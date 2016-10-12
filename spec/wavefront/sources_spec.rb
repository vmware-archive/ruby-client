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
  end
end
