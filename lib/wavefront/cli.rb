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

      if @options[:help]
        puts @options
        exit 0
      end
    end

    def load_profile
      cf = Pathname.new(options[:config])
      pf = options[:profile]

      if cf.exist?
        raw = IniFile.load(cf)
        profile = raw[pf]

        unless profile.empty?
          puts "using #{pf} profile from #{cf}" if options[:debug]
          return profile.inject({}){|x, (k, v)| x[k.to_sym] = v; x }
        end

      else
        puts "no config file at '#{cf}': using options" if options[:debug]
      end
    end

  end
end
