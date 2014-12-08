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
required_bundler_version = '1.6.0'..'1.7.4'
gem 'bundler', [">=#{required_bundler_version.first}", "<=#{required_bundler_version.last}"]

unless required_bundler_version.include?(Bundler::VERSION)
  if Bundler::VERSION < required_bundler_version.first
    bundle_command = "gem install bundler -v #{required_bundler_version.last}"
  else
    require 'shellwords'
    bundle_command = "bundle _#{required_bundler_version.last}_ #{ARGV.map { |a| Shellwords.escape(a) }.join(' ')}"
  end

  warn "Bundler version #{required_bundler_version.first} is required; you're currently running #{Bundler::VERSION}. Maybe try `#{bundle_command}`, or `gem uninstall bundler -v #{Bundler::VERSION}`."
  exit 1
end

# NOTE: this has to use 1.8.7 hash syntax to not raise a parser exception on 1.8.7
if RUBY_VERSION == "2.0.0"
  warn "Ruby 2.0 support is untested"
  ruby '2.0.0', :engine => 'ruby', :engine_version => '2.0.0'
elsif RUBY_VERSION >= "2.1" && RUBY_VERSION < "2.2"
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
elsif RUBY_VERSION >= "2.2"
  warn "Ruby newer than 2.1 is very UNSUPPORTED"
  ruby RUBY_VERSION, :engine => 'ruby', :engine_version => RUBY_VERSION
else
  ruby '1.9.3', :engine => 'ruby', :engine_version => '1.9.3'
end

# force a different lockfile for rails 4
unless CANVAS_RAILS3
  Bundler::SharedHelpers.class_eval do
    class << self
      def default_lockfile
        Pathname.new("#{Bundler.default_gemfile}.lock4")
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

module CanvasBundlerRuntime
  def self.included(klass)
    klass.send(:remove_method, :cache)
  end

  def cache(custom_path = nil)
    cache_path = cache_path(custom_path)
    FileUtils.mkdir_p(cache_path) unless File.exist?(cache_path)

    all_platforms = true # Bundler.config[:all_platforms]
    Bundler.ui.info "Updating files in vendor/cache"
    specs = if all_platforms
              @definition.resolve.map(&:__materialize__)
            else
              self.specs
            end
    specs.each do |spec|
      spec.source.send(:fetch_gem, spec) if all_platforms && spec.source.respond_to?(:fetch_gem, true)
      spec.source.cache(spec, custom_path) if spec.source.respond_to?(:cache)
    end

    Dir[cache_path.join("*/.git")].each do |git_dir|
      FileUtils.rm_rf(git_dir)
      FileUtils.touch(File.expand_path("../.bundlecache", git_dir))
    end

    prune_cache(custom_path) unless Bundler.settings[:no_prune]
  end
end
Bundler::Runtime.send(:include, CanvasBundlerRuntime)

if RUBY_VERSION >= '2.2'
  gem 'syck', '1.0.4'
  gem 'iconv', '1.0.4'
else
  platforms :ruby_20, :ruby_21 do
    gem 'syck', '1.0.4'
    gem 'iconv', '1.0.4'
  end
end
