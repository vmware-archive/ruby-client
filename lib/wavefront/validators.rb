module Wavefront
  #
  # A module of mixins to validate input. The Wavefront documentation
  # lays down restrictions on types and sizes of various inputs, which
  # we will check on the user's behalf. Most of the information used in
  # this file comes from https://community.wavefront.com/docs/DOC-1031
  # some comes from the Swagger API documentation.
  #
  module Validators
    def valid_source?(source)
      #
      # Check a source, according to
      #
      unless source.is_a?(String) && source.match(/^[a-z0-9\-_\.]+$/) &&
             source.length < 1024
        fail Wavefront::Exception::InvalidSource
      end
      true
    end

    def valid_string?(string)
      #
      # Only allows PCRE "word" characters, spaces, full-stops and
      # commas in tags and descriptions. This might be too restrictive,
      # but if it is, this is the only place we need to change it.
      #
      string.match(/^[\-\w \.,]*$/)
    end

    def valid_path?(path)
      fail Wavefront::Exception::InvalidMetricName unless \
        path.is_a?(String) && path.match(/^[a-z0-9\-_\.]+$/) &&
        path.length < 1024
      true
    end

    def valid_value?(value)
      fail Wavefront::Exception::InvalidMetricValue unless value.is_a?(Numeric)
      true
    end

    def valid_ts?(ts)
      unless ts.is_a?(Time) || ts.is_a?(Date)
        fail Wavefront::Exception::InvalidTimestamp
      end
      true
    end

    def valid_tags?(tags)
      #
      # Operates on a hash of key-value point tags. These are
      # different from source tags.
      #
      tags.each do |k, v|
        fail Wavefront::Exception::InvalidTag unless (k.length +
             v.length < 254) && k.match(/^[a-z0-9\-_\.]+$/)
      end
      true
    end
  end
end
