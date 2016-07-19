=begin
    Copyright 2015 Wavefront Inc.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
   limitations under the License.

=end

require "wavefront/client/version"
require "wavefront/exception"
require "wavefront/constants"
require 'uri'
require 'socket'

module Wavefront
  class Writer
    include Wavefront::Constants
    DEFAULT_AGENT_HOST = 'localhost'
    DEFAULT_PORT = 2878
    DEFAULT_HOSTNAME = %x{hostname -f}.chomp

    def initialize(options = {})
      options[:agent_host] ||= DEFAULT_AGENT_HOST
      options[:agent_port] ||= DEFAULT_PORT
      options[:host_name] ||= DEFAULT_HOSTNAME
      options[:metric_name] ||= ''
      options[:point_tags] ||= {}

      @host_name = options[:host_name]
      @metric_name = options[:metric_name]
      @point_tags = options[:point_tags]

      @socket = get_socket(options[:agent_host], options[:agent_port])
    end

    def write(metric_value, metric_name = @metric_name, options = {})
      options[:host_name] ||= @host_name
      options[:point_tags] ||= @point_tags
      options[:timestamp] ||= Time.now

      if metric_name.empty?
        raise Wavefront::Exception::EmptyMetricName
      end

      if options[:point_tags].empty?
        append = "host=#{options[:host_name]}"
      else
        tags = options[:point_tags].map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
        append = "host=#{options[:host_name]} #{tags}"
      end

      str = [metric_name, metric_value, options[:timestamp].to_i,
                    append].join(' ')

      if options[:noop]
        puts "metric to send: #{str}"
      else
        @socket.puts(str)
      end
    end

    private

    def get_socket(host, port)
      TCPSocket.new(host, port)
    end
  end
end
