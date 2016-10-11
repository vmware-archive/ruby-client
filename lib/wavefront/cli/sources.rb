require 'wavefront/sources'
require 'wavefront/cli'
require 'json'
require 'pp'

class Wavefront::Cli::Sources < Wavefront::Cli
  attr_accessor :wf, :format

  def run
    @wf = Wavefront::Sources.new(options[:token])
    @format = options[:format]

    if options[:show]
      show_source_handler(options[:'<host>'])
    elsif options[:tag] && options[:add]
      add_tag_handler(options[:host], options[:'<tag>'])
    elsif options[:tag] && options[:delete]
      delete_tag_handler(options[:host], options[:'<tag>'])
    elsif options[:describe]
      describe_handler(options[:'<host>'], options[:'<description>'])
    elsif options[:undescribe]
      describe_handler(options[:'<host>'], '')
    elsif options[:untag]
      untag_handler(options[:'<host>'])
    else
      fail 'undefined sources error'
    end
  end

  def describe_handler(hosts, desc)
    hosts = [Socket.gethostname] if hosts.empty?

    hosts.each do |h|
      if desc.empty?
        puts "clearing description of '#{h}'"
      else
        puts "setting '#{h}' description to '#{desc}'"
      end

      wf.set_description(h, desc)
    end
  end

  def untag_handler(hosts)
    hosts ||= [Socket.gethostname]

    hosts.each do |h|
      puts "Removing all tags from '#{h}'"
      wf.delete_tags(h)
    end
  end

  def add_tag_handler(hosts, tags)
    hosts ||= [Socket.gethostname]

    hosts.each do |h|
      tags.each do |t|
        puts "Tagging '#{h}' with '#{t}'"
        wf.set_tag(h, t)
      end
    end
  end

  def delete_tag_handler(hosts, tags)
    hosts ||= [Socket.gethostname]

    hosts.each do |h|
      tags.each do |t|
        puts "Removing tag '#{t}' from '#{h}'"
        wf.delete_tag(h, t)
      end
    end
  end

  def show_source_handler(sources)
    sources.each do |s|
      begin
        data = JSON.load(wf.show_source(s))
      rescue RestClient::ResourceNotFound
        puts "Source '#{s}' not found."
        next
      end

      if format == 'human'
        puts humanize_source(data) + "\n"
      elsif format == 'json'
        puts data.to_json
      else
        pp data
      end
    end
  end

  def humanize_source(data)
    ret = [data['hostname']]

    if data['description']
      ret.<< [('  %-15s%s' % ['description', data['description']])]
    end

    if data['userTags']
      ret.<< [('  %-15s%s' % ['tags', data['userTags'].shift])]
      data['userTags'].each { |t| ret.<< [('  %-15s%s' % ['', t])] }
    end

    ret.join("\n")
  end

=begin
  def format_result(result, format)
    #
    # Call a suitable method to display the output of the API call,
    # which is JSON.
    #
    case format
    when :ruby
      pp result
    when :json
      puts JSON.pretty_generate(JSON.parse(result))
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
    s = wfa.public_methods(false).sort
    s.delete(:token)
    unless s.include?(state)
      raise 'State must be one of: ' + s.each { |q| q.to_s }.join(', ') +
        '.'
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
      end
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
    human_line(k, Time.at(v / 1000))
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
    line.gsub(/(.{1,#{cols - offset}})(\s+|\Z)/, "\\1\n#{' ' *
              offset}").rstrip
  end
=end
end
