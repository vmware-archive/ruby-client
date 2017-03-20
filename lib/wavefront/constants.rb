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
require 'socket'

module Wavefront
  module Constants
    DEFAULT_HOST = 'metrics.wavefront.com'
    DEFAULT_PERIOD_SECONDS = 600
    DEFAULT_FORMAT = :raw
    DEFAULT_PREFIX_LENGTH = 1
    DEFAULT_STRICT = true
    DEFAULT_OBSOLETE_METRICS = false
    FORMATS = [ :raw, :ruby, :graphite, :highcharts, :human ]
    ALERT_FORMATS = [:ruby, :json, :human, :yaml]
    SOURCE_FORMATS = [:ruby, :json, :human]
    DASH_FORMATS = [:json, :human, :yaml]
    DEFAULT_ALERT_FORMAT = :human
    DEFAULT_SOURCE_FORMAT = :human
    DEFAULT_DASH_FORMAT = :human
    GRANULARITIES = %w( s m h d )
    EVENT_STATE_DIR = Pathname.new('/var/tmp/wavefront/events')
    EVENT_LEVELS = %w(info smoke warn severe)
    DEFAULT_PROXY = 'wavefront'
    DEFAULT_PROXY_PORT = 2878
    DEFAULT_INFILE_FORMAT = 'tmv'

    # The CLI will use these options if they are not supplied on the
    # command line or in a config file
    #
    DEFAULT_OPTS = {
      endpoint:     DEFAULT_HOST,          # API endpoint
      proxy:        'wavefront',           # proxy endpoint
      port:         DEFAULT_PROXY_PORT,    # proxy port
      profile:      'default',             # stanza in config file
      host:         Socket.gethostname,    # source host
      prefixlength: DEFAULT_PREFIX_LENGTH, # no of prefix path elements
      strict:       DEFAULT_STRICT,        # points outside query window
      format:       DEFAULT_FORMAT,        # ts output format
      alertformat:  DEFAULT_ALERT_FORMAT,  # alert command output format
      infileformat: DEFAULT_INFILE_FORMAT, # batch writer file format
      sourceformat: DEFAULT_SOURCE_FORMAT, # source output format
      dashformat:   DEFAULT_DASH_FORMAT,   # dashboard output format
    }.freeze
  end
end
