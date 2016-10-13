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

require "wavefront/client/version"

module Wavefront
  class Exception
    class InvalidTimeFormat < ::Exception; end
    class InvalidGranularity < ::Exception; end
    class InvaldResponseFormat < ::Exception; end
    class EmptyMetricName < ::Exception; end
    class NotImplemented < ::Exception; end
    class InvalidPrefixLength < ::Exception; end
    class InvalidMetricName < ::Exception; end
    class InvalidMetricValue < ::Exception; end
    class InvalidTimestamp < ::Exception; end
    class InvalidTag < ::Exception; end
    class InvalidHostname < ::Exception; end
    class InvalidEndpoint < ::Exception; end
    class InvalidSource < ::Exception; end
    class InvalidString < ::Exception; end
    class ValueOutOfRange < ::Exception; end
  end
end
