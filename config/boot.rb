#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

if ENV['RAILS_ENV'] != 'production'
  module BootLib
    module Require
      ARCHDIR    = RbConfig::CONFIG['archdir']
      RUBYLIBDIR = RbConfig::CONFIG['rubylibdir']
      DLEXT      = RbConfig::CONFIG['DLEXT']

      def self.from_archdir(feature)
        require(File.join(ARCHDIR, "#{feature}.#{DLEXT}"))
      end

      def self.from_rubylibdir(feature)
        require(File.join(RUBYLIBDIR, "#{feature}.rb"))
      end

      def self.from_gem(gem, feature)
        match = $LOAD_PATH
          .select { |e| e.match(gem_pattern(gem)) }
          .map    { |e| File.join(e, feature) }
          .detect { |e| File.exist?(e) }
        if match
          require(match)
        else
          puts "[BootLib::Require warning] couldn't locate #{feature}"
          require(feature)
        end
      end

      def self.gem_pattern(gem)
        %r{
          /
          (gems|extensions/[^/]+/[^/]+)          # "gems" or "extensions/x64_64-darwin16/2.3.0"
          /
          #{Regexp.escape(gem)}-(\h{12}|(\d+\.)) # msgpack-1.2.3 or msgpack-1234567890ab
        }x
      end
    end
  end

  # compilation cache only works on macOS right now
  on_mac = (/darwin/ =~ RUBY_PLATFORM) != nil

  BootLib::Require.from_gem('bootsnap', 'bootsnap')
  Bootsnap.setup(
    cache_dir:            'tmp/cache',
    development_mode:     true,
    load_path_cache:      true,
    autoload_paths_cache: true,
    disable_trace:        false,
    compile_cache_iseq:   on_mac,
    compile_cache_yaml:   on_mac
  )
end
