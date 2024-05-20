# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

# don't define additional lockfiles unless we're being called as part of a vendored gem
# (i.e. we're not being called from the main Gemfile)
Pathname.include(Comparable)
return unless Bundler.default_gemfile.dirname > Pathname.new(__dir__)

plugin "bundler-multilock", "1.2.3", path: File.expand_path("../vendor/gems/bundler-multilock", __dir__)
raise GemNotFound, "bundler-multilock plugin is not installed" if !is_a?(Bundler::Plugin::DSL) && !Plugin.installed?("bundler-multilock")
return unless Plugin.installed?("bundler-multilock")

Plugin.send(:load_plugin, "bundler-multilock")

require_relative "../config/canvas_rails_switcher" unless defined?($canvas_rails)

canvas_default_lockfile = "../../Gemfile.lock"

current_rails = $canvas_rails
SUPPORTED_RAILS_VERSIONS.each do |rails_version|
  lockfile = "rails#{rails_version.delete(".")}"
  parent = if rails_version == SUPPORTED_RAILS_VERSIONS.first
             lockfile = nil
             canvas_default_lockfile
           else
             "../../Gemfile.#{lockfile}.lock"
           end

  lockfile(lockfile, active: rails_version == current_rails, parent:) do
    $canvas_rails = rails_version
  end
end
