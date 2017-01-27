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

describe Wavefront::Metadata do
  attr_reader :wf, :host, :path, :post_headers

  before do
    @wf = Wavefront::Metadata.new(TEST_TOKEN)
    @host = Wavefront::Metadata::DEFAULT_HOST
    @path = Wavefront::Metadata::DEFAULT_PATH
    @post_headers = wf.headers.merge(
      { :'Content-Type' => 'text/plain', :Accept => 'application/json' })

  end

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

  describe "#initialize" do
    it 'enables rest-client debugging if instructed to do so' do
      wf = Wavefront::Metadata.new(TEST_TOKEN, 'somehost', true)
      expect RestClient.log == 'stdout'
    end
  end

  describe '#delete_tags' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:delete).with(
        concat_url(host, path, 'mysource', 'tags'), wf.headers
      )
      wf.delete_tags('mysource')
    end

    it 'raises an exception on an invalid source' do
      expect{wf.delete_tags('!INVALID!')}.
        to raise_exception(Wavefront::Exception::InvalidSource)
    end
  end

  describe '#delete_tag' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:delete).with(
        concat_url(host, path, 'mysource', 'tags', 'mytag'), wf.headers
      )
      wf.delete_tag('mysource', 'mytag')
    end

    it 'raises an exception on an invalid source' do
      expect{wf.delete_tag('INVALID!', 'mytag')}.
        to raise_exception(Wavefront::Exception::InvalidSource)
    end

    it 'raises an exception on an invalid tag' do
      expect{wf.delete_tag('mysource', 'INVALID!')}.
        to raise_exception(Wavefront::Exception::InvalidString)
    end
  end

  describe '#show_sources' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:get).with(
        concat_url(host, path, '?'), wf.headers
      )
      expect(JSON).to receive(:parse)
      wf.show_sources
    end

    it 'makes API request with options' do
      expect(RestClient).to receive(:get).with(
        concat_url(host, path, '?limit=100&pattern=test-*'), wf.headers
      )
      expect(JSON).to receive(:parse)
      wf.show_sources({ limit: 100, pattern: 'test-*' })
    end

    it 'raises an exception on an invalid lastEntityId' do
      expect{wf.show_sources({lastEntityId: nil})}.
        to raise_exception(TypeError)
    end

    it 'raises an exception on an invalid desc' do
      expect{wf.show_sources({desc: 1234})}.
        to raise_exception(TypeError)
    end

    it 'raises an exception on an invalid limit' do
      expect{wf.show_sources({limit: 'abcdef'})}.
        to raise_exception(TypeError)

      expect{wf.show_sources({limit: 10000})}.
        to raise_exception(Wavefront::Exception::ValueOutOfRange)

      expect{wf.show_sources({limit: -1})}.
        to raise_exception(Wavefront::Exception::ValueOutOfRange)
    end

    it 'raises an exception on an invalid pattern' do
      expect{wf.show_sources({pattern: [1, 2, 3]})}.
        to raise_exception(TypeError)
    end
  end

  describe '#show_source' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:get).with(
        concat_url(host, path, 'mysource'), wf.headers
      )
      expect(JSON).to receive(:parse)
      wf.show_source('mysource')
    end

    it 'raises an exception on an invalid source' do
      expect{wf.show_source('!INVALID!')}.
        to raise_exception(Wavefront::Exception::InvalidSource)
    end
  end

  describe '#set_description' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:post).with(
        concat_url(host, path, 'mysource', 'description'),
        'my description', post_headers)
      wf.set_description('mysource', 'my description')
    end

    it 'raises an exception on an invalid source' do
      expect{wf.set_description('!INVALID!', 'my description')}.
        to raise_exception(Wavefront::Exception::InvalidSource)
    end

    it 'raises an exception on an invalid description' do
      expect{wf.set_description('my_source', '!INVALID!')}.
        to raise_exception(Wavefront::Exception::InvalidString)
    end
  end

  describe '#set_tag' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:post).with(
        concat_url(host, path, 'my_source', 'tags', 'my_tag'),
        nil, post_headers)
      wf.set_tag('my_source', 'my_tag')
    end

    it 'raises an exception on an invalid source' do
      expect{wf.set_tag('!INVALID!', 'my_tag')}.
        to raise_exception(Wavefront::Exception::InvalidSource)
    end

    it 'raises an exception on an invalid description' do
      expect{wf.set_tag('my_source', '!INVALID!')}.
        to raise_exception(Wavefront::Exception::InvalidString)
    end

    it 'raises an exception on an invalid tag' do
      expect{wf.set_tag('my_source', '!INVALID!')}.
        to raise_exception(Wavefront::Exception::InvalidString)
    end
  end
end
