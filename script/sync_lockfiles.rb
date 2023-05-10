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

sync = ARGV.include?("--sync")

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
lockfile_name = Dir.glob(Bundler.default_lockfile.dirname + "Gemfile.rails*.lock*").first

default_specs = Bundler::LockfileParser.new(File.read(lockfile_name)).specs.to_h do |spec| # rubocop:disable Rails/IndexBy
  [[spec.name, spec.platform], spec]
end

success = true
Dir["gems/*/Gemfile.lock"].each do |lockfile|
  lockfile_contents = File.read(lockfile)
  new_lockfile = lockfile_contents.dup
  updates = []
  Bundler::LockfileParser.new(lockfile_contents).specs.each do |spec|
    next unless (default_spec = default_specs[[spec.name, spec.platform]])

    platform = (spec.platform == "ruby") ? "" : "-#{spec.platform}"

    next if default_spec.version == spec.version

    if sync
      updates << [spec, platform, default_spec.version]
      new_lockfile.gsub!("#{spec.name} (#{spec.version}#{platform})", "#{spec.name} (#{default_spec.version}#{platform})")
    else
      warn "#{spec.name}#{platform}@#{spec.version} in #{lockfile} does not match Canvas #{default_spec.version}"
      success = false
    end
  end

  next if !sync || lockfile_contents == new_lockfile

  Dir.chdir(File.dirname(lockfile)) do
    Bundler.with_unbundled_env do
      updates = updates.map { |spec, platform, new_version| "  #{spec.name}#{platform} from #{spec.version} to #{new_version}" }
      puts "Updating #{lockfile}:\n#{updates.join("\n")}"

      # first make sure all referenced gems are installed
      `bundle check 2> /dev/null || bundle install 2> /dev/null`

      File.write("Gemfile.lock", new_lockfile)

      # now see if we screwed it up
      result = `bundle check`
      unless $?.success?
        warn result
        success = false

        # revert to its original state
        File.write("Gemfile.lock", new_lockfile)
      end
    end
  end
end

if !success && !sync
  warn "\nYou can attempt to fix by running script/sync_lockfiles.rb --sync"
end

exit(success ? 0 : 1)
