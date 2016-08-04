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

# # enforce the version of bundler itself, to avoid any surprises
req_bundler_version_floor, req_bundler_version_ceiling = '1.10.1', '1.12.5'
bundler_requirements = [">=#{req_bundler_version_floor}",
                        "<=#{req_bundler_version_ceiling}"]
gem 'bundler', bundler_requirements

# we still manually do this check because older bundler versions don't validate the version requirement
# of the bundler gem once the bundle has been initially installed
unless Gem::Requirement.new(*bundler_requirements).satisfied_by?(Gem::Version.new(Bundler::VERSION))
  if Gem::Version.new(Bundler::VERSION) < Gem::Version.new(req_bundler_version_floor)
    bundle_command = "gem install bundler -v #{req_bundler_version_ceiling}"
  else
    require 'shellwords'
    bundle_command = "bundle _#{req_bundler_version_ceiling}_ " +
                     "#{ARGV.map { |a| Shellwords.escape(a) }.join(' ')}"
  end

  warn "Bundler version #{req_bundler_version_floor} is required; " +
       "you're currently running #{Bundler::VERSION}. " +
       "Maybe try `#{bundle_command}`, or " +
       "`gem uninstall bundler -v #{Bundler::VERSION}`."
  exit 1
end

# NOTE: this has to use 1.8.7 hash syntax to not raise a parser exception on 1.8.7
if RUBY_VERSION >= "2.1" && RUBY_VERSION < "2.2"
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
elsif RUBY_VERSION >= "2.2" && RUBY_VERSION < "2.3"
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
elsif RUBY_VERSION >= "2.3.1" && RUBY_VERSION < "2.4"
  puts "Ruby 2.3 support is untested"
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
else
  ruby '2.1.6', :engine => 'ruby', :engine_version => '2.1.6'
end

# force a different lockfile for rails 4.2
unless CANVAS_RAILS4_0
  Bundler::SharedHelpers.class_eval do
    class << self
      def default_lockfile
        Pathname.new("#{Bundler.default_gemfile}.lock4_2")
      end
    end
  end

  Bundler::Dsl.class_eval do
    def to_definition(lockfile, unlock)
      @sources << @rubygems_source if @sources.respond_to?(:include?) && !@sources.include?(@rubygems_source)
      Definition.new(Bundler.default_lockfile, @dependencies, @sources, unlock, @ruby_version)
    end
  end
end

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'syck', '1.0.4'
gem 'iconv', '1.0.4'
