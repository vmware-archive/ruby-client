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

require 'spec_helper'
require 'pathname'
require 'tempfile'

# A sample config file with two profiles.
#
pf_src = %Q(
[default]
token = 12345678-abcd-1234-abcd-123456789012
endpoint = metrics.wavefront.com
format = human
proxy = wavefront.localnet

[other]
token = abcdefab-0123-abcd-0123-abcdefabcdef
endpoint = test.wavefront.com
format = human
)

describe Wavefront::Cli do

  profile = Tempfile.new('wf_test_profile')
  cf = profile.path
  profile.write(pf_src)
  profile.close

  it 'does not complain when there is no config file' do
    k = Wavefront::Cli.new({config: '/no/file', profile: 'default'}, false)
    expect(k.load_profile).to be_kind_of(NilClass)
  end

  it 'loads the specified profile' do
    k = Wavefront::Cli.new({config: cf, profile: 'other'}, false)
    pf = k.load_profile
    expect(pf).not_to include('proxy')
    expect(pf[:token]).to eq('abcdefab-0123-abcd-0123-abcdefabcdef')
  end

  it 'loads the default when no profile is specified' do
    k = Wavefront::Cli.new({config: cf}, false)
    pf = k.load_profile
    expect(pf[:proxy]).to eq('wavefront.localnet')
    expect(pf[:token]).to eq('12345678-abcd-1234-abcd-123456789012')
  end

  it 'prefers command-line options to config file values' do
    k = Wavefront::Cli.new({config: cf, format: 'graphite'}, false)
    pf = k.load_profile
    expect(pf[:format]).to eq('graphite')
    expect(pf[:token]).to eq('12345678-abcd-1234-abcd-123456789012')
  end
end
