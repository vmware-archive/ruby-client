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
require 'socket'

opts = {}

describe Wavefront::BatchWriter do

  describe '#initialize' do
    it 'sets @opts correctly' do
      k = Wavefront::BatchWriter.new({noop: true, proxy: 'myproxy'})
      expect(k.instance_variable_get(:@opts)).to eq({
                                                tags:       false,
                                                proxy:     'myproxy',
                                                port:       2878,
                                                noop:       true,
                                                novalidate: false,
                                                verbose:    false,
                                                debug:      false,
                                              })
    end

    it 'allows unset @global_tags' do
      k = Wavefront::BatchWriter.new
      expect(k.instance_variable_get(:@global_tags)).to be nil
    end

    it 'sets @global_tags' do
      k = Wavefront::BatchWriter.new(tags: { t1: 'v1', t2: 'v2' })
      expect(k.instance_variable_get(:@global_tags)).to eq({t1: 'v1', t2: 'v2'})
    end

  end

  describe '#write' do

    # end-to-end test

    context 'without noop set' do
      it 'should write a single metric to a socket' do

        socket = Mocket.new
        allow(TCPSocket).to receive(:new).and_return(socket)
        expect(socket).to receive(:puts).with(
          'test.metric 1234 1469987572 source=testhost t1="v1" t2="v2"')

        k = Wavefront::BatchWriter.new(opts)
        k.open_socket
        expect(k.write(
          path:   'test.metric',
          value:  1234,
          ts:     Time.at(1469987572),
          source: 'testhost',
          tags:   { t1: 'v1', t2: 'v2' },
        )).to be(true)
        expect(k.summary[:sent]).to eq(1)
        expect(k.summary[:unsent]).to eq(0)
        expect(k.summary[:rejected]).to eq(0)
      end

      it 'should write multiple metrics to a socket' do
        socket = Mocket.new
        allow(TCPSocket).to receive(:new).and_return(socket)
        k = Wavefront::BatchWriter.new
        k.open_socket
        expect(socket).to receive(:puts).with(
          'test.metric_1 1234 1469987572 source=testhost t1="v1" t2="v2"')
        expect(socket).to receive(:puts).with(
          'test.metric_2 2468 1469987572 source=testhost')
        expect(k.write([
          { path:   'test.metric_1',
            value:  1234,
            ts:     Time.at(1469987572),
            source: 'testhost',
            tags:   { t1: 'v1', t2: 'v2' },
          },
          { path:   'test.metric_2',
            value:  2468,
            ts:     Time.at(1469987572),
            source: 'testhost',
          }
        ])).to be(true)
        expect(k.summary[:sent]).to eq(2)
        expect(k.summary[:unsent]).to eq(0)
        expect(k.summary[:rejected]).to eq(0)
      end

      it 'should let good points through and drop bad points' do
        socket = Mocket.new
        allow(TCPSocket).to receive(:new).and_return(socket)
        k = Wavefront::BatchWriter.new(verbose: true)
        k.open_socket
        expect(socket).to receive(:puts).with(
          'test.metric_1 1234 1469987572 source=testhost t1="v1" t2="v2"')
        expect(socket).to receive(:puts).with(
          'test.metric_2 2468 1469987572 source=testhost')
        expect(k.write([
          { path:   'test.metric_1',
            value:  1234,
            ts:     Time.at(1469987572),
            source: 'testhost',
            tags:   { t1: 'v1', t2: 'v2' },
          },
          { path:   'bogus_metric',
          },
          { path:   'test.metric_2',
            value:  2468,
            ts:     Time.at(1469987572),
            source: 'testhost',
          }
        ])).to be(false)
        expect(k.summary[:sent]).to eq(2)
        expect(k.summary[:unsent]).to eq(0)
        expect(k.summary[:rejected]).to eq(1)
      end
    end

    context 'with noop set' do
      it 'should not write a metric to a socket object' do
        m = 'test.metric 1234 1469987572 source=testhost t1="v1" t2="v2"'
        socket = Mocket.new
        allow(TCPSocket).to receive(:new).and_return(socket)
        expect(socket).not_to receive(:puts).with(m)
        k = Wavefront::BatchWriter.new(noop: true)
        k.open_socket
        k.write(
          path:   'test.metric',
          value:  1234,
          ts:     Time.at(1469987572),
          source: 'testhost',
          tags:   { t1: 'v1', t2: 'v2' },
        )
        expect(k.summary[:sent]).to eq(0)
        expect(k.summary[:unsent]).to eq(0)
        expect(k.summary[:rejected]).to eq(0)
      end
    end
  end

  describe '#setup_options' do
    defaults = {
      tags:       false,
      proxy:      'wavefront',
      port:       2878,
      noop:       false,
      novalidate: false,
      verbose:    false,
      debug:      false,
    }

    it 'falls back to all defaults' do
      k = Wavefront::BatchWriter.new
      expect(k.setup_options({}, defaults)).to eq(defaults)
    end

    it 'allows overriding of defaults' do
      k = Wavefront::BatchWriter.new
      expect(k.setup_options({noop: true, proxy: 'myproxy'},
                             defaults)).to eq({ tags:       false,
                                                proxy:      'myproxy',
                                                port:       2878,
                                                noop:       true,
                                                novalidate: false,
                                                verbose:    false,
                                                debug:      false,
                                              })
    end
  end

  describe '#valid_point?' do
    context 'novalidate is true' do
      k = Wavefront::BatchWriter.new({novalidate: true})

      it 'lets through an invalid point' do
        expect(k.valid_point?({junk: true})).to be(true)
      end
    end

    context 'novalidate is false' do
      opts[:novalidate] = false
      k = Wavefront::BatchWriter.new(opts)

      it 'lets through a valid point with all members' do
        expect(k.valid_point?(
          path:   'test.metric',
          value:  123456,
          ts:     Time.now,
          source: 'testhost',
          tags:   { tag1: 'value 1', tag2: 'value 2' },
        )).to be(true)
      end

      it 'lets through a valid point with no timestamp' do
        expect(k.valid_point?(
          path:   'test.metric',
          value:  123456,
          source: 'testhost',
          tags:   { tag1: 'value 1', tag2: 'value 2' },
        )).to be(true)
      end

      it 'lets through a valid point with no tags' do
        expect(k.valid_point?(
          path:   'test.metric',
          value:  123456,
          ts:     Time.now,
          source: 'testhost',
        )).to be(true)
      end

      it 'raises InvalidMetricName on invalid metric name' do
        expect{k.valid_point?(
          path:   '!n\/@1!d_metric',
          value:  123456,
          ts:     Time.now,
          source: 'testhost',
          tags:   { tag1: 'value 1', tag2: 'value 2' },
        )}.to raise_exception(Wavefront::Exception::InvalidMetricName)
      end

      it 'raises InvalidMetricValue on invalid metric value' do
        expect{k.valid_point?(
          path:   'test.metric',
          value:  'three_point_one_four',
          ts:     Time.now,
          source: 'testhost',
          tags:   { tag1: 'value 1', tag2: 'value 2' },
        )}.to raise_exception(Wavefront::Exception::InvalidMetricValue)
      end

      it 'raises InvalidTimestamp on invalid timestamp' do
        expect{k.valid_point?(
          path:   'test.metric',
          value:  123456,
          ts:     'half_past_eleven',
          source: 'testhost',
          tags:   { tag1: 'value 1', tag2: 'value 2' },
        )}.to raise_exception(Wavefront::Exception::InvalidTimestamp)
      end

      it 'raises InvalidHostname on invalid source' do
        expect{k.valid_point?(
          path:   'test.metric',
          value:  123456,
          ts:     Time.now,
          source: ['source1', 'source2'],
          tags:   { tag1: 'value 1', tag2: 'value 2' },
        )}.to raise_exception(Wavefront::Exception::InvalidSource)
      end

      it 'raises InvalidTag on invalid tag' do
        expect{k.valid_point?(
          path:   'test.metric',
          value:  123456,
          ts:     Time.now,
          source: 'testhost',
          tags:   { :tag1 => 'value 1', :'invalid tag' => 'value 2' },
        )}.to raise_exception(Wavefront::Exception::InvalidTag)
      end
    end

  end

  describe '#tag_hash_to_str' do
    k = Wavefront::BatchWriter.new(opts)

    it 'converts multiple tags to a string' do
      expect(k.tag_hash_to_str({tag1: 'value 1', tag2: 'value 2' })).
        to eq('tag1="value 1" tag2="value 2"')
    end

    it 'converts an empty hash to an empty string' do
      expect(k.tag_hash_to_str({})).to eq('')
    end
  end

  describe '#hash_to_wf' do
    context 'when global tags are not defined' do
      k = Wavefront::BatchWriter.new(opts)

      it 'converts a known, full, point hash to a known metric' do
        expect(k.hash_to_wf(
          path:   'test.metric',
          value:  123456,
          ts:     Time.at(1469987572),
          source: 'testhost',
          tags:   { t1: 'v1', t2: 'v2' },
        )).to eq(
          'test.metric 123456 1469987572 source=testhost t1="v1" t2="v2"')
      end

      it 'converts a tag-less point hash to a known metric' do
        expect(k.hash_to_wf(
          path:   'test.metric',
          value:  123456,
          ts:     Time.at(1469987572),
          source: 'testhost',
        )).to eq('test.metric 123456 1469987572 source=testhost')
      end

      it 'converts a timestamp-less point hash to a known metric' do
        expect(k.hash_to_wf(
          path:   'test.metric',
          value:  123456,
          source: 'testhost',
          tags:   { t1: 'v1', t2: 'v2' },
        )).to eq('test.metric 123456 source=testhost t1="v1" t2="v2"')
      end

      it 'raises ArgumentError if vital components are missing' do
        expect{k.hash_to_wf({})}.to raise_exception(ArgumentError)
      end
    end

    context 'when global tags are defined' do
      k = Wavefront::BatchWriter.new(tags: { gtag1: 'gval1', gtag2:
                                             'gval2'})

      it 'converts a known, full, point hash to a known metric' do
        expect(k.hash_to_wf(
          path:   'test.metric',
          value:  123456,
          ts:     Time.at(1469987572),
          source: 'testhost',
          tags:   { t1: 'v1', t2: 'v2' },
        )).to eq(
          'test.metric 123456 1469987572 source=testhost t1="v1" ' +
          't2="v2" gtag1="gval1" gtag2="gval2"')
      end
    end
  end

  describe '#send_point' do
    context 'without noop set' do
      it 'should write a metric to a socket object' do
        m = 'test.metric 1234 1469987572 source=testhost t1="v1" t2="v2"'
        socket = Mocket.new
        allow(TCPSocket).to receive(:new).and_return(socket)
        expect(socket).to receive(:puts).with(m)
        k = Wavefront::BatchWriter.new(opts)
        k.open_socket
        k.send_point(m)
      end
    end

    context 'with noop set' do
      it 'should not write a metric to a socket object' do
        m = 'test.metric 1234 1469987572 source=testhost t1="v1" t2="v2"'
        socket = Mocket.new
        allow(TCPSocket).to receive(:new).and_return(socket)
        expect(socket).not_to receive(:puts).with(m)
        k = Wavefront::BatchWriter.new(noop: true)
        k.open_socket
        k.send_point(m)
        expect{k.send_point(m)}.to match_stdout("Would send: #{m}")
      end
    end
  end

  describe '#open_socket' do

    context 'without noop set' do
      it 'creates a socket object with the default parameters' do
        allow(TCPSocket).to receive(:new)
        expect(TCPSocket).to receive(:new).with('wfp', 2878)
        allow_any_instance_of(Wavefront::BatchWriter).to receive(:new)
        k = Wavefront::BatchWriter.new
        k.instance_variable_set(:@opts, proxy: 'wfp', port: 2878)
        k.open_socket
      end

      it 'raises an exception on an invalid endpoint' do
        allow_any_instance_of(Wavefront::BatchWriter).to receive(:new)
        k = Wavefront::BatchWriter.new
        k.instance_variable_set(:@opts, proxy: 'wfp', port: 2879)
        expect{k.open_socket}.to raise_exception(
          Wavefront::Exception::InvalidEndpoint)
      end
    end

    context 'with noop set' do
      it 'prints a message but does not open a socket' do
        allow_any_instance_of(Wavefront::BatchWriter).to receive(:new)
        k = Wavefront::BatchWriter.new
        k.instance_variable_set(:@opts, proxy: 'wfp', port:
                                2878, noop: true)
        expect(k.open_socket).to be(true)
        expect{k.open_socket}.to match_stdout(
          'No-op requested. Not opening connection to proxy.')
      end
    end
  end

  describe '#close_socket' do
  end
end
