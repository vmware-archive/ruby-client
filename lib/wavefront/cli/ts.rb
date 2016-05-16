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

require 'wavefront/client'
require 'wavefront/cli'
require 'pp'
require 'json'

class Wavefront::Cli::Ts < Wavefront::Cli

  attr_accessor :options, :arguments

  def run
    query = @arguments[0]
    if @options.minutes?
      granularity = 'm'
    elsif @options.hours?
      granularity = 'h'
    elsif @options.seconds?
      granularity = 's'
    elsif @options.days?
      granularity = 'd'
    else
      puts "You must specify a granularity of either --seconds, --minutes --hours or --days. See --help for more information."
      exit 1
    end

    unless Wavefront::Client::FORMATS.include?(@options[:format].to_sym)
      puts "The output format must be on of #{Wavefront::Client::FORMATS.join(', ')}"
      exit 1
    end

    options = Hash.new
    options[:response_format] = @options[:format].to_sym
    options[:prefix_length] = @options[:prefixlength].to_i

    if @options[:start]
      options[:start_time] = Time.at(@options[:start].to_i)
    end

    if @options[:end]
      options[:end_time] = Time.at(@options[:end].to_i)
    end

    wave = Wavefront::Client.new(@options[:token], @options[:endpoint], @options[:debug])
    case options[:response_format]
    when :raw
      puts wave.query(query, granularity, options)
    when :graphite
      puts wave.query(query, granularity, options).graphite.to_json
    else
      pp wave.query(query, granularity, options)
    end

    exit 0
  end
end
