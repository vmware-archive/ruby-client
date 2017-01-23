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
require 'wavefront/mixins'

HOST = 'i-12345678'

describe Wavefront::Mixins do
  include Wavefront::Mixins
  it 'provides a method to interpolate the schema' do
    wavefront_schema = "a.b.c.d.e"
    expect(interpolate_schema(wavefront_schema, HOST, 1)).to eq("a.#{HOST}.b.c.d.e")
    expect(interpolate_schema(wavefront_schema, HOST, 2)).to eq("a.b.#{HOST}.c.d.e")
  end

  it 'provides a method to parse times' do
    expect(parse_time(1469711187)).to eq(1469711187)
    expect(parse_time('1469711187')).to eq(1469711187)
    expect(parse_time('2016-07-28 14:25:36 +0100')).to eq(1469712336)
    expect(parse_time('2016-07-28')).to eq(1469664000)
    expect(parse_time(Time.now)).to be_kind_of(Integer)
    expect{parse_time('nonsense')}.to raise_exception(RuntimeError,
                                  "cannot parse timestamp 'nonsense'.")
  end

  it 'provides a method to convert epoch times to milliseconds' do
    expect(time_to_ms(1469711187)).to eq(1469711187000)
    expect(time_to_ms('1469711187')).to be(false)
  end

  it 'makes a proper query string' do
    expect(hash_to_qs({
      key1: 'val1',
      key2: 'value 2'
    })).to eq('key1=val1&key2=value%202')
  end
end
