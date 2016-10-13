require 'rest_client'
require 'uri'
require 'wavefront/client/version'
require 'wavefront/mixins'
require 'wavefront/validators'
require 'wavefront/constants'
require 'wavefront/exception'

module Wavefront
  #
  # Because of the way the 'manage' API is laid out, this class doesn't
  # reflect it as clearly as, say the 'alerts' class.
  #
  # Note that the following methods do not do any exception handling. It
  # is up to your client code to decide how to deal with, for example, a
  # RestClient::ResourceNotFound exception.
  #
  class Sources
    DEFAULT_PATH = '/api/manage/source/'.freeze
    include Wavefront::Constants
    include Wavefront::Mixins
    include Wavefront::Validators

    attr_reader :headers

    def initialize(token, debug = false)
      @headers = { :'X-AUTH-TOKEN' => token }
      debug(debug)
    end

    def delete_tags(source)
      #
      # Delete all tags from a source. Maps to
      # DELETE /api/manage/source/{source}/tags
      #
      raise Wavefront::Exception::InvalidSource unless valid_source?(source)
      call_delete(build_uri(uri_concat(source, 'tags')))
    end

    def delete_tag(source, tag)
      #
      # Delete a given tag from a source. Maps to
      # DELETE /api/manage/source/{source}/tags/{tag}
      #
      raise Wavefront::Exception::InvalidSource unless valid_source?(source)
      raise Wavefront::Exception::InvalidString unless valid_string?(tag)
      call_delete(build_uri(uri_concat(source, 'tags', tag)))
    end

    def show_sources(params = {})
      #
      # return a list of sources. Maps to
      # GET /api/manage/source
      # call it with a hash as described in the Wavefront API docs.
      #
      # At the time of writing, supported paramaters are:
      #   lastEntityId (string)
      #   desc         (bool)
      #   limit        (int)
      #   pattern      (string)
      #
      # Hash keys should be symbols.
      #
      if params.has_key?(:lastEntityId) &&
         !params[:lastEntityId].is_a?(String)
        raise TypeError
      end

      if params.has_key?(:pattern) && !params[:pattern].is_a?(String)
        raise TypeError
      end

      if params.has_key?(:desc) && ! (params[:desc] == !!params[:desc])
        raise TypeError
      end

      if params.has_key?(:limit)
        raise TypeError unless params[:limit].is_a?(Numeric)

        if params[:limit] < 0 || params[:limit] >= 10000
          raise Wavefront::Exception::ValueOutOfRange
        end
      end

      call_get(build_uri(nil, query: hash_to_qs(params)))
    end

    def show_source(source)
      #
      # return information about a single source. Maps to
      # GET /api/manage/source/{source}
      #
      raise Wavefront::Exception::InvalidSource unless valid_source?(source)
      call_get(build_uri(source))
    end

    def set_description(source, desc)
      #
      # set the description field for a source. Maps to
      # POST /api/manage/source/{source}/description
      #
      raise Wavefront::Exception::InvalidSource unless valid_source?(source)
      raise Wavefront::Exception::InvalidString unless valid_string?(desc)
      call_post(build_uri(uri_concat(source, 'description')), desc)
    end

    def set_tag(source, tag)
      #
      # set a tag on a source. Maps to
      # POST /api/manage/source/{source}/tags/{tag}
      #
      raise Wavefront::Exception::InvalidSource unless valid_source?(source)
      raise Wavefront::Exception::InvalidString unless valid_string?(tag)
      call_post(build_uri(uri_concat(source, 'tags', tag)))
    end

    private

    def build_uri(path_ext = '', options = {})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      URI::HTTPS.build(
        host:  options[:host],
        path:  uri_concat(options[:path], path_ext),
        query: options[:query]
      )
    end

    def call_get(uri)
      RestClient.get(uri.to_s, headers)
    end

    def call_delete(uri)
      RestClient.delete(uri.to_s, headers)
    end

    def call_post(uri, query = nil)
      h = headers

      RestClient.post(uri.to_s, query, h.merge(
        :'Content-Type' => 'text/plain', :Accept => 'application/json'
      ))
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
