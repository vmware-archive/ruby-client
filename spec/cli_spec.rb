require 'pathname'
require 'open3'
require 'ostruct'
require 'wavefront/client/version'

ROOT = Pathname.new(__FILE__).dirname.parent
WF = ROOT + 'bin' + 'wavefront'
LIB = ROOT + 'lib'

def wf(args = '')
  ret = OpenStruct.new
  env = {'RUBYLIB' => LIB.to_s}

  stdout, stderr, status = Open3.capture3(env, "#{WF} #{args}")

  ret.status = status.exitstatus
  ret.stdout_a = stdout.split("\n")
  ret.stdout = stdout.strip
  ret.stderr_a = stderr.split("\n")
  ret.stderr = stderr.strip
  ret
end

# This script is able to run REAL tests against a REAL Wavefront
# account. It will add, change, and delete data. Do not do it unless you
# are sure you want to do it and you understand what it will do!
#
RUN_REAL = false

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
end

describe 'event mode' do
end

describe 'source mode' do
end

describe 'ts mode' do
end
