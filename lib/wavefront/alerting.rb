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
require 'rest_client'
require 'uri'
require 'logger'

module Wavefront
  class Alerting
    DEFAULT_HOST = 'metrics.wavefront.com'
    DEFAULT_PATH = '/api/alert/'

    attr_reader :token

    def initialize(token, debug=false)
      @token = token
      debug(debug)
    end

    def active(options={})
      get_alerts('active', options)
    end

    def all(options={})
      get_alerts('all', options)
    end

    def invalid(options={})
      get_alerts('invalid', options)
    end

    def snoozed(options={})
      get_alerts('snoozed', options)
    end

    def affected_by_maintenance(options={})
      get_alerts('affected_by_maintenance', options)
    end

    def get_alerts(path, options={})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      query = "t=#{@token}"

      if options[:shared_tags]
        tags = options[:shared_tags].class == Array ? options[:shared_tags] : [ options[:shared_tags] ] # Force an array, even if string given
        query += "&#{tags.map{|t| "customerTag=#{t}"}.join('&')}"
      end

      if options[:private_tags]
        tags = options[:private_tags].class == Array ? options[:private_tags] : [ options[:private_tags] ] # Force an array, even if string given
        query += "&#{tags.map{|t| "userTag=#{t}"}.join('&')}"
      end

      uri = URI::HTTPS.build(
        host: options[:host],
	path: File.join(options[:path], path),
	query: query
      )
      RestClient.get(uri.to_s)
    end

    private

    def debug(enabled)
      if enabled
        RestClient.log = 'stdout'
      end
    end

  end
end
