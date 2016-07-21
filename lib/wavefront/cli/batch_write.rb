require 'wavefront/cli'
require 'socket'
require 'pathname'
#
# Push datapoints into Wavefront, via a proxy
#
class Wavefront::Cli::BatchWrite < Wavefront::Cli
  attr_reader :data, :opts, :sock, :fmt

  include Wavefront::Constants
  include Wavefront::Mixins

  def run
    raise 'Invalid format string.' unless valid_format?(options[:format])

    file = options[:'<file>']
    @fmt = options[:format].split('')
    @points_sent = 0

    @opts = {
      prefix:   options[:metric] || '',
      source:   options[:host] || Socket.gethostname,
      tags:     prep_tags(options[:tag]),
      endpoint: options[:proxy],
      port:     options[:port],
      verbose:  options[:verbose],
      noop:     options[:noop],
    }

    begin
      open_socket
    rescue
      raise 'unable to connect to proxy'
    end

    begin
      if file == '-'
        STDIN.each_line { |l| process_line(l.strip) }
      else
        file = Pathname.new(file)
        load_data(file)
        process_filedata
      end
    ensure
      close_socket
    end

    puts "Sent #{@points_sent} point(s) to Wavefront."
  end

  def load_data(file)
    raise "Cannot open file '#{file}'." unless file.exist?
    @data = IO.read(file)
  end

  def process_filedata
    #
    # we know what order the fields are in from the format string,
    # which contains 't', 'm', and 'v' in some order
    #
    @data.split("\n").each { |l| process_line(l) }
  end

  def process_line(l)
    #
    # Process a line of input, as described by the format string
    # held in opts[:fmt].
    #
    # We let the user define most of the fields, but anything beyond
    # what they define is always assumed to be point tags. This is
    # because you can have arbitrarily many of those for each point.
    #
    m_prefix = opts[:prefix]
    chunks = l.split(/\s+/, fmt.length)

    begin
      raise 'wrong number of fields' unless valid_line?(l)

      begin
        value = chunks[fmt.index('v')]
      rescue TypeError
        raise "no value in '#{l}'"
      end

      raise "invalid value '#{value}'" unless valid_value?(value)

      # The user can supply a time. If they have told us they won't
      # be, we'll use the current time.
      #
      ts = begin
        parse_time(chunks[fmt.index('t')])
      rescue TypeError
        Time.now.utc.to_i
      end

      raise "invalid timestamp '#{ts}'" unless valid_timestamp?(ts)

      # The source is normally the local hostname, but the user can
      # override that.

      source = begin
        chunks[fmt.index('s')]
      rescue TypeError
        opts[:source]
      end

      # The metric path can be in the data, or passed as an option, or
      # both. If the latter, then we assume the option is a prefix,
      # and concatenate the value in the data.
      #
      begin
        m = chunks[fmt.index('m')]
        metric = m_prefix.empty? ? m : [m_prefix, m].join('.')
      rescue TypeError
        if m_prefix
          metric = m_prefix
        else
          raise "metric path in '#{l}'"
        end
      end
    rescue => e
      puts "WARNING: #{e}. Skipping."
      return false
    end

    # Now we can assemble the metric, adding on any point tags we
    # might have. Tags can come from the data, the command-line
    # options, or both.
    #
    metric = [metric, value, ts.to_i, "source=#{source}"].join(' ')

    metric.<< ' ' + chunks[3] if chunks[3]
    opts[:tags].each { |t| metric.<< ' ' + t.join('="') + '"' }
    send_metric(metric)
  end

  def valid_format?(fmt)
    # The format string must contain a 'v'. It must not contain
    # anything other than 'm', 't', 'T' or 'v', and the 'T', if
    # there, must be at the end. No letter must appear more than
    # once.
    #
    fmt.include?('v') && fmt.match(/^[mtv]+T?$/) && fmt ==
      fmt.split('').uniq.join
  end

  def valid_line?(l)
    #
    # Make sure we have the right number of columns, according to
    # the format string. We want to take every precaution we can to
    # stop users accidentally polluting their metric namespace with
    # junk.
    #
    # If the format string says we are expecting point tags, we may
    # have more columns than the length of the format string.
    #
    ncols = l.split.length

    if fmt.include?('T')
      return false unless ncols >= fmt.length
    else
      return false unless ncols == fmt.length
    end

    true
  end

  def valid_timestamp?(ts)
    #
    # Another attempt to stop the user accidentally sending nonsense
    # data. See if the time looks valid. We'll assume anything before
    # 2000/01/01 or after a year from now is wrong. Arbitrary, but
    # there has to be a cut-off somewhere.
    #
    (ts.is_a?(Integer) || ts.match(/^\d+$/)) &&
      ts.to_i > 946684800 && ts.to_i < (Time.now.to_i + 31557600)
  end

  def valid_value?(val)
    val.is_a?(Fixnum) || val.is_a?(Float) || val.match(/^[\d\.e]+$/)
  end

  def open_socket
    if opts[:noop]
      puts "No-op requested. Not opening connection to proxy."
      return
    end

    if opts[:verbose]
      puts "Connecting to proxy at #{opts[:endpoint]}:#{opts[:port]}."
    end

    begin
      @sock = TCPSocket.new(opts[:endpoint], opts[:port])
    rescue
      raise Wavefront::Exception::InvalidEndpoint
    end
  end

  def send_metric(metric)
    if opts[:noop]
      puts "would send: #{metric}"
      return
    end

    puts "Sending: #{metric}" if opts[:verbose]

    begin
      sock.puts(metric)
      @points_sent += 1
    rescue
      puts 'WARNING: failed to send metric.'
    end
  end

  def close_socket
    unless opts[:noop]
      puts 'Closing connection to proxy.' if opts[:verbose]
      sock.close
    end
  end
end
