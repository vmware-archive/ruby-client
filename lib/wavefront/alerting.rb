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
require "wavefront/constants"
require 'wavefront/mixins'
require 'wavefront/validators'
require 'rest_client'
require 'uri'
require 'logger'

module Wavefront
  class Alerting
    include Wavefront::Constants
    include Wavefront::Validators
    include Wavefront::Mixins
    DEFAULT_PATH = '/api/alert/'

    attr_reader :token, :noop, :verbose, :endpoint

    def initialize(token, host = DEFAULT_HOST, debug=false, options = {})
      #
      # Following existing convention, 'host' is the Wavefront API endpoint.
      #
      @headers = { :'X-AUTH-TOKEN' => token }
      @endpoint = host
      @token = token
      debug(debug)
      @noop = options[:noop]
      @verbose = options[:verbose]
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

    private

    def list_of_tags(t)
      t.is_a?(Array) ? t : [t]
    end

    def mk_qs(options)
      query = "t=#{token}"

      query += '&' + list_of_tags(options[:shared_tags]).map do |t|
        "customerTag=#{t}"
      end.join('&') if options[:shared_tags]

      query += '&' + list_of_tags(options[:private_tags]).map do |t|
        "userTag=#{t}"
      end.join('&') if options[:private_tags]

      query
    end

    def get_alerts(path, options={})
      options[:host] ||= endpoint
      options[:path] ||= DEFAULT_PATH

      uri = URI::HTTPS.build(
        host:  options[:host],
        path:  uri_concat(options[:path], path),
	      query: mk_qs(options),
      )

      puts "GET #{uri.to_s}" if (verbose || noop)
      return if noop

      RestClient.get(uri.to_s)
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
