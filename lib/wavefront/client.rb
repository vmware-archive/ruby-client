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
require "wavefront/client/constants"
require "wavefront/exception"
require "wavefront/response"
require 'rest_client'
require 'uri'
require 'logger'

module Wavefront
  class Client
    DEFAULT_PERIOD_SECONDS = 600
    DEFAULT_PATH = '/chart/api'
    DEFAULT_FORMAT = :raw
    DEFAULT_PREFIX_LENGTH = 1
    FORMATS = [ :raw, :ruby, :graphite, :highcharts ]
    GRANULARITIES = %w( s m h d )

    attr_reader :headers, :base_uri

    def initialize(token, host=DEFAULT_HOST, debug=false)
      @headers = {'X-AUTH-TOKEN' => token}
      @base_uri = URI::HTTPS.build(:host => host, :path => DEFAULT_PATH)
      debug(debug)
    end

    def query(query, granularity='m', options={})

      options[:end_time] ||= Time.now
      options[:start_time] ||= options[:end_time] - DEFAULT_PERIOD_SECONDS
      options[:response_format] ||= DEFAULT_FORMAT
      options[:prefix_length] ||= DEFAULT_PREFIX_LENGTH

      [ options[:start_time], options[:end_time] ].each { |o| raise Wavefront::Exception::InvalidTimeFormat unless o.is_a?(Time) }
      raise Wavefront::Exception::InvalidGranularity unless GRANULARITIES.include?(granularity)
      raise Wavefront::Exception::InvalidResponseFormat unless FORMATS.include?(options[:response_format])
      raise InvalidPrefixLength unless options[:prefix_length].is_a?(Fixnum)

      args = {:params =>
              {:q => query, :g => granularity, :n => 'Unknown',
               :s => options[:start_time].to_i, :e => options[:end_time].to_i}}.merge(@headers)

      if options[:passthru]
        args.merge!(options[:passthru])
      end

      response = RestClient.get @base_uri.to_s, args

      klass = Object.const_get('Wavefront').const_get('Response').const_get(options[:response_format].to_s.capitalize)
      return klass.new(response, options)

    end

    private

    def debug(enabled)
      if enabled
        RestClient.log = 'stdout'
      end
    end

  end
end
