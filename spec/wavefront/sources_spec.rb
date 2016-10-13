require 'spec_helper'

describe Wavefront::Sources do
  attr_reader :wf, :host, :path

  before do
    @wf = Wavefront::Sources.new(TEST_TOKEN)
    @host = Wavefront::Sources::DEFAULT_HOST
    @path = Wavefront::Sources::DEFAULT_PATH
  end

  it 'has some defaults' do
    expect(Wavefront::Sources::DEFAULT_HOST).to_not be_nil
    expect(Wavefront::Sources::DEFAULT_HOST).to be_a_kind_of String
    expect(Wavefront::Sources::DEFAULT_PATH).to_not be_nil
    expect(Wavefront::Sources::DEFAULT_PATH).to be_a_kind_of String
  end

  describe "#initialize" do
    it 'enables rest-client debugging if instructed to do so' do
      wf = Wavefront::Sources.new(TEST_TOKEN, true)
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
  end


  describe '#delete_tag' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:delete).with(
        concat_url(host, path, 'mysource', 'tags', 'mytag'), wf.headers
      )
      wf.delete_tag('mysource', 'mytag')
    end

    it 'raises an exception on an invalid tag' do
      expect{wf.delete_tag('mysource', '!!!!!!!!')}.
        to raise_exception(Wavefront::Exception::InvalidString)
    end
  end

  describe '#show_sources' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:get).with(
        concat_url(host, path, '?'), wf.headers
      )
      wf.show_sources
    end

    it 'makes API request with options' do
      expect(RestClient).to receive(:get).with(
        concat_url(host, path, '?limit=100&pattern=test-*'), wf.headers
      )
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
end
