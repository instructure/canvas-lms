#
# Copyright (C) 2014 - present Instructure, Inc.
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

gem 'bundler', '>= 1.13.3', '<= 1.17.2'

if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new('1.14.0') &&
  Gem::Version.new(Gem::VERSION) < Gem::Version.new('2.6.9')
  raise "Please run `gem update --system` to bring RubyGems to 2.6.9 or newer for use with Bundler 1.14 or newer."
end

# NOTE: this has to use 1.8.7 hash syntax to not raise a parser exception on 1.8.7
if RUBY_VERSION >= "2.4.0" && RUBY_VERSION < "2.6"
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
elsif RUBY_VERSION >= "2.6.0" && RUBY_VERSION < "2.7"
  $stderr.puts "Ruby 2.6 support is untested" unless ENV['SUPPRESS_RUBY_WARNING']
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
else
  ruby '2.4.0', :engine => 'ruby', :engine_version => '2.4.0'
end

# force a different lockfile for rails 5.2
unless CANVAS_RAILS5_1
  Bundler::SharedHelpers.class_eval do
    class << self
      def default_lockfile
        lockfile = "#{Bundler.default_gemfile}.lock"
        lockfile << ".52" unless CANVAS_RAILS5_1
        Pathname.new(lockfile)
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

