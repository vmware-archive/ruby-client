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
  end
end
