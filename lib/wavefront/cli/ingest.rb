require 'socket'
require 'date'
require 'wavefront/constants'
require 'wavefront/mixins'
require 'wavefront/ingest'
require 'wavefront/cli'
#
# Push datapoints into Wavefront, via the API. This uses an undocumented,
# unstable interface, and should be used with caution.
# It cannot batch, or deal with files or streams of data.
#
class Wavefront::Cli::Ingest < Wavefront::Cli
  attr_reader :wf, :fmt, :buffer, :last_buffer_time

  include Wavefront::Constants
  include Wavefront::Mixins

  def run
    @wf = Wavefront::Ingest.new(@options[:token], @options[:endpoint],
                               @options[:debug],
                               { noop: @options[:noop],
                                 verbose: @options[:verbose]})

    @buffer = {}
    @last_buffer_time = nil
    @fmt = options[:infileformat] || 'mvT'

    if options[:point]
      valid_value?(options[:'<value>'])
      valid_metric?(options[:'<metric>'])
      write_metric(options[:'<value>'].to_f, options[:'<metric>'])
    else
      if options[:'<file>'] == '-'
        write_from_stdin
      else
        write_from_file(Pathname.new(options[:'<file>']))
      end
    end
  end

  def write_from_file(file)
    abort 'Input file not found.' unless file.exist?

    body = IO.read(file).each_line.with_object({}) do |l, aggr|
      aggr.merge!(process_line(l))
    end

    wf.write(body, options[:host], options[:time] || Time.now)
  end

  # We want to make the fewest API calls as possible to send the
  # data. Wavefront has a resolution of one second. So, let's assume
  # we aren't going to overload the POST body size (you can tell I'm
  # going on holiday tomorrow), and try to batch our queries on
  # internal clock seconds. BUT, only push when we need to.
  #
  # When a point gets pushed to this method, we check to see whether
  # the time has changed since the last time we performed that
  # operation. If it has, we push the contents of the buffer, with
  # that timestamp, and start a fresh buffer with the new line.  If
  # not we append the line to our buffer.
  #
  # If there are multiple values for the same metric, within the same
  # second, the last one will win. This matches the behaviour of the
  # Wavefront engine.
  #
  def flush_or_buffer(point, time)
    return unless point.is_a?(Hash) && ! point.empty?

    if time == last_buffer_time || last_buffer_time.nil?
      @buffer.merge!(point)
    else
      flush_buffer
      @buffer = point
    end

    @last_buffer_time = time
  end

  def flush_buffer
    wf.write(buffer, options[:host], last_buffer_time)
  end

  def write_from_stdin
    STDIN.each_line { |l| flush_or_buffer(process_line(l), Time.now.to_i) }
    flush_buffer
  end

  def process_line(l)
    chunks = l.split(/\s+/, fmt.size)

    unless chunks.size == fmt.size
      puts "WARNING: malformed line: #{l}"
      return {}
    end

    value = chunks[fmt.index('v')].to_f

    point = { value: value }

    tags = Hash[prep_tags(chunks.last.split + options[:tag])]
    point[:tags] = tags unless tags.empty?

    metric_name = if options[:metric] && fmt.include?('m')
                    [options[:metric], chunks[fmt.index('m')]].join('.')
                  elsif options[:metric]
                    options[:metric]
                  elsif fmt.include?('m')
                    chunks[fmt.index('m')]
                  else
                    abort 'no metric name in file on or command line'
                  end

    begin
      valid_metric?(metric_name)
      valid_value?(value)
    rescue Wavefront::Exception::InvalidMetricName
      puts "WARNING: invalid metric name: #{metric_name}"
      return {}
    rescue Wavefront::Exception::InvalidValue
      puts "WARNING: invalid metric value #{value}"
      return {}
    end

    return { metric_name => point }
  end

  def write_metric(value, name)
    point = { value: value }
    tags = prep_tags(options[:tag])
    point[:tags] = Hash[tags] if tags

    body = { name => point }

    wf.write(body, options[:host], options[:time] || Time.now)
  end

  def valid_host?(hostname)
    #
    # quickly make sure a hostname looks vaguely sensible
    #
    hostname.match(/^[\w\.\-]+$/) && hostname.length < 1024
  end

  def valid_value?(value)
    #
    # Values, it seems, will always come in as strings. We need to
    # cast them to numbers. I don't think there's any reasonable way
    # to allow exponential notation.
    #
    unless value.is_a?(Numeric) || value.match(/^-?\d*\.?\d*$/) ||
           value.match(/^-?\d*\.?\d*e\d+$/)
      fail Wavefront::Exception::InvalidMetricValue
    end
    true
  end

  def valid_metric?(metric)
    #
    # Apply some common-sense rules to metric paths. Check it's a
    # string, and that it has at least one dot in it. Don't allow
    # through odd characters or whitespace.
    #
    begin
      fail unless metric.is_a?(String) &&
                  metric.split('.').length > 1 &&
                  metric.match(/^[\w\-\._]+$/) &&
                  metric.length < 1024
    rescue
      raise Wavefront::Exception::InvalidMetricName
    end
    true
  end

  def prep_tags(tags)
    #
    # Takes an array of key=value tags (as produced by docopt) and
    # turns it into an array of [key, value] arrays (as required
    # by various of our own methods). Anything not of the form
    # key=val is dropped.
    #
    return [] unless tags.is_a?(Array)
    tags.map { |t| t.split('=') }.select { |e| e.length == 2 }
  end
end
