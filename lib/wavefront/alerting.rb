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

    def initialize(token)
      @token = token
    end

    def active(options={})

      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      uri = URI::HTTPS.build(:host => options[:host], :path => options[:path])
      uri = URI.join(uri.to_s,"active")
      uri = URI.join(uri.to_s,"?t=#{@token}")
      
      response = RestClient.get(uri.to_s)

      return response
    end

    private

    def debug(enabled)
      if enabled
        RestClient.log = 'stdout'
      end
    end

  end
end
