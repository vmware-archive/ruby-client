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
require 'wavefront/mixins'
require 'json'
require 'yaml'
require 'pp'
require 'time'

class Wavefront::Cli::Alerts < Wavefront::Cli
  include Wavefront::Mixins

  attr_accessor :options, :arguments, :wfa

  def run
    raise 'Missing token.' if ! @options[:token] || @options[:token].empty?
    raise 'Missing query.' if arguments.empty?
    valid_format?(@options[:alertformat].to_sym)

    @wfa = Wavefront::Alerting.new(@options[:token], @options[:endpoint],
                                  @options[:debug], {
      noop: @options[:noop], verbose: @options[:verbose]})

    if options[:export]
      export_alert(options[:'<timestamp>'])
      return
    end

    if options[:import]
      import_alert
      return
    end

    query = arguments[0].to_sym
    valid_state?(wfa, query)
    options = { host: @options[:endpoint] }

    if @options[:shared]
      options[:shared_tags] = @options[:shared].delete(' ').split(',')
    end

    if @options[:private]
      options[:private_tags] = @options[:private].delete(' ').split(',')
    end

    begin
      result = wfa.send(query, options)
    rescue => e
      puts e if @options[:debug]
      raise 'Unable to execute query.'
    end

    format_result(result, @options[:alertformat].to_sym)
    exit
  end

  def import_alert
    begin
      prepped = wfa.import_to_create(load_file(options[:'<file>']))
    rescue => e
      puts e if options[:debug]
      raise 'could not parse input.'
    end

    return if noop

    begin
      wfa.create_alert(prepped)
      puts 'Alert imported.'
    rescue RestClient::BadRequest
      raise '400 error: alert probably exists.'
    end
  end

  def export_alert(id)
    begin
      resp = wfa.get_alert(id)
    rescue => e
      puts e if @options[:debug]
      raise 'Unable to retrieve alert.'
    end

    case options[:alertformat].to_sym
    when :json
      puts JSON.pretty_generate(resp)
    when :yaml
      puts resp.to_yaml
    when :human
      puts humanize([resp])
    else
      puts 'unknown output format.'
    end
  end

  def format_result(result, format)
    #
    # Call a suitable method to display the output of the API call,
    # which is JSON.
    #
    return if noop

    case format
    when :ruby
      pp result
    when :json
      puts JSON.pretty_generate(JSON.parse(result))
    when :yaml
      puts JSON.parse(result).to_yaml
    when :human
      puts humanize(JSON.parse(result))
    else
      raise "Invalid output format '#{format}'. See --help for more detail."
    end
  end

  def valid_format?(fmt)
    fmt = fmt.to_sym if fmt.is_a?(String)

    unless Wavefront::Client::ALERT_FORMATS.include?(fmt)
      raise 'Output format must be one of: ' +
        Wavefront::Client::ALERT_FORMATS.join(', ') + '.'
    end
    true
  end

  def valid_state?(wfa, state)
    #
    # Check the alert type we've been given is valid. There needs to
    # be a public method in the 'alerting' class for every one.
    #
    states = %w(active affected_by_maintenance all invalid snoozed)

    unless states.include?(state.to_s)
      raise "State must be one of: #{states.join(', ')}."
    end
    true
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
      end.<< ''
    end
  end

  def human_line(k, v)
    ('%-22s%s' % [k, v]).rstrip
  end

  def human_line_created(k, v)
    #
    # The 'created' and 'updated' timestamps are in epoch
    # milliseconds
    #
    human_line(k, "#{Time.at(v / 1000)} (#{v})")
  end

  def human_line_updated(k, v)
    human_line_created(k, v)
  end

  def human_line_hostsUsed(k, v)
    #
    # Put each host on its own line, indented. Does this by
    # returning an array.
    #
    return k unless v && v.is_a?(Array) && ! v.empty?
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
    return unless line
    line.gsub(/(.{1,#{cols - offset}})(\s+|\Z)/, "\\1\n#{' ' *
              offset}").rstrip
  end
end
