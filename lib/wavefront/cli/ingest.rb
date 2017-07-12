require 'socket'
require 'date'
require 'wavefront/constants'
require 'wavefront/mixins'
require 'wavefront/ingest'
require 'wavefront/cli'
#
# Push datapoints into Wavefront, via the API. This uses an undocumented,
# unstable interface, and should be used with caution.
# It cannot batch, or deal with files or streams of data.
#
class Wavefront::Cli::Ingest < Wavefront::Cli
  include Wavefront::Constants
  include Wavefront::Mixins

  def run
    valid_value?(options[:'<value>'])
    valid_metric?(options[:'<metric>'])
    write_metric(options[:'<value>'].to_f, options[:'<metric>'])
  end

  def write_metric(value, name)
    wf = Wavefront::Ingest.new(@options[:token], @options[:endpoint],
                               @options[:debug],
                               { noop: @options[:noop],
                                 verbose: @options[:verbose]})

    point = { value: value }
    tags = prep_tags(options[:tag])
    point[:tags] = Hash[tags] if tags

    body = { name => point }

    wf.write(body, options[:host], options[:time] || Time.now)
  end

  def valid_host?(hostname)
    #
    # quickly make sure a hostname looks vaguely sensible
    #
    hostname.match(/^[\w\.\-]+$/) && hostname.length < 1024
  end

  def valid_value?(value)
    #
    # Values, it seems, will always come in as strings. We need to
    # cast them to numbers. I don't think there's any reasonable way
    # to allow exponential notation.
    #
    unless value.is_a?(Numeric) || value.match(/^-?\d*\.?\d*$/) ||
           value.match(/^-?\d*\.?\d*e\d+$/)
      fail Wavefront::Exception::InvalidMetricValue
    end
    true
  end

  def valid_metric?(metric)
    #
    # Apply some common-sense rules to metric paths. Check it's a
    # string, and that it has at least one dot in it. Don't allow
    # through odd characters or whitespace.
    #
    begin
      fail unless metric.is_a?(String) &&
                  metric.split('.').length > 1 &&
                  metric.match(/^[\w\-\._]+$/) &&
                  metric.length < 1024
    rescue
      raise Wavefront::Exception::InvalidMetricName
    end
    true
  end

  def prep_tags(tags)
    #
    # Takes an array of key=value tags (as produced by docopt) and
    # turns it into an array of [key, value] arrays (as required
    # by various of our own methods). Anything not of the form
    # key=val is dropped.
    #
    return [] unless tags.is_a?(Array)
    tags.map { |t| t.split('=') }.select { |e| e.length == 2 }
  end
end
