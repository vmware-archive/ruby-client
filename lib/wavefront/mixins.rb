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

module Wavefront
  module Mixins
    def interpolate_schema(label, host, prefix_length)
      label_parts = label.split('.')
      interpolated = Array.new
      interpolated << label_parts.shift(prefix_length)
      interpolated << host
      interpolated << label_parts
      interpolated.flatten!
      return interpolated.join('.')
    end

    def parse_time(t)
      #
      # Return a time as an integer, however it might come in.
      #
      begin
        return t if t.is_a?(Integer)
        return t.to_i if t.is_a?(Time)
        return t.to_i if t.is_a?(String) && t.match(/^\d+$/)
        return DateTime.parse("#{t} #{Time.now.getlocal.zone}").
          to_time.utc.to_i
      rescue
        raise "cannot parse timestamp '#{t}'."
      end
    end

    def time_to_ms(t)
      #
      # Return the time as milliseconds since the epoch
      #
      return false unless t.is_a?(Integer)
      (t.to_f * 1000).round
    end

    def hash_to_qs(payload)
      #
      # Make a properly escaped query string out of a key: value
      # hash.
      #
      URI.escape(payload.map { |k, v| [k, v].join('=') }.join('&'))
    end

    def uri_concat(*args)
      args.join('/').squeeze('/')
    end

    def valid_source?(path)
      unless path.is_a?(String) && path.match(/^[a-z0-9\-_\.]+$/) &&
             path.length < 1024
        fail Wavefront::Exception::InvalidSource
      end
      true
    end
  end
end
