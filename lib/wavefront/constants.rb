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

require 'pathname'

module Wavefront
  module Constants
    DEFAULT_HOST = 'metrics.wavefront.com'
    DEFAULT_PERIOD_SECONDS = 600
    DEFAULT_FORMAT = :raw
    DEFAULT_PREFIX_LENGTH = 1
    DEFAULT_STRICT = true
    DEFAULT_OBSOLETE_METRICS = false
    FORMATS = [ :raw, :ruby, :graphite, :highcharts, :human ]
    ALERT_FORMATS = [:ruby, :json, :human]
    DEFAULT_ALERT_FORMAT = :human
    GRANULARITIES = %w( s m h d )
    EVENT_STATE_DIR = Pathname.new('/var/tmp/wavefront/events')
    EVENT_LEVELS = %w(info smoke warn severe)
    DEFAULT_PROXY = 'wavefront'
    DEFAULT_PROXY_PORT = 2878
  end
end
