#!/usr/bin/env ruby

#     Copyright 2015 Wavefront Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.

require 'wavefront/alerting'
require 'wavefront/cli'
require 'json'
require 'pp'

class Wavefront::Cli::Alerts < Wavefront::Cli

  attr_accessor :options, :arguments

  def run
    alerts = Wavefront::Alerting.new(@options[:token])
    queries = alerts.public_methods(false).sort
    queries.delete(:token)
    query = arguments[0].to_sym

    # This isn't especially nice, but if require to
    # avoiding breaking the Alerting interface :(
    options = Hash.new
    options[:host] = @options[:endpoint]

    if @options[:shared]
      options[:shared_tags] = @options[:shared].delete(' ').split(',')
    end
    if @options[:private]
      options[:private_tags] = @options[:private].delete(' ').split(',')
    end

    if queries.include?(query)
      result = alerts.send(query, options)
    else
      puts "Your query should be one of: #{ queries.each {|q| q.to_s}.join(', ') }"
      exit 1
    end

    case @options[:format].to_sym
    when :ruby
      pp result
    when :json
      puts JSON.pretty_generate(JSON.parse(result))
    else
      puts "Invalid output format, See --help for more detail."
      exit 1
    end
  end
end
