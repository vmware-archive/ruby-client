=begin
    Copyright 2015 Wavefront Inc.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
   limitations under the License.

=end

require_relative '../spec_helper'
require 'pathname'
require 'socket'

# DEFAULT_OPTS come from the real constants.rb file

describe Wavefront::OptHandler do
  it 'uses defaults if nothing else is supplied' do
    opts = Wavefront::OptHandler.new(Pathname.new('/nofile'), {}).opts

    expect(opts.class).to be(Hash)
    expect(opts[:endpoint]).to eq('metrics.wavefront.com')
    expect(opts[:host]).to eq(Socket.gethostname)
    expect(opts[:sourceformat]).to eq(:human)
  end

  it 'ensures options override defaults' do
    cli_opts = {
      endpoint: 'myendpoint.wavefront.com',
      sourceformat: 'ruby',
    }

    opts = Wavefront::OptHandler.new(Pathname.new('/nofile'), cli_opts).opts

    expect(opts.class).to be(Hash)
    expect(opts[:endpoint]).to eq('myendpoint.wavefront.com')
    expect(opts[:host]).to eq(Socket.gethostname)
    expect(opts[:sourceformat]).to eq('ruby')
  end

  it 'ensures default config file values override defaults' do
    opts = Wavefront::OptHandler.new(CF, {}).opts

    expect(opts.class).to be(Hash)
    expect(opts[:endpoint]).to eq('default.wavefront.com')
    expect(opts[:host]).to eq(Socket.gethostname)
    expect(opts[:sourceformat]).to eq('raw')
    expect(opts[:format]).to eq(:raw)
  end

  it 'ensures alternate stanza config file values override defaults' do
    opts = Wavefront::OptHandler.new(CF, {profile: 'other'}).opts

    expect(opts.class).to be(Hash)
    expect(opts[:endpoint]).to eq('other.wavefront.com')
    expect(opts[:host]).to eq(Socket.gethostname)
    expect(opts[:sourceformat]).to eq(:human)
    expect(opts[:format]).to eq(:raw)
  end

  it 'ensures command line options override defaults and config files' do
    cli_opts = {
      endpoint: 'cli.wavefront.com',
      sourceformat: 'ruby',
    }

    opts = Wavefront::OptHandler.new(CF, cli_opts).opts

    expect(opts.class).to be(Hash)
    expect(opts[:endpoint]).to eq('cli.wavefront.com')
    expect(opts[:host]).to eq(Socket.gethostname)
    expect(opts[:sourceformat]).to eq('ruby')
    expect(opts[:format]).to eq(:raw)
  end

  it 'issues a warning if there is no config file' do
    expect{Wavefront::OptHandler.new(Pathname.new('/nofile'), {})}.
      to match_stdout("'/nofile' not found. Taking options from command-line.")
  end

end
