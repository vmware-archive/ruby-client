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

describe Wavefront::Alerting do
  before do
    @wave = Wavefront::Alerting.new(TEST_TOKEN)
  end

  it 'has some defaults' do
    expect(Wavefront::Alerting::DEFAULT_HOST).to_not be_nil
    expect(Wavefront::Alerting::DEFAULT_HOST).to be_a_kind_of String
    expect(Wavefront::Alerting::DEFAULT_PATH).to_not be_nil
    expect(Wavefront::Alerting::DEFAULT_PATH).to be_a_kind_of String
  end


  describe "#initialize" do
    it 'accepts a token option initialized and exposes token for reading' do
      wave = Wavefront::Alerting.new(TEST_TOKEN)
      expect(wave.token).to eq TEST_TOKEN
    end

    it 'enables rest-client debugging if instructed to do so' do
      wave = Wavefront::Alerting.new(TEST_TOKEN, true)
      expect RestClient.log == 'stdout'
    end
  end

  describe '#get_alerts' do
    it 'makes API request with default options' do
      expect(RestClient).to receive(:get).with("https://#{File.join(Wavefront::Alerting::DEFAULT_HOST, Wavefront::Alerting::DEFAULT_PATH, "all?t=#{TEST_TOKEN}")}")
      @wave.get_alerts('all')
    end

    it 'makes API request with specified host' do
      host = 'madeup.wavefront.com'
      expect(RestClient).to receive(:get).with("https://#{File.join(host, Wavefront::Alerting::DEFAULT_PATH, "all?t=#{TEST_TOKEN}")}")
      @wave.get_alerts('all', { :host => host } )
    end

    it 'makes API request with specified path' do
      path = '/api/new_alerts' 
      expect(RestClient).to receive(:get).with("https://#{File.join(Wavefront::Alerting::DEFAULT_HOST, path, "all?t=#{TEST_TOKEN}")}")
      @wave.get_alerts('all', { :path => path })
    end

    it 'makes API request with appended shared tags' do
      tags = [ 'first', 'second' ]
      expect(RestClient).to receive(:get).with("https://#{File.join(Wavefront::Alerting::DEFAULT_HOST, Wavefront::Alerting::DEFAULT_PATH, "all?t=#{TEST_TOKEN}&customerTag=first&customerTag=second")}")
      @wave.get_alerts('all', { :shared_tags => tags })
    end

    it 'makes API request with appended private tags' do
      tags = [ 'first', 'second' ]
      expect(RestClient).to receive(:get).with("https://#{File.join(Wavefront::Alerting::DEFAULT_HOST, Wavefront::Alerting::DEFAULT_PATH, "all?t=#{TEST_TOKEN}&userTag=first&userTag=second")}")
      @wave.get_alerts('all', { :private_tags => tags })
    end

    it 'makes API request with both appended private tags and shared tags' do
      private_tag = 'first' 
      shared_tag = 'second'
      expect(RestClient).to receive(:get).with("https://#{File.join(Wavefront::Alerting::DEFAULT_HOST, Wavefront::Alerting::DEFAULT_PATH, "all?t=#{TEST_TOKEN}&customerTag=second&userTag=first")}")
      @wave.get_alerts('all', { :private_tags => private_tag, :shared_tags => shared_tag })
    end
  end

  describe '#active' do
    it 'requests all active alerts' do
      expect(@wave).to receive(:get_alerts).with("active", {}) 
      @wave.active
    end
  end

  describe '#snoozed' do
    it 'requests all snoozed alerts' do
      expect(@wave).to receive(:get_alerts).with("snoozed", {}) 
      @wave.snoozed
    end
  end

  describe '#invalid' do
    it 'requests all invalid alerts' do
      expect(@wave).to receive(:get_alerts).with("invalid", {}) 
      @wave.invalid
    end
  end

  describe '#affected_by_maintenance' do
    it 'requests all affected_by_maintenance alerts' do
      expect(@wave).to receive(:get_alerts).with("affected_by_maintenance", {}) 
      @wave.affected_by_maintenance
    end
  end
  
end
