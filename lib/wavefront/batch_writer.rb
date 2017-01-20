require 'wavefront/client/version'
require 'wavefront/exception'
require 'wavefront/constants'
require 'wavefront/validators'
require 'uri'
require 'socket'

HOSTNAME = Socket.gethostname

module Wavefront
  #
  # This class exists to facilitate sending of multiple data points
  # to a Wavefront proxy. It sends points in native Wavefront
  # format.
  #
  # When initializing the instance you can
  # define point tags which will apply to all points sent via that
  # instance.
  #
  # Though we provide methods to do it, it is the developer's
  # responsibility to open and close the socket to the proxy. Points
  # are sent by calling the write() method.
  #
  # The class keeps a count of the points the current instance has
  # sent, dropped, and failed to send, in @summary. The socket is accessed
  # through the instance variable @sock.
  #
  class BatchWriter
    attr_reader :sock, :opts, :summary
    include Wavefront::Constants
    include Wavefront::Validators

    def initialize(options = {})
      #
      # options is of the form:
      #
      # {
      #   tags:       a key-value hash of tags which will be applied to
      #               every  point
      #   proxy:      the address of the Wavefront proxy
      #   port:       the port of the Wavefront proxy
      #   noop:       if this is true, no proxy connection will be made,
      #               and instead of sending the points, they will
      #               be printed in Wavefront wire format.
      #   novalidate: if this is true, points will not be validated.
      #               This might make things go marginally quicker
      #               if you have done point validation higher up in
      #               the chain.
      #   verbose:    if this is true, many of the methods will report
      #               their progress.
      #   debug:      if this is true, debugging output will be
      #               printed.
      # }
      #
      defaults = {
        tags:       false,
        proxy:      DEFAULT_PROXY,
        port:       DEFAULT_PROXY_PORT,
        noop:       false,
        novalidate: false,
        verbose:    false,
        debug:      false,
      }

      @summary = { sent:     0,
                   rejected: 0,
                   unsent:   0,
                 }

      @opts = setup_options(options, defaults)

      if opts[:tags]
        valid_tags?(opts[:tags])
        @global_tags = opts[:tags]
      end

      debug(options[:debug])
    end

    def setup_options(user, defaults)
      #
      # Fill in some defaults, if the user hasn't supplied them
      #
      defaults.merge(user)
    end

    def write(points = [], options = {})
      #
      # Points are defined as hashes of the following form:
      # {
      #    path:   metrics path. String. Mandatory.
      #    value:  value of metric. Numeric. Mandatory.
      #    ts:     timestamp as a Time or Date object.  default:
      #            Time.now. May be omitted or false.
      #    source: originating source of metric. default: `hostname`
      #    tags:   optional hash of key: value point tags
      # }
      #
      # Send multiple points by using an array of the above hashes.
      #
      unless points.is_a?(Hash) || points.is_a?(Array)
        summary[:rejected] += 1
        return false
      end

      points = [points] if points.is_a?(Hash)

      points.each do |p|
        p[:ts] = Time.at(p[:ts]) if p[:ts].is_a?(Integer)
        begin
          valid_point?(p)
        rescue Wavefront::Exception::InvalidMetricName,
               Wavefront::Exception::InvalidMetricValue,
               Wavefront::Exception::InvalidTimestamp,
               Wavefront::Exception::InvalidSource,
               Wavefront::Exception::InvalidTag => e
          puts 'Invalid point, skipping.' if opts[:verbose]
          puts "Invalid point: #{p}. (#{e})" if opts[:debug]
          summary[:rejected] += 1
          next
        end

        send_point(hash_to_wf(p))
      end
      summary[:rejected] == 0 ? true : false
    end

    def valid_point?(point)
      #
      # Validate a point so it conforms to the standard described in
      # https://community.wavefront.com/docs/DOC-1031
      #
      return true if opts.key?(:novalidate) && opts[:novalidate]
      valid_path?(point[:path])
      valid_value?(point[:value])
      valid_ts?(point[:ts]) if point[:ts]
      valid_source?(point[:source])
      valid_tags?(point[:tags]) if point[:tags] && point[:tags].length > 0
      true
    end

    def hash_to_wf(p)
      #
      # Convert the hash received by the write() method to a string
      # conforming with that defined in
      # https://community.wavefront.com/docs/DOC-1031
      #
      fail ArgumentError unless p.key?(:path) && p.key?(:value) &&
                                p.key?(:source)

      m = [p[:path], p[:value]]
      m.<< p[:ts].to_i.to_s if p.key?(:ts) && p[:ts]
      m.<< 'source=' + p[:source]
      m.<< tag_hash_to_str(p[:tags]) if p.key?(:tags) && p[:tags]
      m.<< tag_hash_to_str(opts[:tags]) if opts[:tags]
      m.join(' ')
    end

    def tag_hash_to_str(tags)
      #
      # Convert a hash of tags into a string of key="val" tags. The
      # quoting is recommended in the WF wire-format guide. No tag
      # validation is done here: we assume you used valid_tags()
      #
      return '' unless tags.is_a?(Hash)
      tags.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    end

    def send_point(point)
      #
      # Send a point, which should already be in Wavefront wire
      # format.
      #
      if opts[:noop]
        puts "Would send: #{point}"
        return
      end

      puts "Sending: #{point}" if opts[:verbose] || opts[:debug]

      begin
        sock.puts(point)
        summary[:sent] += 1
        return true
      rescue
        summary[:unsent] += 1
        puts 'WARNING: failed to send point.'
        return false
      end
    end

    def open_socket
      #
      # Open a socket to a Wavefront proxy, putting the descriptor
      # in instance variable @sock.
      #
      if opts[:noop]
        puts 'No-op requested. Not opening connection to proxy.'
        return true
      end

      puts "Connecting to #{opts[:proxy]}:#{opts[:port]}." if opts[:verbose]

      begin
        @sock = TCPSocket.new(opts[:proxy], opts[:port])
      rescue
        raise Wavefront::Exception::InvalidEndpoint
      end
    end

    def close_socket
      return if opts[:noop]
      puts 'Closing connection to proxy.' if opts[:verbose]
      sock.close
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
