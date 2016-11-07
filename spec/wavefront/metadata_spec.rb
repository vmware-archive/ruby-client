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

describe Wavefront::Metadata do

  it 'has some defaults' do
    expect(Wavefront::Metadata::DEFAULT_HOST).to_not be_nil
    expect(Wavefront::Metadata::DEFAULT_HOST).to be_a_kind_of String
    expect(Wavefront::Metadata::DEFAULT_PATH).to_not be_nil
    expect(Wavefront::Metadata::DEFAULT_PATH).to be_a_kind_of String
  end


  describe "#initialize" do
    it 'accepts a token option initialized and exposes request header for reading' do
      wave = Wavefront::Metadata.new(TEST_TOKEN)
      headers = {'X-AUTH-TOKEN' => TEST_TOKEN}
      expect(wave.headers).to eq headers
    end
  end
  
end
