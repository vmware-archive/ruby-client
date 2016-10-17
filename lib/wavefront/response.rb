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

require 'wavefront/client'
require 'wavefront/client/version'
require 'wavefront/exception'
require 'wavefront/mixins'
require 'json'

module Wavefront
  class Response
    class Raw
      attr_reader :response, :options

      def initialize(response, options={})
        @response = response
        @options = options
      end

      def to_s
        return @response
      end

    end

    class Ruby
      include JSON
      attr_reader :response, :options

      def initialize(response, options={})
        @response = response
        @options = options

        JSON.parse(response).each_pair do |k,v|
          self.instance_variable_set("@#{k}", v)	# Dynamically populate instance vars
          self.class.__send__(:attr_reader, k)		# and set accessors
        end
      end

    end

    class Graphite < Wavefront::Response::Ruby
      include Wavefront::Mixins
      attr_reader :response, :graphite, :options

      def initialize(response, options={})
        super
        options[:prefix_length] ||= Wavefront::Client::DEFAULT_PREFIX_LENGTH

        @graphite = Array.new
        self.timeseries.each do |ts|

          output_timeseries = Hash.new
          output_timeseries['target'] = interpolate_schema(ts['label'], ts['host'], options[:prefix_length])

          datapoints = Array.new
          ts['data'].each do |d|
            datapoints << [d[1], d[0]]
          end

          output_timeseries['datapoints'] = datapoints
          @graphite << output_timeseries

        end
      end

    end

    class Highcharts < Wavefront::Response::Ruby
      include JSON
      attr_reader :response, :highcharts, :options

      def initialize(response, options={})
        super

        @response = JSON.parse(response)
	      @highcharts = []
	      self.timeseries.each do |series|
          # Highcharts expects the time in milliseconds since the epoch
          # And for some reason the first value tends to be BS
          # We also have to deal with missing (null/nil) data points.
          amended_data = Array.new
          next unless series['data'].size > 0
          series['data'][1..-1].each do |time_value_pair|
            if time_value_pair[0]
              time_value_pair[0] = time_value_pair[0] * 1000
            else
              time_value_pair[0] = "null"
            end
            amended_data << time_value_pair
          end
          @highcharts << { 'name' => series['label'],  'data' => amended_data }
        end
      end

      def to_json
        @highcharts.to_json
      end
    end

    class Human < Wavefront::Response::Ruby
      #
      # Print "human-readable" (but also easily machine-pareseable)
      # values.
      #
      attr_reader :response, :options, :human

      def initialize(response, options={})
        super

        if self.response
          if self.respond_to?(:timeseries)
            out = process_timeseries
          elsif self.respond_to?(:events)
            out = process_events
          else
            out = []
          end
        else
          out = self.warnings
        end

        @human = out.join("\n")
      end

      def process_timeseries
        out = ['%-20s%s' % ['query', self.query]]

        self.timeseries.each_with_index do |ts, i|
          out.<< '%-20s%s' % ['timeseries', i]
          out += ts.select{|k,v| k != 'data' }.map do |k, v|
            if k == 'tags'
              v.map { |tk, tv| 'tag.%-16s%s' % [tk, tv] }
            else
              '%-20s%s' % [k, v]
            end
          end
          out += ts['data'].map do |t, v|
            [Time.at(t).strftime('%F %T'), v].join(' ')
          end
        end

        out
      end

      def process_events
        sorted = self.events.sort_by { |k| k['start'] }

        sorted.each_with_object([]) do |e, out|
          hosts = e['hosts'] ? '[' + e['hosts'].join(',') + ']' : ''

          if e['tags']
            severity = e['tags']['severity']
            type = e['tags']['type']
            details = e['tags']['details']
          else
            severity = type = details = ''
          end

          t = [format_event_time(e['start']), '->',
               format_event_time(e['end']),
               '%-9s' % ('(' + format_event_duration(e['start'],
                                                     e['end']) + ')'),
               '%-7s' % severity,
               '%-15s' % type,
               '%-25s' % e['name'],
               hosts,
               details,
              ].join(' ')

          out.<< t
        end
      end

      def format_event_time(tms)
        Time.at(tms / 1000).strftime('%F %T')
      end

      def format_event_duration(ts, te)
        #
        # turn an event start and end into a human-readable,
        # approximate, time.  Truncates after the first two parts in
        # the interests of space.
        #
        dur = (te - ts) / 1000

        return 'inst' if dur == 0

        {s: 60, m: 60, h: 24, d: 1000 }.map do |sfx, val|
          next unless dur > 0
          dur, n = dur.divmod(val)
          n.to_s + sfx.to_s
        end.compact.reverse[0..1].join(' ')
      end

    end
  end
end
