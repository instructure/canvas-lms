#!/usr/bin/env ruby
# frozen_string_literal: true

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

require "bundler"
require "tempfile"

do_sync = ARGV.include?("--sync")

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
canvas_lockfile_name = Dir.glob(Bundler.default_lockfile.dirname + "Gemfile.rails*.lock*").first

canvas_lockfile_contents = File.read(canvas_lockfile_name)
canvas_specs = Bundler::LockfileParser.new(canvas_lockfile_contents).specs.to_h do |spec| # rubocop:disable Rails/IndexBy
  [[spec.name, spec.platform], spec]
end
canvas_root = File.dirname(canvas_lockfile_name)

success = true
Bundler.settings.temporary(cache_all_platforms: true) do
  previous_ui_level = Bundler.ui.level
  Bundler.ui.level = "silent"

  Dir["Gemfile.d/*.lock", "gems/*/Gemfile.lock"].each do |gem_lockfile_name|
    if do_sync
      gem_gemfile_name = gem_lockfile_name.sub(/\.lock$/, "")
      # root needs to be set so that paths are output relative to the correct root in the lockfile
      Bundler.instance_variable_set(:@root, Pathname.new(gem_lockfile_name).dirname.expand_path)

      # adjust locked paths from the Canvas lockfile to be relative to _this_ gemfile
      new_contents = canvas_lockfile_contents.gsub(/PATH\n  remote: ([^\n]+)\n/) do |remote|
        remote_path = Pathname.new($1)
        next remote if remote_path.absolute?

        relative_remote_path = remote_path.expand_path(canvas_root).relative_path_from(Bundler.root).to_s
        remote.sub($1, relative_remote_path)
      end

      # add a source for the current gem
      gem_spec = canvas_specs[[File.basename(Bundler.root), "ruby"]]

      if gem_spec
        new_contents += <<~TEXT
          PATH
            remote: .
            specs:
          #{gem_spec.to_lock}
        TEXT
      end

      definition = nil

      puts "Syncing #{gem_gemfile_name}..."
      # Now build a definition based on the gem's Gemfile, but *Canvas* (tweaked) lockfile
      Tempfile.create do |temp_lockfile|
        temp_lockfile.write(new_contents)

        definition = Bundler::Definition.build(gem_gemfile_name, temp_lockfile.path, false)
      end

      changed = !definition.send(:lockfiles_equal?, File.read(gem_lockfile_name), definition.to_lock, true)
      success = false if changed

      if changed
        definition.lock(gem_lockfile_name, true)
      end
    end

    # now do a double check for conflicting requirements
    Bundler::LockfileParser.new(File.read(gem_lockfile_name)).specs.each do |spec|
      next unless (canvas_spec = canvas_specs[[spec.name, spec.platform]])

      platform = (spec.platform == "ruby") ? "" : "-#{spec.platform}"

      next if canvas_spec.version == spec.version

      warn "#{spec.name}#{platform}@#{spec.version} in #{gem_lockfile_name} does not match Canvas (@#{canvas_spec.version}); this is may be due to a conflicting requirement, which would require manual resolution."
      success = false
    end
  end
ensure
  Bundler.ui.level = previous_ui_level
end

if !success && !do_sync
  warn "\nYou can attempt to fix by running script/sync_lockfiles.rb --sync"
end

exit(success ? 0 : 1)
