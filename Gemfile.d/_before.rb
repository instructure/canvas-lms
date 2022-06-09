# frozen_string_literal: true

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

gem "bundler", "~> 2.2"

if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new("1.14.0") &&
   Gem::Version.new(Gem::VERSION) < Gem::Version.new("2.6.9")
  raise "Please run `gem update --system` to bring RubyGems to 2.6.9 or newer for use with Bundler 1.14 or newer."
end

if RUBY_ENGINE == "truffleruby"
  warn "TruffleRuby support is experimental" unless ENV["SUPPRESS_RUBY_WARNING"]
elsif RUBY_VERSION >= "3.0.0" && RUBY_VERSION < "3.1"
  warn "Ruby 3.0+ support is experimental" unless ENV["SUPPRESS_RUBY_WARNING"]
end
ruby ">= 2.7.0", "< 3.1"

# Add the version number to the Gemfile.lock as Gemfile.<version>.lock
Bundler::SharedHelpers.class_eval do
  class << self
    def default_lockfile
      lockfile = "#{Bundler.default_gemfile}.rails#{CANVAS_RAILS.delete(".")}.lock"
      Pathname.new(lockfile)
    end
  end
end

Bundler::Dsl.class_eval do
  def to_definition(_lockfile, unlock)
    @sources << @rubygems_source if @sources.respond_to?(:include?) && !@sources.include?(@rubygems_source)
    Definition.new(Bundler.default_lockfile, @dependencies, @sources, unlock, @ruby_version)
  end
end
