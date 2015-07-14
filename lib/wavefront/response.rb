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

require 'wavefront/client/version'
require 'wavefront/exception'
require 'json'

module Wavefront
  class Response
    class Raw
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def to_s
        return @response
      end

    end

    class Ruby
      include JSON
      attr_reader :response
      
      def initialize(response)
        @response = response

        JSON.parse(response).each_pair do |k,v|
          self.instance_variable_set("@#{k}", v)	# Dynamically populate instance vars
          self.class.__send__(:attr_reader, k)		# and set accessors
        end
      end

    end

    class Graphite < Wavefront::Response::Ruby
      attr_reader :response, :graphite

      def initialize(response)
        super
        
        datapoints = Array.new
        self.timeseries.each do |ts|
          ts['data'].each do |d|
            datapoints << [d[1], d[0]]
          end
        end

        @graphite = [{ 'target' => self.query, 'datapoints' => datapoints }]
      end

    end

    class Highcharts < Wavefront::Response::Ruby
      include JSON
      attr_reader :response, :highcharts

      def initialize(response)
        super

        @response = JSON.parse(response)

	@highcharts = []
	self.timeseries.each do |series|
	  # Highcharts expects the time in milliseconds since the epoch
	  # And for some reason the first value tends to be BS

	  @highcharts << { 'name' => series['label'],  'data' => series['data'][1..-1].map!{|x,y| [ x * 1000, y ]} }
	end
      end

      def to_json
	@highcharts.to_json
      end
    end

  end
end
