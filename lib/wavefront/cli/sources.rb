require 'wavefront/cli'
require 'wavefront/sources'
require 'json'
require 'pp'

class Wavefront::Cli::Sources < Wavefront::Cli
  attr_accessor :wf, :format, :show_hidden, :show_tags

  def run
    @wf = Wavefront::Sources.new(options[:token])
    @format = options[:format]
    @show_hidden = options[:all]
    @show_tags = options[:tags]

    if options[:list]
      list_source_handler(options[:'<pattern>'], options[:start],
                          options[:limit], options[:reverse])
    elsif options[:show]
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

  def list_source_handler(pattern, start, limit, desc)
    start ||= 0
    limit ||= 100

    q = {
      lastEntityId: start,
      desc:         desc,
      limit:        limit,
      pattern:      pattern,
    }

    display_data(JSON.load(wf.show_sources(q)), 'list_source')
  end

  def describe_handler(hosts, desc)
    hosts = [Socket.gethostname] if hosts.empty?

    hosts.each do |h|
      if desc.empty?
        puts "clearing description of '#{h}'"
      else
        puts "setting '#{h}' description to '#{desc}'"
      end

      begin
        wf.set_description(h, desc)
      rescue Wavefront::Exception::InvalidString
        puts 'ERROR: description contains invalid characters.'
      end
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
        begin
          wf.set_tag(h, t)
        rescue Wavefront::Exception::InvalidString
          puts 'ERROR: tag contains invalid characters.'
        end
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
        result = JSON.load(wf.show_source(s))
      rescue RestClient::ResourceNotFound
        puts "Source '#{s}' not found."
        next
      end

      display_data(result, 'show_source')
    end
  end

  def display_data(result, method)
    if format == 'human'
      puts self.public_send('humanize_' + method, result)
    elsif format == 'json'
      puts result.to_json
    else
      pp result
    end
  end

  def humanize_list_source(result)
    hdr = ['%-25s %-30s %s' % %w(HOSTNAME DESCRIPTION TAGS)]
    ret = result['sources'].each_with_object(hdr) do |s, ret|
      if s.include?('userTags') && s['userTags'].include?('hidden') && !
        show_hidden
        next
      end

      if s['description']
        desc = s['description']
        if desc.length > 30
          desc = desc[0..27] + '...'
        end
      else
        desc = ''
      end

      if s['userTags']
        tags = s['userTags'].join(', ')
      else
        tags = ''
      end

      ret.<< ['%-25s %-30s %s' % [s['hostname'], desc, tags]]
    end

    if show_tags
      ret.<< ['', '%-25s%s' % %w(TAG COUNT)]

      result['counts'].each do |tag, count|
        ret.<< ['%-25s%s' % [tag, count]]
      end
    end

    ret.join("\n")
  end

  def humanize_show_source(data)
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
end
