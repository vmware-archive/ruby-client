require 'wavefront/writer'
require 'wavefront/cli'
require 'socket'
#
# Push datapoints into Wavefront, via a proxy.
#
class Wavefront::Cli::Write < Wavefront::Cli

  include Wavefront::Constants
  include Wavefront::Mixins

  def run
    #require 'pp'
    #pp options

    valid_value?(options[:'<value>'])
    valid_metric?(options[:'<metric>'])
    ts = options[:time] ? parse_time(options[:time]).to_i : false

    [:proxy, :host].each do |h|
      raise Wavefront::Exception::InvalidHostname unless valid_host?(h)
    end

    write_opts = {
      agent_host:   options[:proxy],
      host_name:    options[:host],
      metric_name:  options[:'<metric>'],
      point_tags:   prep_tags(options[:tag]),
      timestamp:    ts,
      noop:         options[:noop],
    }

    write_metric(options[:'<value>'].to_i, options[:'<metric>'], write_opts)
  end

  def prep_tags(tags)
    return [] unless tags.is_a?(Array)
    tags.map { |t| t.split('=') }
  end

  def write_metric(value, name, opts)
    wf = Wavefront::Writer.new(opts)
    wf.write(value, name, opts)
  end

  def valid_host?(hostname)
    #
    # quickly make sure a hostname looks vaguely sensible
    #
    hostname.match(/^[\w\.\-]+$/)
  end

  def valid_value?(value)
    #
    # Values, it seems, will always come in as strings. We need to
    # cast them to numbers. I don't think there's any reasonable way
    # to allow exponential notation.
    #
  raise Wavefront::Exception::InvalidMetricValue unless value.to_i.to_s == value
  end

  def valid_metric?(metric)
    #
    # Apply some common-sense rules to metric paths. Check it's a
    # string, and that it has at least one dot in it. Don't allow
    # through odd characters or whitespace.
    #
    begin
      raise unless metric.is_a?(String)
      raise unless metric.split('.').size > 1
      raise unless metric.match(/^[\w\.\-_]+$/)
    rescue
      fail Wavefront::Exception::InvalidMetricName
    end
  end
end
