=begin
    Copyright 2016 Wavefront Inc.
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

describe Wavefront::Events do

  describe "#initialize" do
    it 'puts the token in a suitable header' do
      k = Wavefront::Events.new(TEST_TOKEN)
      expect(k.headers).to eq({ :'X-AUTH-TOKEN' =>  TEST_TOKEN })
    end
  end

  describe '#create_uri' do
    it 'generates a correct URI if host and path are supplied' do
      k = Wavefront::Events.new(TEST_TOKEN)
      res = k.create_uri({
        host: 'test.wavefront.com', path: '/alternate/api/'
      })

      expect(res).to be_kind_of(URI)
      expect(res.port).to be(443)
      expect(res.host).to eq('test.wavefront.com')
      expect(res.path).to eq('/alternate/api/')
      expect(res.query).to be(nil)
    end

    it 'generates a correct URI if no host or path are supplied' do
      k = Wavefront::Events.new(TEST_TOKEN)
      res = k.create_uri

      expect(res).to be_kind_of(URI)
      expect(res.port).to be(443)
      expect(res.host).to eq('metrics.wavefront.com')
      expect(res.path).to eq('/api/events/')
      expect(res.query).to be(nil)
    end
  end

  describe '#close_uri' do
    it 'generates a correct URI if host and path are supplied' do
      k = Wavefront::Events.new(TEST_TOKEN)
      res = k.close_uri({
        host: 'test.wavefront.com', path: '/alternate/api/'
      })

      expect(res).to be_kind_of(URI)
      expect(res.port).to be(443)
      expect(res.host).to eq('test.wavefront.com')
      expect(res.path).to eq('/alternate/api/close')
      expect(res.query).to be(nil)
    end

    it 'generates a correct URI if no host or path are supplied' do
      k = Wavefront::Events.new(TEST_TOKEN)
      res = k.close_uri

      expect(res).to be_kind_of(URI)
      expect(res.port).to be(443)
      expect(res.host).to eq('metrics.wavefront.com')
      expect(res.path).to eq('/api/events/close')
      expect(res.query).to be(nil)
    end
  end

  describe '#create_qs' do
    payload = { key1: 'val1', key2: 'val2' }

    it 'generates a query string with no hosts' do
      k = Wavefront::Events.new(TEST_TOKEN)
      expect(k.create_qs(payload)).to eq('key1=val1&key2=val2')
    end

    it 'generates a query string with single host as a string' do
      payload[:h] = ['host1']
      k = Wavefront::Events.new(TEST_TOKEN)
      expect(k.create_qs(payload)).to eq('key1=val1&key2=val2&h=host1')
    end

    it 'generates a query string with multiple hosts' do
      payload[:h] = ['host1', 'host2', 'host3']
      k = Wavefront::Events.new(TEST_TOKEN)
      expect(k.create_qs(payload)).to eq(
        'key1=val1&key2=val2&h=host1&h=host2&h=host3')
    end
  end
end
