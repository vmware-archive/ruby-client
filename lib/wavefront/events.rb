require 'wavefront/client/version'
require 'wavefront/exception'
require 'rest_client'
require 'uri'
require 'logger'

module Wavefront
  #
  # These methods expect to be called with a hash whose keys are as defined in
  # the Wavefront API Console. That is, 'n' as 'name for the event', 's' as
  # 'start time for the event' and so-on.
  #
  class Events
    DEFAULT_HOST = 'metrics.wavefront.com'
    DEFAULT_PATH = '/api/events'

    attr_reader :token

    def initialize(token)
      @token = token
    end

    def create(payload = {}, options = {})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      uri = URI::HTTPS.build(
        host:  options[:host],
        path:  options[:path],
        query: "?t=#{@token}"
      )

      RestClient.post(uri.to_s, payload)
    end

    def close(payload = {}, options = {})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      # This request seems to need the data as a query string. I was getting a
      # 500 when I posted a hash. A map will do the needful.

      uri = URI::HTTPS.build(
        host:  options[:host],
        path:  options[:path] + 'close',
        query: URI.escape(
            payload.map { |k, v| [k, v].join('=') }.join('&') + "&t=#{@token}"
        )
      )

      RestClient.post(uri.to_s, payload)
    end

    private

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
