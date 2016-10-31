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

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'wavefront/client'
require 'wavefront/writer'
require 'wavefront/metadata'
require 'wavefront/alerting'
require 'wavefront/events'
require 'wavefront/batch_writer'
require 'wavefront/validators'
require 'wavefront/cli'
require 'wavefront/cli/alerts'
require 'wavefront/cli/events'
require 'wavefront/cli/batch_write'
require 'wavefront/cli/write'
require 'wavefront/cli/sources'

TEST_TOKEN = "test"
TEST_HOST = "metrics.wavefront.com"

# The following RSpec matcher is used to test things which `puts`
# (or related), which RSpec can't do by default. It works with RSpec
# 3, and was lifted wholesale from
# http://stackoverflow.com/questions/6372763/rspec-how-do-i-write-a-test-that-expects-certain-output-but-doesnt-care-about/28258747#28258747

RSpec::Matchers.define :match_stdout do |check|

  @capture = nil

  match do |block|

    begin
      stdout_saved = $stdout
      $stdout      = StringIO.new
      block.call
    ensure
      @capture     = $stdout
      $stdout      = stdout_saved
    end

    @capture.string.match check
  end

  failure_message do
    "expected to #{description}"
  end
  failure_message_when_negated do
    "expected not to #{description}"
  end
  description do
    "match [#{check}] on stdout [#{@capture.string}]"
  end

  def supports_block_expectations?
    true
  end
end

class Mocket
  def puts(str)
    return true
  end
end

def concat_url(*args)
  'https://' + args.join('/').squeeze('/')
end
