require 'pathname'
require 'open3'
require 'ostruct'
require 'wavefront/client/version'
require 'json'
require 'socket'
require 'date'
require 'uri'

ROOT = Pathname.new(__FILE__).dirname.parent
WF = ROOT + 'bin' + 'wavefront'
LIB = ROOT + 'lib'
CF = ROOT + 'spec' + 'wavefront' + 'resources' + 'conf.yaml'

# Things from the sample config file, for shorthand
#
DEF_TOKEN = '12345678-abcd-1234-abcd-123456789012'
OTHER_TOKEN = 'abcdefab-0123-abcd-0123-abcdefabcdef'

# Some standard start and end times
#
TIME = {
  start: {
    eng: '12:00',
    i:    DateTime.parse('12:00').to_time.to_i,
    ms:   DateTime.parse('12:00').to_time.to_i * 1000
  },
  end: {
    eng: '12:05',
    i:    DateTime.parse('12:05').to_time.to_i,
    ms:   DateTime.parse('12:05').to_time.to_i * 1000
  }
}

def raw(str)
  # eval. I know. But some things dump raw Ruby hashes in the debug output. This
  # parses them so you can check them. They'll be prefixed with 'POST' or 'GET'
  #
  eval(str.split[1..-1].join(' '))
end

def wf(args = '')
  ret = OpenStruct.new
  env = {'RUBYLIB' => LIB.to_s}

  puts "testing #{WF} #{args}"
  stdout, stderr, status = Open3.capture3(env, "#{WF} #{args}")

  ret.status = status.exitstatus
  ret.stdout_a = stdout.split("\n")
  ret.stdout = stdout.strip
  ret.stderr_a = stderr.split("\n")
  ret.stderr = stderr.strip
  ret
end

# A matcher that tells you whether you have a key=value setting in a query
# string. Call it with have_element([:key, value])
#
RSpec::Matchers.define :have_element do |expected|
  match do |str|
    str.sub(/^\S+ /, '').sub(/^=/, '').split('&').each_with_object([]) do |e, aggr|
      k, v = e.split('=')
      aggr.<< [k.to_sym, v]
    end.include?([expected[0].to_sym, URI.escape(expected[1].to_s)])
  end
end

# This script is able to run REAL tests against a REAL Wavefront
# account. It will add, change, and delete data. Do not do it unless you
# are sure you want to do it and you understand what it will do! You need a
# config file with a stanza called "cli-test", which has valid WF credentials.
#
run_real = true

if run_real
  REAL_CF = Pathname.new(ENV['HOME']) + '.wavefront'
  LIVE_OPTS = "-c #{REAL_CF} -P cli-test"

  if ! REAL_CF.exist?
    puts "cannot run real tests, no config at #{REAL_CF}"
    run_real = false
  elsif ! IO.read(REAL_CF).split("\n").include?('[cli-test]')
    puts "cannot run real tests, no 'cli-test' stanza in #{REAL_CF}"
    run_real = false
  end
end

describe 'usage' do
  commands = %w(alerts event source ts write)

=begin
  it 'prints usage and exits 1 with no args' do
    o = wf
    expect(o.stdout).to be_empty
    expect(o.stderr_a.first).to eq('Usage:')
    expect(o.status).to eq(1)
  end

  it 'prints detailed usage with --help' do
    o = wf('--help')
    expect(o.stdout).to be_empty
    expect(o.stderr_a.first).to eq('Wavefront CLI')
    expect(o.status).to eq(1)
    commands.each { |cmd| expect(o.stderr).to match(/\n  #{cmd} /) }
  end

  commands.each do |cmd|
    it "prints help for the #{cmd} command" do
      o = wf("#{cmd} --help")
      expect(o.status).to eq(1)
      expect(o.stdout).to be_empty
      expect(o.stderr_a.first).to eq('Usage:')
      expect(o.stderr_a).to include('Global options:')
    end
  end

  it 'displays the correct version number' do
    include Wavefront::Client
    o = wf('--version')
    expect(o.status).to eq(1)
    expect(o.stdout).to be_empty
    expect(o.stderr).to eq(Wavefront::Client::VERSION)
  end
=end
end

describe 'alerts mode' do
=begin
  it 'fails with no token if there is no token' do
    o = wf('alerts -c/nf -E metrics.wavefront.com active')
    expect(o.status).to eq(1)
    expect(o.stderr).to eq('alerts query failed. Please supply an API token.')
    expect(o.stdout).to eq("config file '/nf' not found. Taking options from command-line.")
  end

  it 'fails with a helpful message if an invalid state is given' do
    o = wf('alerts -n -c/nf -t token -E metrics.wavefront.com badstate')
    expect(o.status).to eq(1)
    expect(o.stderr).to eq('alerts query failed. State must be one of: active, ' \
                           'affected_by_maintenance, all, invalid, snoozed.')
    expect(o.stdout).to eq("config file '/nf' not found. Taking options from command-line.")
  end

  it 'performs a verbose noop with a CLI endpoint' do
    o = wf('alerts -n -c/nf -t token -E test.wavefront.com active')
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a[-1]).to eq('GET https://test.wavefront.com/api/alert/active?t=token')
  end

  it 'performs a verbose noop with default config file options' do
    o = wf("alerts -n -c #{CF} active")
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a.last).to eq(
      "GET https://default.wavefront.com/api/alert/active?t=#{DEF_TOKEN}")
  end

  it 'performs a verbose noop with config file and CLI options' do
    o = wf("alerts -n -c #{CF} -E cli.wavefront.com active")
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a.last).to eq(
      "GET https://cli.wavefront.com/api/alert/active?t=#{DEF_TOKEN}")
  end

  if run_real
    keys = %w(name created severity condition alertStates)

    it 'fetches and correctly formats alerts from config file and CLI options' do
      o = wf("alerts #{LIVE_OPTS} -f human all")
      expect(o.status).to eq(0)
      expect(o.stderr).to be_empty
      expect(o.stdout_a.first).to start_with('name ')
      keys.each { |key| expect(o.stdout).to start_with(key + ' ') }
    end

    it 'fetches and correctly formats alerts from config file' do
      o = wf("alerts #{LIVE_OPTS} all")
      expect(o.status).to eq(0)
      expect(o.stderr).to be_empty
      r = JSON.parse(o.stdout)
      expect(r).to be_instance_of(Array)
      expect(r.first).to be_instance_of(Hash)
      keys.each { |key| expect(r.first.keys).to include(key) }
    end
  end
=end
end

describe 'event mode' do
=begin
  cmds = %w(create close delete).each do |cmd|
    it "#{cmd} fails with no token if there is no token" do
      o = wf("event #{cmd} -c/nf #{cmd == 'delete' ? 'arg1 arg2' : 'arg1'}")
      expect(o.status).to eq(1)
      expect(o.stderr).to eq('Please supply an API token.')
      expect(o.stdout).to eq(
        "config file '/nf' not found. Taking options from command-line.")
    end
  end

  describe 'create subcommand' do
    it 'performs a verbose noop with default options' do
      o = wf('event create -c/nf -t token -n test_ev')
      expect(o.status).to eq(0)
      expect(o.stderr).to be_empty
      expect(o.stdout_a[-3]).to eq('PUT https://metrics.wavefront.com/api/events/')
      expect(o.stdout_a[-2]).to have_element([:h, Socket.gethostname])
      expect(o.stdout_a[-1]).to eq('HEADERS {:"X-AUTH-TOKEN"=>"token"}')
    end

    it 'performs a verbose noop on a bounded event with command-line options' do
      o = wf("event create -c/nf --start #{TIME[:start][:eng]} --end #{TIME[:end][:eng]} " \
             "-t token -d 'some description' -l info -E test.wavefront.com -n test_ev")
      expect(o.status).to eq(0)
      expect(o.stderr).to be_empty
      expect(o.stdout_a[-3]).to eq('PUT https://test.wavefront.com/api/events/')
      expect(o.stdout_a[-2]).to have_element([:h, Socket.gethostname])
      expect(o.stdout_a[-2]).to have_element([:s, TIME[:start][:ms]])
      expect(o.stdout_a[-2]).to have_element([:e, TIME[:end][:ms]])
      expect(o.stdout_a[-2]).to have_element([:l, 'info'])
      expect(o.stdout_a[-2]).to have_element([:c, false])
      expect(o.stdout_a[-2]).to have_element([:d, 'some description'])
      expect(o.stdout_a[-1]).to eq('HEADERS {:"X-AUTH-TOKEN"=>"token"}')
    end

    it 'performs a verbose noop on an unbounded event with CLI and file options' do
      o = wf("event create -c #{CF} -P other -s #{TIME[:start][:eng]} " \
             "-t token -H i-123456,i-abcdef -d 'some description' -n test_ev")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-3]).to eq('PUT https://other.wavefront.com/api/events/')
      expect(o.stdout_a[-2]).to have_element([:h, 'i-123456'])
      expect(o.stdout_a[-2]).to have_element([:h, 'i-abcdef'])
      expect(o.stdout_a[-2]).to have_element([:s, TIME[:start][:ms]])
      expect(o.stdout_a[-2]).not_to match(/&e=/)
      expect(o.stdout_a[-2]).to have_element([:c, false])
      expect(o.stdout_a[-2]).to have_element([:d, 'some description'])
    end

    it 'performs a verbose noop on an instantaneous event with CLI and file options' do
      o = wf("event create -c #{CF} -i -H i-123456 " \
             "-d 'some description' -l smoke -E test.wavefront.com -n test_ev")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-3]).to eq('PUT https://test.wavefront.com/api/events/')
      expect(o.stdout_a[-2]).to have_element([:h, 'i-123456'])
      expect(o.stdout_a[-2]).not_to match(/&s=/)
      expect(o.stdout_a[-2]).not_to match(/&e=/)
      expect(o.stdout_a[-2]).to have_element([:c, 'true'])
      expect(o.stdout_a[-2]).to have_element([:l, 'smoke'])
      expect(o.stdout_a[-2]).to have_element([:d, 'some description'])
      expect(o.stdout_a[-1]).to eq("HEADERS {:\"X-AUTH-TOKEN\"=>\"#{DEF_TOKEN}\"}")
    end
  end
=end

  if run_real
    it 'creates a real event using config file options' do
      o = wf("event create #{LIVE_OPTS} -V -d 'CLI test event' -l test " \
             '-E test.wavefront.com cli_test_event')
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-3]).to eq('PUT https://test.wavefront.com/api/events/')
      expect(o.stdout_a[-2]).to have_element([:h, 'i-123456'])
      expect(o.stdout_a[-2]).not_to match(/&s=/)
      expect(o.stdout_a[-2]).not_to match(/&e=/)
      expect(o.stdout_a[-2]).to have_element([:c, 'true'])
      expect(o.stdout_a[-2]).to have_element([:l, 'smoke'])
      expect(o.stdout_a[-2]).to have_element([:d, 'some description'])
      expect(o.stdout_a[-1]).to eq("HEADERS {:\"X-AUTH-TOKEN\"=>\"#{DEF_TOKEN}\"}")
    end
  end

=begin
  describe 'close subcommand' do
    it 'refuses to close an unknown event' do
      o = wf("event close -c #{CF} -t token -n uknown_event")
      expect(o.stderr).to eq("event query failed. No event 'uknown_event' to close.")
      expect(o.status).to eq(1)
      expect(o.stdout).to be_empty
    end

    it 'performs a verbose noop with default options' do
      o = wf("event close -c/nf -t token -n test_ev #{TIME[:start][:ms]}")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-3]).to eq('PUT https://metrics.wavefront.com/api/events/close')
      expect(o.stdout_a[-2]).to have_element([:s, TIME[:start][:ms]])
      expect(o.stdout_a[-2]).to have_element([:n, 'test_ev'])
      expect(o.stdout_a[-1]).to eq('HEADERS {:"X-AUTH-TOKEN"=>"token"}')
    end

    it 'performs a verbose noop with CLI and file options' do
      o = wf("event close -P other -c #{CF} -t token -n test_ev #{TIME[:start][:ms]}")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-3]).to eq('PUT https://other.wavefront.com/api/events/close')
      expect(o.stdout_a[-2]).to have_element([:s, TIME[:start][:ms]])
      expect(o.stdout_a[-2]).to have_element([:n, 'test_ev'])
      expect(o.stdout_a[-1]).to eq('HEADERS {:"X-AUTH-TOKEN"=>"token"}')
    end

    it 'performs a verbose noop with CLI options' do
      o = wf("event close -c/nf -E cli.wavefront.com -t token -n test_ev #{TIME[:start][:ms]}")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-3]).to eq('PUT https://cli.wavefront.com/api/events/close')
      expect(o.stdout_a[-2]).to have_element([:s, TIME[:start][:ms]])
      expect(o.stdout_a[-2]).to have_element([:n, 'test_ev'])
      expect(o.stdout_a[-1]).to eq('HEADERS {:"X-AUTH-TOKEN"=>"token"}')
    end
  end

  describe 'delete subcommand' do
    it 'performs a verbose noop with default options' do
      o = wf("event delete -c/nf -t token -n #{TIME[:start][:ms]} test_ev")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout_a[-2]).to eq('DELETE https://metrics.wavefront.com/api/events/'\
                                  "#{TIME[:start][:ms]}/test_ev")
      expect(o.stdout_a[-1]).to eq('HEADERS {:"X-AUTH-TOKEN"=>"token"}')
    end
  end
=end
end

describe 'real tests' do
  if run_real
  end
end

describe 'ts mode' do
=begin
  it 'fails with no granularity' do
    o = wf('ts "ts(dev.cli.test)"')
    expect(o.status).to eq(1)
    expect(o.stdout).to be_empty
    expect(o.stderr).to start_with('ts query failed. You must specify a granularity')
  end

  it 'fails with no token if there is no token' do
    o = wf('ts -c/nf -E metrics.wavefront.com "ts(dev.cli.test)"')
    expect(o.status).to eq(1)
    expect(o.stderr).to eq('ts query failed. Please supply an API token.')
    expect(o.stdout).to eq("config file '/nf' not found. Taking options from command-line.")
  end

  it 'performs a verbose noop with default options' do
    o = wf('ts -c/nf -t token -Sn "ts(dev.cli.test)"')
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a[-2]).to eq('GET https://metrics.wavefront.com/chart/api')
    q = raw(o.stdout_a.last)
    expect(q['X-AUTH-TOKEN']).to eq('token')
    expect(q[:params][:g]).to eq('s')
    expect(q[:params][:q]).to eq('ts(dev.cli.test)')
  end

  it 'performs a verbose noop with a CLI endpoint' do
    o = wf('ts -c/nf -t token -Sn -E test.wavefront.com "ts(dev.cli.test)"')
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a[-2]).to eq('GET https://test.wavefront.com/chart/api')
    q = raw(o.stdout_a.last)
    expect(q['X-AUTH-TOKEN']).to eq('token')
    expect(q[:params][:g]).to eq('s')
    expect(q[:params][:q]).to eq('ts(dev.cli.test)')
  end

  it 'performs a verbose noop with default config file options' do
    o = wf("ts -c #{CF} -Hn 'ts(dev.cli.test)'")
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a[-2]).to eq('GET https://default.wavefront.com/chart/api')
    q = raw(o.stdout_a.last)
    expect(q['X-AUTH-TOKEN']).to eq(DEF_TOKEN)
    expect(q[:params][:g]).to eq('h')
    expect(q[:params][:q]).to eq('ts(dev.cli.test)')
  end

  it 'performs a verbose noop with config file and CLI options' do
    o = wf("ts -c #{CF} -P other -mn -E cli.wavefront.com 'ts(dev.cli.test)'")
    expect(o.status).to eq(0)
    expect(o.stderr).to be_empty
    expect(o.stdout_a[-2]).to eq('GET https://cli.wavefront.com/chart/api')
    q = raw(o.stdout_a.last)
    expect(q['X-AUTH-TOKEN']).to eq(OTHER_TOKEN)
    expect(q[:params][:g]).to eq('m')
    expect(q[:params][:q]).to eq('ts(dev.cli.test)')
  end

  if run_real
    it 'gets an empty JSON payload for a silly request' do
      o = wf("ts #{LIVE_OPTS} -f raw -m 'ts(better.not.exist)'")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      r = JSON.parse(o.stdout)
      expect(r['query']).to eq('ts(better.not.exist)')
      expect(r['warnings']).to eq('No metrics matching: [better.not.exist]')
    end

    it 'gets an empty human payload for a silly request' do
      o = wf("ts #{LIVE_OPTS} -f human -m 'ts(better.not.exist)'")
      expect(o.stderr).to be_empty
      expect(o.status).to eq(0)
      expect(o.stdout).to be_empty
    end
  end
=end
end
