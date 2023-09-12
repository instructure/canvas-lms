# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "lib/bundler/multilock"

# this is terrible, but we can't prepend into these modules because we only load
# _inside_ of the CLI commands already running
if defined?(Bundler::CLI::Check)
  require_relative "lib/bundler/multilock/check"
  at_exit do
    next unless $!.nil?
    next if $!.is_a?(SystemExit) && !$!.success?

    next if Bundler::Multilock::Check.run

    Bundler.ui.warn("You can attempt to fix by running `bundle install`")
    exit 1
  end
end
if defined?(Bundler::CLI::Lock)
  at_exit do
    next unless $!.nil?
    next if $!.is_a?(SystemExit) && !$!.success?

    Bundler::Multilock.after_install_all(install: false)
  end
end

Bundler::Plugin.add_hook(Bundler::Plugin::Events::GEM_AFTER_INSTALL_ALL) do |_|
  Bundler::Multilock.after_install_all
end

Bundler::Multilock.inject_preamble unless Bundler::Multilock.loaded?
