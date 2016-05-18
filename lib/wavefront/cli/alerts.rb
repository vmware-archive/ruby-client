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
require 'time'

class Wavefront::Cli::Alerts < Wavefront::Cli

  attr_accessor :options, :arguments

  def run
    alerts = Wavefront::Alerting.new(@options[:token])
    queries = alerts.public_methods(false).sort
    queries.delete(:token)

    raise 'Missing query.' if arguments.empty?
    query = arguments[0].to_sym

    unless queries.include?(query)
      raise 'State must be one of: ' + queries.each {|q| q.to_s}.join(', ')
    end

    unless Wavefront::Client::ALERT_FORMATS.include?(
                                            @options[:format].to_sym)
      raise 'Output format must be one of: ' +
            Wavefront::Client::ALERT_FORMATS.join(', ')
    end

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

    result = alerts.send(query, options)

    case @options[:format].to_sym
    when :ruby
      pp result
    when :json
      puts JSON.pretty_generate(JSON.parse(result))
    when :human
      puts humanize(JSON.parse(result))
    else
      puts "Invalid output format, See --help for more detail."
      exit 1
    end

    exit 0
  end

  def humanize(alerts)
    #
    # Selectively display alert information in an easily
    # human-readable format. I have chosen not to display certain
    # fields which I don't think are useful in this context. I also
    # wish to put the fields in order. Here are the fields I want, in
    # the order I want them.
    #
    row_order = %w(name created severity condition displayExpression
                   minutes resolveAfterMinutes updated alertStates
                   metricsUsed hostsUsed additionalInformation)

    # build up an array of lines then turn it into a string and
    # return it
    #
    # Most things get printed with the human_line() method, but some
    # data needs special handling. To do that, just add a method
    # called human_line_key() where key is something in row_order,
    # and it will be found.
    #
    x = alerts.map do |alert|
      row_order.map do |key|
        lm = "human_line_#{key}"
        if self.respond_to?(lm)
          self.method(lm.to_sym).call(key, alert[key])
        else
          human_line(key, alert[key])
        end
      end
    end
  end

  def human_line(k, v)
    '%-22s%s' % [k, v]
  end

  def human_line_created(k, v)
    #
    # The 'created' and 'updated' timestamps are in epoch
    # milliseconds
    #
    human_line(k, Time.at(v / 1000))
  end

  def human_line_updated(k, v)
    human_line_created(k, v)
  end

  def human_line_hostsUsed(k, v)
    #
    # Put each host on its own line, indented.
    #
    v.sort!
    [human_line(k, v.shift)] + v.map {|el| human_line('', el)}
  end

  def human_line_metricsUsed(k, v)
    human_line_hostsUsed(k, v)
  end

  def human_line_alertStates(k, v)
    human_line(k, v.join(','))
  end

  def human_line_additionalInformation(k, v)
    human_line(k, indent_wrap(v))
  end

  def indent_wrap(line, cols=78, offset=22)
    #
    # hanging indent long lines to fit in an 80-column terminal
    #
    line.gsub(/(.{1,#{cols - offset}})(\s+|\Z)/, "\\1\n#{' ' * offset}")
  end
end
