#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
#

# NOTE: this has to use 1.8.7 hash syntax to not raise a parser exception on 1.8.7
if RUBY_VERSION == "2.0.0"
  warn "Ruby 2.0 support is untested"
  ruby '2.0.0', :engine => 'ruby', :engine_version => '2.0.0'
elsif RUBY_VERSION == "2.1.0"
  warn "Ruby 2.1 support is untested"
  ruby '2.1.0', :engine => 'ruby', :engine_version => '2.1.0'
else
  ruby '1.9.3', :engine => 'ruby', :engine_version => '1.9.3'
end

# # enforce the version of bundler itself, to avoid any surprises
required_bundler_version = '1.5.1'..'1.5.3'
gem 'bundler', [">=#{required_bundler_version.first}", "<=#{required_bundler_version.last}"]

unless required_bundler_version.include?(Bundler::VERSION)
  if Bundler::VERSION < required_bundler_version.first
    bundle_command = "gem install bundler -v #{required_bundler_version.last}"
  else
    require 'shellwords'
    bundle_command = "bundle _#{required_bundler_version.last}_ #{ARGV.map { |a| Shellwords.escape(a) }.join(' ')}"
  end

  warn "Bundler version #{required_bundler_version.first} is required; you're currently running #{Bundler::VERSION}. Maybe try `#{bundle_command}`."
  exit 1
end

# force a different lockfile for rails 3
if CANVAS_RAILS3
  Bundler::SharedHelpers.class_eval do
    class << self
      def default_lockfile
        Pathname.new("#{Bundler.default_gemfile}.lock3")
      end
    end
  end

  Bundler::Dsl.class_eval do
    def to_definition(lockfile, unlock)
      @sources << @rubygems_source unless @sources.include?(@rubygems_source)
      Definition.new(Bundler.default_lockfile, @dependencies, @sources, unlock, @ruby_version)
    end
  end
end

# patch bundler to do github over https
unless Bundler::Dsl.private_instance_methods.include?(:_old_normalize_options)
  class Bundler::Dsl
    alias_method :_old_normalize_options, :_normalize_options
    def _normalize_options(name, version, opts)
      _old_normalize_options(name, version, opts)
      opts['git'].sub!('git://', 'https://') if opts['git'] && opts['git'] =~ %r{^git://github.com}
    end
  end
end

platforms :ruby_20, :ruby_21 do
  gem 'syck', '1.0.1'
  gem 'iconv', '1.0.3'
end
