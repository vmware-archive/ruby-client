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
require 'rest_client'
require 'uri'
require 'logger'

module Wavefront
  class Metadata
    DEFAULT_PATH = '/api/manage/source/'

    attr_reader :headers, :base_uri

    def initialize(token, host=DEFAULT_HOST, debug=false)
      @headers = {'X-AUTH-TOKEN' => token}
      @base_uri = URI::HTTPS.build(:host => host, :path => DEFAULT_PATH)
      debug(debug)
    end

    def get_tags(hostname='', limit=100)
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

      return response
 
    end

    def add_tags(hostnames, tags)
      
      # Build and call tagging URI for each host and tag.
      hostnames.each do |hostname|
        host_uri = URI.join(@base_uri.to_s,"#{hostname}/")
        extended_uri = URI.join(host_uri.to_s,"tags/")        
        tags.each do |tag|
          final_uri = URI.join(extended_uri.to_s,tag)
          RestClient.post(final_uri.to_s, {}, @headers)
        end
      end

    end

    def remove_tags(hostnames, tags, options={})
          
      hostnames.each do |hostname|
        host_uri = URI.join(@base_uri.to_s,"#{hostname}/")
        extended_uri = URI.join(host_uri.to_s,"tags/")
        tags.each do |tag|
          final_uri = URI.join(extended_uri.to_s,tag)
          RestClient.delete(final_uri.to_s, @headers)
        end
      end

    end

    private

    def debug(enabled)
      if enabled
        RestClient.log = 'stdout'
      end
    end

  end
end
