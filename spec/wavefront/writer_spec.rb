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
require 'socket'

describe Wavefront::Writer do

  it 'has some defaults' do
    expect(Wavefront::Writer::DEFAULT_HOST).to_not be_nil
    expect(Wavefront::Writer::DEFAULT_HOST).to be_a_kind_of String
    expect(Wavefront::Writer::DEFAULT_PORT).to_not be_nil
    expect(Wavefront::Writer::DEFAULT_PORT).to be_a_kind_of Fixnum
    expect(Wavefront::Writer::DEFAULT_HOSTNAME).to_not be_nil
    expect(Wavefront::Writer::DEFAULT_HOSTNAME).to be_a_kind_of String
  end


  describe "#initialize" do
    it 'creates a socket object with the default parameters' do
      allow(TCPSocket).to receive(:new)
      expect(TCPSocket).to receive(:new).with('localhost', Wavefront::Writer::DEFAULT_PORT)
      writer = Wavefront::Writer.new
    end

    it 'creates a socket object with parameters if specified' do
      host = 'somehost'
      port = '8566'
      allow(TCPSocket).to receive(:new)
      expect(TCPSocket).to receive(:new).with(host, port)
      writer = Wavefront::Writer.new({:agent_host => host, :agent_port => port})
    end
  end

  describe "#write" do
    it 'should write a metric to a socket object' do
      host = 'somehost'
      port = '8566'
      delay = 0
      socket = Mocket.new
      allow(TCPSocket).to receive(:new).and_return(socket)
      allow(Time).to receive(:now).and_return(123456789)
      expect(socket).to receive(:puts).with("metric 50 123456789 host=somehost")
      writer = Wavefront::Writer.new
      writer.write(50, "metric", {host_name: host, timestamp: 123456789})
    end

    it 'should accept a single tag and append it correctly' do
      host = 'somehost'
      port = '8566'
      tags = {'tag_key_one' => 'tag_val_one'}
      socket = Mocket.new
      allow(TCPSocket).to receive(:new).and_return(socket)
      allow(Time).to receive(:now).and_return(123456789)
      expect(socket).to receive(:puts).with("metric 50 123456789 host=somehost tag_key_one=\"tag_val_one\"")
      writer = Wavefront::Writer.new
      writer.write(50, "metric",
                   {host_name: host, point_tags: tags, timestamp: 123456789})
    end

   it 'should accept multiple tags and append them correctly' do
      host = 'somehost'
      port = '8566'
      tags = {'tag_key_one' => 'tag_val_one', 'k2' => 'v2'}
      socket = Mocket.new
      allow(TCPSocket).to receive(:new).and_return(socket)
      allow(Time).to receive(:now).and_return(123456789)
      expect(socket).to receive(:puts).with("metric 50 123456789 host=somehost tag_key_one=\"tag_val_one\" k2=\"v2\"")
      writer = Wavefront::Writer.new
      writer.write(50, "metric",
                   {host_name: host, point_tags: tags, timestamp: 123456789})

   end
  end
end
