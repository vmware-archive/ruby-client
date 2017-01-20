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

require 'inifile'

module Wavefront
  class Cli

    attr_accessor :options, :arguments

    def initialize(options, arguments)
      @options   = options
      @arguments = arguments

      if options.include?(:help) && options[:help]
        puts options
        exit 0
      end

      # Don't validate options on this class. When it's
      # instantiated, the CLI and config file options haven't been
      # merged.

      validate_opts unless self.class.name == 'Wavefront::Cli'
    end

    def load_profile
      #
      # Load in configuration options from the (optionally) given
      # section of an ini-style configuration file. If the file's
      # not there, we don't consider that an error.
      #
      return unless options[:config].is_a?(String)
      cf = Pathname.new(options[:config])
      return unless cf.exist?

      pf = options[:profile] || 'default'
      puts "using '#{pf}' profile from '#{cf}'" if options[:debug]

      IniFile.load(cf)[pf].each_with_object({}) do |(k, v), memo|
        memo[k.to_sym] = v
      end
    end

    def validate_opts
      #
      # There are things we need to have. If we don't have them,
      # stop the user right now. Also, if we're in debug mode, print
      # out a hash of options, which can be very useful when doing
      # actual debugging.
      #
      pp @options if options[:debug]

      abort 'Please supply an API token.' unless options[:token]
      abort 'Please supply an API endpoint.' unless options[:endpoint]
    end
  end
end
