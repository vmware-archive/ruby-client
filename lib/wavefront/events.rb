require_relative 'client/version'
require_relative 'exception'
require 'rest_client'
require 'uri'
require 'logger'
require 'wavefront/constants'
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
    DEFAULT_PATH = '/api/events/'

    attr_reader :headers

    def initialize(token)
      @headers = {
        'X-AUTH-TOKEN': token,
      }
    end

    def create(payload = {}, options = {})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      uri = URI::HTTPS.build(
        host:  options[:host],
        path:  options[:path],
      )

      # It seems that posting the hash means the 'host' data is
      # lost. Making a query string works though, so let's do that.
      #
      hosts = payload[:h]
      payload.delete(:h)
      query = mk_qs(payload)
      hosts.each { |host| query.<< "&h=#{host}" }
      RestClient.post(uri.to_s, query, headers)
    end

    def close(payload = {}, options = {})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      # This request seems to need the data as a query string. I was
      # getting a 500 when I posted a hash. A map will do the
      # needful.

      uri = URI::HTTPS.build(
        host:  options[:host],
        path:  options[:path] + 'close',

      )

      RestClient.post(uri.to_s, mk_qs(payload), headers)
    end

    private

    def mk_qs(payload)
      URI.escape(payload.map { |k, v| [k, v].join('=') }.join('&'))
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
