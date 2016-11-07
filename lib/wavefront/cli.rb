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
    end

    def load_profile
      #
      # Load in configuration options from the (optionally) given
      # section of an ini-style configuration file. If the file's
      # not there, we don't consider that an error: it's not
      # entirely reasonable to demand the user has one. Options
      # passed on the command-line trump the same values in the
      # file.
      #
      return unless options[:config].is_a?(String)
      cf = Pathname.new(options[:config])
      return unless cf.exist?

      pf = options[:profile] || 'default'
      raw = IniFile.load(cf)
      profile = raw[pf]

      puts "using #{pf} profile from #{cf}" if options[:debug]

      profile.each_with_object({}) do |(k, v), memo|
        k = k.to_sym
        memo[k] = (options.include?(k) && options[k]) ? options[k] : v
      end
    end
  end
end
