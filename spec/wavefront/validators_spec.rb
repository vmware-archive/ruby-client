require_relative '../spec_helper'

describe Wavefront::Validators do
  include Wavefront::Validators

  describe '#valid_path?' do
    it 'accepts a-z, 0-9, _ and -' do
      expect(valid_path?('a.l33t.metric_path-passes')).to be(true)
    end

    it 'accepts nearly very long paths' do
      expect(valid_path?('a' * 1023)).to be(true)
    end

    it 'rejects very long paths' do
      expect{valid_path?('a' * 1024)}.to raise_exception(
        Wavefront::Exception::InvalidMetricName)
    end

    it 'rejects upper-case letters' do
      expect{valid_path?('NO.NEED.TO.SHOUT')}.to raise_exception(
        Wavefront::Exception::InvalidMetricName)
    end

    it 'rejects odd characters' do
      expect{valid_path?('metric.is.(>_<)')}.to raise_exception(
        Wavefront::Exception::InvalidMetricName)
    end
  end

  describe '#valid_value?' do
    it 'accepts integers' do
      expect(valid_value?(123456)).to be(true)
    end

    it 'accepts 0' do
      expect(valid_value?(0)).to be(true)
    end

    it 'accepts negative integers' do
      expect(valid_value?(-10)).to be(true)
    end

    it 'accepts decimals' do
      expect(valid_value?(1.2345678)).to be(true)
    end

    it 'accepts exponential notation' do
      expect(valid_value?(1.23e04)).to be(true)
    end

    it 'rejects strings which look like numbers' do
      expect { valid_value?('1.23')}.to raise_exception(
        Wavefront::Exception::InvalidMetricValue)
    end
  end

  describe '#valid_ts?' do
    it 'rejects integers' do
      expect { valid_ts?(Time.now.to_i) }.to raise_exception(
        Wavefront::Exception::InvalidTimestamp)
    end

    it 'accepts Times' do
      expect(valid_ts?(Time.now)).to be(true)
    end

    it 'accepts DateTimes' do
      expect(valid_ts?(DateTime.now)).to be(true)
    end

    it 'accepts Dates' do
      expect(valid_ts?(Date.today)).to be(true)
    end
  end

  describe '#valid_tags?' do
    it 'accepts zero tags' do
      expect(valid_tags?({})).to be(true)
    end

    it 'accepts nice sensible tags' do
      expect(valid_tags?({tag1: 'val1', tag2: 'val2'})).to be(true)
    end

    it 'accepts spaces and symbols in values' do
      expect(valid_tags?({tag1: 'val 1', tag2: 'val 2'})).to be(true)
      expect(valid_tags?({tag1: '(>_<)', tag2: '^_^'})).to be(true)
    end

    it 'rejects spaces and symbols in keys' do
      expect { valid_tags?({'tag 1' => 'val1',
                              'tag 2' => 'val2'}) }.to raise_exception(
        Wavefront::Exception::InvalidTag)
      expect { valid_tags?({'(>_<)' => 'val1',
                              '^_^'   => 'val2'}) }.to raise_exception(
        Wavefront::Exception::InvalidTag)
    end

    it 'rejects long keys and/or values' do
      expect { valid_tags?({tag1: 'v' * 255}) }.to raise_exception(
        Wavefront::Exception::InvalidTag)
      expect { valid_tags?({'k' * 255 => 'val1'}) }.to raise_exception(
        Wavefront::Exception::InvalidTag)
      expect { valid_tags?({'k' * 130 => 'v' * 130}) }.to raise_exception(
        Wavefront::Exception::InvalidTag)
    end
  end
end
