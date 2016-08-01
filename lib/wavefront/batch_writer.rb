require 'wavefront/client/version'
require 'wavefront/exception'
require 'wavefront/constants'
require 'uri'
require 'socket'

module Wavefront
  #
  # This class exists to facilitate sending of multiple data points
  # to a Wavefront proxy. When initializing the instance you can
  # define point tags which will apply to all points sent via that
  # instance.
  #
  # Though we provide methods to do it, it is the developer's
  # responsibility to open and close the socket to the proxy. Points
  # are sent by calling the write() method.
  #
  # The class keeps a count of the points the current instance has
  # sent in @points_sent. The socket is accessed through the
  # instance variable @sock.
  #
  class BatchWriter
    attr_reader :sock, :options

    def initialize(options = {})
      @points_sent = 0
      @points_rejected = 0
      @points_unsent = 0
      @options = options

      if options[:tags]
        valid_tags?(options[:tags])
        @global_tags = options[:tags]
      end
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
      points = [points] if points.is_a?(Hash)

      points.each do |p|
        begin
          valid_point?(p)
        rescue Wavefront::Exception::InvalidMetricName,
               Wavefront::Exception::InvalidMetricValue,
               Wavefront::Exception::InvalidTimestamp,
               Wavefront::Exception::InvalidSource,
               Wavefront::Exception::InvalidTag
          puts 'Invalid point, skipping.' if options[:verbose]
          puts "Invalid point: #{p}" if options[:debug]
          @points_rejected += 1
          next
        end

        send_point(hash_to_wf(p))
      end
      return @points_rejected == 0 ? true : false
    end

    def valid_point?(point)
      #
      # Validate a point so it conforms to the standard described in
      # https://community.wavefront.com/docs/DOC-1031
      #
      return true if options.key?(:novalidate) && options[:novalidate]
      valid_path?(point[:path])
      valid_value?(point[:value])
      valid_ts?(point[:ts]) if point[:ts]
      valid_source?(point[:source])
      valid_tags?(point[:tags]) if point[:tags] && point[:tags].length > 0
      true
    end

    def valid_path?(path)
      fail Wavefront::Exception::InvalidMetricName unless \
        path.is_a?(String) && path.match(/^[a-z0-9\-_\.]+$/) &&
        path.length < 1024
      true
    end

    def valid_value?(value)
      fail Wavefront::Exception::InvalidMetricValue unless value.is_a?(Numeric)
      true
    end

    def valid_ts?(ts)
      unless ts.is_a?(Time) || ts.is_a?(Date)
        fail Wavefront::Exception::InvalidTimestamp
      end
      true
    end

    def valid_source?(path)
      unless path.is_a?(String) && path.match(/^[a-z0-9\-_\.]+$/) &&
             path.length < 1024
        fail Wavefront::Exception::InvalidSource
      end
      true
    end

    def valid_tags?(tags)
      tags.each do |k, v|
        fail Wavefront::Exception::InvalidTag unless (k.length +
             v.length < 254) && k.match(/^[a-z0-9\-_\.]+$/)
      end
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
      m.<< tag_hash_to_str(options[:tags]) if options[:tags]
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
      if options[:noop]
        puts "Would send: #{point}"
        return
      end

      puts "Sending: #{point}" if options[:verbose]

      begin
        sock.puts(point)
        @points_sent += 1
        return true
      rescue
        @points_unsent += 1
        puts 'WARNING: failed to send point.'
        return false
      end
    end

    def open_socket
      #
      # Open a socket to a Wavefront proxy, putting the descriptor
      # in instance variable @sock.
      #
      if options[:noop]
        puts 'No-op requested. Not opening connection to proxy.'
        return true
      end

      puts "Connecting to #{options[:endpoint]}:#{options[:port]}." \
        if options[:verbose]

      begin
        @sock = TCPSocket.new(options[:endpoint], options[:port])
      rescue
        raise Wavefront::Exception::InvalidEndpoint
      end
    end

    def close_socket
      return if options[:noop]
      puts 'Closing connection to proxy.' if options[:verbose]
      sock.close
    end
  end
end
