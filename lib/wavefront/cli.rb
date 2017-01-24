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

require 'wavefront/constants'

module Wavefront
  #
  # Parent of all the CLI classes.
  #
  class Cli
    attr_accessor :options, :arguments, :noop

    def initialize(options, arguments)
      @options   = options
      @arguments = arguments
      @noop = options[:noop]

      if options.include?(:help) && options[:help]
        puts options
        exit 0
      end
    end

    def validate_opts
      #
      # There are things we need to have. If we don't have them,
      # stop the user right now. Also, if we're in debug mode, print
      # out a hash of options, which can be very useful when doing
      # actual debugging. Some classes may have to override this
      # method. The writer, for instance, uses a proxy and has no
      # token.
      #
      raise 'Please supply an API token.' unless options[:token]
      raise 'Please supply an API endpoint.' unless options[:endpoint]
    end
  end
end
