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
require "wavefront/exception"
require 'wavefront/validators'
require 'wavefront/mixins'
require 'rest_client'
require 'uri'
require 'logger'

module Wavefront
  #
  # Because of the way the 'manage' API is laid out, this class doesn't
  # reflect it as clearly as, say the 'alerts' class. There is a small
  # amount of duplication in method names too, as it merges a new class
  # and an old one.
  #
  # Note that the following methods do not do any exception handling. It
  # is up to your client code to decide how to deal with, for example, a
  # RestClient::ResourceNotFound exception.
  #
  class Metadata
    include Wavefront::Constants
    include Wavefront::Mixins
    include Wavefront::Validators
    DEFAULT_PATH = '/api/manage/source/'.freeze

    attr_reader :headers, :host, :verbose, :endpoint, :noop

    def initialize(token, host=DEFAULT_HOST, debug=false, options = {})
      #
      # 'host' is the Wavefront API endpoint
      #
      @headers = {'X-AUTH-TOKEN' => token}
      @base_uri = URI::HTTPS.build(:host => host, :path => DEFAULT_PATH)
      @endpoint = host
      @verbose = options[:verbose] || false
      @noop = options[:noop] || false
      debug(debug)
    end

    def get_tags(hostname='', limit=100)
      #
      # This method is capable of making two distinct API calls,
      # depending on the arguments. It is left here for backward
      # compatibility, but you are recommended to use show_source() and
      # show_sources() instead.
      #
      uri = @base_uri

      unless hostname.empty?
        uri = URI.join(@base_uri.to_s, hostname)
      end

      if limit > 10000
        limit = 10000
      end

      args = {:params => {:limit => limit}}.merge(@headers)

      begin
        response = RestClient.get(uri.to_s, args)
      rescue RestClient::ResourceNotFound
        # If a 404 is returned, we return an empty JSON as this is the expected behaviour for untagged hosts
        response = {}
      end

      response
    end

    def add_tags(hostnames, tags)

      # Build and call tagging URI for each host and tag. A
      # backward-compatibility wrapper for set_tag()
      #
      hostnames.each do |hostname|
        tags.each { |tag| set_tag(hostname, tag) }
      end
    end

    def remove_tags(hostnames, tags, _options = {})
      #
      # A backward-compatibilty wrapper to delete_tag().
      #
      hostnames.each do |hostname|
        tags.each { |tag| delete_tag(hostname, tag) }
      end
    end

    def delete_tags(source)
      #
      # Delete all tags from a source. Maps to
      # DELETE /api/manage/source/{source}/tags
      #
      fail Wavefront::Exception::InvalidSource unless valid_source?(source)
      call_delete(build_uri(uri_concat(source, 'tags')))
    end

    def delete_tag(source, tag)
      #
      # Delete a given tag from a source. Maps to
      # DELETE /api/manage/source/{source}/tags/{tag}
      #
      fail Wavefront::Exception::InvalidSource unless valid_source?(source)
      fail Wavefront::Exception::InvalidString unless valid_string?(tag)
      call_delete(build_uri(uri_concat(source, 'tags', tag)))
    end

    def show_sources(params = {})
      #
      # Return a list of sources as a Ruby object. Maps to
      # GET /api/manage/source
      # call it with a hash as described in the Wavefront API docs.
      #
      # See the Wavefront API docs for the format of the returned
      # object.
      #
      # At the time of writing, supported paramaters are:
      #   lastEntityId (string)
      #   desc         (bool)
      #   limit        (int)
      #   pattern      (string)
      #
      # Hash keys should be symbols.
      #
      if params.key?(:lastEntityId) &&
         !params[:lastEntityId].is_a?(String)
        fail TypeError
      end

      if params.key?(:pattern) && !params[:pattern].is_a?(String)
        fail TypeError
      end

      if params.key?(:desc) && ! (params[:desc] == !!params[:desc])
        fail TypeError
      end

      if params.key?(:limit)
        fail TypeError unless params[:limit].is_a?(Numeric)

        if params[:limit] < 0 || params[:limit] >= 10000
          fail Wavefront::Exception::ValueOutOfRange
        end
      end

      resp = call_get(build_uri(nil, query: hash_to_qs(params))) || '{}'
      JSON.parse(resp)
    end

    def show_source(source)
      #
      # return information about a single source as a Ruby object. Maps to
      # GET /api/manage/source/{source}.
      #
      # See the Wavefront API docs for the structure of the object.
      #
      fail Wavefront::Exception::InvalidSource unless valid_source?(source)
      resp = call_get(build_uri(source)) || '{}'

      JSON.parse(resp)
    end

    def set_description(source, desc)
      #
      # set the description field for a source. Maps to
      # POST /api/manage/source/{source}/description
      #
      fail Wavefront::Exception::InvalidSource unless valid_source?(source)
      fail Wavefront::Exception::InvalidString unless valid_string?(desc)
      call_post(build_uri(uri_concat(source, 'description')), desc)
    end

    def set_tag(source, tag)
      #
      # set a tag on a source. Maps to
      # POST /api/manage/source/{source}/tags/{tag}
      #
      fail Wavefront::Exception::InvalidSource unless valid_source?(source)
      fail Wavefront::Exception::InvalidString unless valid_string?(tag)
      call_post(build_uri(uri_concat(source, 'tags', tag)))
    end

    private

    def build_uri(path_ext = '', options = {})
      options[:host] ||= endpoint
      options[:path] ||= DEFAULT_PATH

      URI::HTTPS.build(
        host:  options[:host],
        path:  uri_concat(options[:path], path_ext),
        query: options[:query]
      )
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
