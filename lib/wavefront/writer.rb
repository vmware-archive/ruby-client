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
require 'uri'
require 'socket'

module Wavefront
  class Writer
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
    
    def write(metric_value, metric_name=@metric_name, host=@host_name, point_tags=@point_tags, timestamp=Time.now)
      raise Wavefront::Exception::EmptyMetricName if metric_name.empty?
      tags = point_tags.empty? ? '' : point_tags.map{|k,v| "#{k}=\"#{v}\""}.join(' ')
      append = tags.empty? ? "host=#{host}" : "host=#{host} #{tags}"
      @socket.puts "#{metric_name} #{metric_value} #{timestamp.to_i} #{append}"
    end

    private
    def get_socket(host,port)
      TCPSocket.new(host, port)
    end

  end
end
