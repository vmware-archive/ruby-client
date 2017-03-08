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

    attr_reader :token, :noop, :verbose, :endpoint, :headers, :options

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
      @options = options
    end

    def import_to_create(raw)
      #
      # Take a previously exported alert, and construct a hash which
      # create_alert() can use to re-create it.
      #
      ret = {
        name:          raw['name'],
        condition:     raw['condition'],
        minutes:       raw['minutes'],
        notifications: raw['target'].split(','),
        severity:      raw['severity'],
      }

      if raw.key?('displayExpression')
        ret[:displayExpression] = raw['displayExpression']
      end

      if raw.key?('resolveAfterMinutes')
        ret[:resolveMinutes] = raw['resolveAfterMinutes']
      end

      if raw.key?('customerTagsWithCounts')
        ret[:sharedTags] = raw['customerTagsWithCounts'].keys
      end

      if raw.key?('additionalInformation')
        ret[:additionalInformation] = raw['additionalInformation']
      end

      ret
    end

    def create_alert(alert={})
      #
      # Create an alert. Expects you to provide it with a hash of
      # the form:
      #
      # {
      #   name:                 string
      #   condition:            string
      #   displayExpression:    string     (optional)
      #   minutes:              int
      #   resolveMinutes:       int        (optional)
      #   notifications:        array
      #   severity:             INFO | SMOKE | WARN | SEVERE
      #   privateTags:          array      (optional)
      #   sharedTags:           array      (optional)
      #   additionalInformation string     (optional)
      # }
      #
      %w(name condition minutes notifications severity).each do |f|
        raise "missing field: #{f}" unless alert.key?(f.to_sym)
      end

      unless %w(INFO SMOKE WARN SEVER).include?(alert[:severity])
        raise 'invalid severity'
      end

      %w(notifications privateTags sharedTags).each do |f|
        f = f.to_sym
        alert[f] = alert[f].join(',') if alert[f] && alert[f].is_a?(Array)
      end

      call_post(create_uri(path: 'create'),
                hash_to_qs(alert), 'application/x-www-form-urlencoded')
    end

    def get_alert(id, options = {})
      #
      # Alerts are identified by the timestamp at which they were
      # created. Returns a hash. Exceptions are just passed on
      # through. You get a 500 if the alert doesn't exist.
      #
      resp = call_get(create_uri(path: id))
      return JSON.parse(resp)
    end

    def active(options={})
      call_get(create_uri(options.merge(path: 'active', qs: mk_qs(options))))
    end

    def all(options={})
      call_get(create_uri(options.merge(path: 'all', qs: mk_qs(options))))
    end

    def invalid(options={})
      call_get(create_uri(options.merge(path: 'invalid', qs: mk_qs(options))))
    end

    def snoozed(options={})
      call_get(create_uri(options.merge(path: 'snoozed', qs: mk_qs(options))))
    end

    def affected_by_maintenance(options={})
      call_get(create_uri(options.merge(path: 'affected_by_maintenance', qs: mk_qs(options))))
    end

    private

    def list_of_tags(t)
      t.is_a?(Array) ? t : [t]
    end

    def mk_qs(options)
      query = []

      query.<< (list_of_tags(options[:shared_tags]).map do |t|
        "customerTag=#{t}"
      end.join('&')) if options[:shared_tags]

      query.<< (list_of_tags(options[:private_tags]).map do |t|
        "userTag=#{t}"
      end.join('&')) if options[:private_tags]

      query.join('&')
    end

    def create_uri(options = {})
      #
      # Build the URI we use to send a 'create' request.
      #
      options[:host] ||= endpoint
      options[:path] ||= ''
      options[:qs]   ||= nil

      options[:qs] = nil if options[:qs].empty?

      URI::HTTPS.build(
        host:  options[:host],
        path:  uri_concat(DEFAULT_PATH, options[:path]),
        query: options[:qs],
      )
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
