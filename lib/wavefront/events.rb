require_relative 'client/version'
require_relative 'exception'
require 'rest_client'
require 'uri'
require 'logger'
require 'wavefront/constants'
require 'wavefront/mixins'
#
# Add basic support to cover Wavefront's events API. I have followed
# the standards and conventions established in the files already in
# this repository.
#
# R Fisher 07/2015
#
module Wavefront
  #
  # These methods expect to be called with a hash whose keys are as
  # defined in the Wavefront API Console. That is, 'n' as 'name for
  # the event', 's' as 'start time for the event' and so-on.
  #
  class Events
    include Wavefront::Constants
    include Wavefront::Mixins
    DEFAULT_PATH = '/api/events/'

    attr_reader :headers

    def initialize(token)
      @headers = { :'X-AUTH-TOKEN' => token }
    end

    def create(payload = {}, options = {})
      make_call(create_uri(options), create_qs(payload))
    end

    def close(payload = {}, options = {})
      make_call(close_uri(options), hash_to_qs(payload))
    end

    def delete(payload = {}, options = {})
      unless payload.has_key?(:startTime)  && payload.has_key?(:name)
        raise 'invalid payload'
      end

      uri = create_uri(path: [DEFAULT_PATH, payload[:startTime],
                       payload[:name]].join('/').squeeze('/'))

      RestClient.delete(uri.to_s, headers)
    end

    def create_uri(options = {})
      #
      # Build the URI we use to send a 'create' request.
      #
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      URI::HTTPS.build(
        host:  options[:host],
        path:  options[:path],
      )
    end

    def create_qs(payload = {})
      #
      # It seems that posting the hash means the 'host' data is
      # lost. Making a query string works though, so let's do that.
      #
      if payload[:h].is_a?(Array)
        hosts = payload[:h]
      elsif payload[:h].is_a?(String)
        hosts = [payload[:h]]
      else
        hosts = []
      end

      payload.delete(:h)
      query = hash_to_qs(payload)
      hosts.each { |host| query.<< "&h=#{host}" }
      query
    end

    def close_uri(options = {})
      #
      # Build the URI we use to send a 'close' request
      #
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      URI::HTTPS.build(
        host:  options[:host],
        path:  options[:path] + 'close',
      )
    end

    def make_call(uri, query)
      RestClient.post(uri.to_s, query, headers)
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
