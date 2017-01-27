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

# Just test initialization

describe Wavefront::Cli do
  it 'raises an error if no token is set' do
    wf = Wavefront::Cli.new({}, nil)
    expect{wf.validate_opts}.to raise_exception(RuntimeError)
  end

  it 'raises an error if no endpoint is set' do
    wf = Wavefront::Cli.new({token: 'abcdef' }, nil)
    expect{wf.validate_opts}.to raise_exception(RuntimeError)
  end

  it 'does not raise an error if an endpoint and token are set' do
    wf = Wavefront::Cli.new({token: 'abcdef', endpoint: 'wavefront' }, nil)
    expect{wf.validate_opts}.to_not raise_exception
  end
end
