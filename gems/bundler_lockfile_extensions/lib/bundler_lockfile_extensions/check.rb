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

require "set"

module BundlerLockfileExtensions
  class Check
    class << self
      def run # rubocop:disable Rails/Delegate
        new.run
      end
    end

    def initialize
      default_lockfile_contents = ::Bundler.default_lockfile.read
      @default_lockfile = ::Bundler::LockfileParser.new(default_lockfile_contents)
      @default_specs = @default_lockfile.specs.to_h do |spec| # rubocop:disable Rails/IndexBy
        [[spec.name, spec.platform], spec]
      end
    end

    def run
      return true unless ::Bundler.default_lockfile.exist?

      success = true
      BundlerLockfileExtensions.lockfile_definitions.each do |lockfile_definition|
        next unless lockfile_definition[:lockfile].exist?

        success = false unless check(lockfile_definition)
      end
      success
    end

    # this is mostly equivalent to the built in checks in `bundle check`, but even
    # more conservative, and returns false instead of exiting on failure
    def base_check(lockfile_definition)
      return false unless lockfile_definition[:lockfile].file?

      lockfile_definition[:prepare]&.call
      definition = ::Bundler::Definition.build(lockfile_definition[:gemfile], lockfile_definition[:lockfile], false)
      return false unless definition.send(:current_platform_locked?)

      begin
        definition.validate_runtime!
        definition.resolve_only_locally!
        not_installed = definition.missing_specs
      rescue ::Bundler::RubyVersionMismatch, ::Bundler::GemNotFound, ::Bundler::SolveFailure
        return false
      end

      not_installed.empty?
    end

    # this checks for mismatches between the default lockfile and the given lockfile,
    # and for pinned dependencies in lockfiles requiring them
    def check(lockfile_definition, allow_mismatched_dependencies: true)
      success = true
      proven_pinned = Set.new
      needs_pin_check = []
      lockfile = ::Bundler::LockfileParser.new(lockfile_definition[:lockfile].read)
      unless lockfile.platforms == @default_lockfile.platforms
        ::Bundler.ui.error("The platforms in #{lockfile_definition[:lockfile].relative_path_from(Dir.pwd)} do not match the default lockfile.")
        success = false
      end
      unless lockfile.bundler_version == @default_lockfile.bundler_version
        ::Bundler.ui.error("bundler (#{lockfile.bundler_version}) in #{lockfile_definition[:lockfile].relative_path_from(Dir.pwd)} does not match the default lockfile's version (@#{@default_lockfile.bundler_version}).")
        success = false
      end

      specs = lockfile.specs.group_by(&:name)
      allow_mismatched_dependencies = lockfile_definition[:allow_mismatched_dependencies] if allow_mismatched_dependencies

      # build list of top-level dependencies that differ from the default lockfile,
      # and all _their_ transitive dependencies
      if allow_mismatched_dependencies
        transitive_dependencies = Set.new
        # only dependencies that differ from the default lockfile
        pending_transitive_dependencies = lockfile.dependencies.reject do |name, dep|
          @default_lockfile.dependencies[name] == dep
        end.map(&:first)

        until pending_transitive_dependencies.empty?
          dep = pending_transitive_dependencies.shift
          next if transitive_dependencies.include?(dep)

          transitive_dependencies << dep
          platform_specs = specs[dep]
          unless platform_specs
            # should only be bundler that's missing a spec
            raise "Could not find spec for dependency #{dep}" unless dep == "bundler"

            next
          end

          pending_transitive_dependencies.concat(platform_specs.flat_map(&:dependencies).map(&:name).uniq)
        end
      end

      # look through top-level explicit dependencies for pinned requirements
      if lockfile_definition[:enforce_pinned_additional_dependencies]
        find_pinned_dependencies(proven_pinned, lockfile.dependencies.each_value)
      end

      # check for conflicting requirements (and build list of pins, in the same loop)
      specs.values.flatten.each do |spec|
        default_spec = @default_specs[[spec.name, spec.platform]]

        if lockfile_definition[:enforce_pinned_additional_dependencies]
          # look through what this spec depends on, and keep track of all pinned requirements
          find_pinned_dependencies(proven_pinned, spec.dependencies)

          needs_pin_check << spec unless default_spec
        end

        next unless default_spec

        # have to ensure Path sources are relative to their lockfile before comparing
        same_source = if [default_spec.source, spec.source].grep(::Bundler::Source::Path).length == 2
                        lockfile_definition[:lockfile].dirname.join(spec.source.path).ascend.any?(::Bundler.default_lockfile.dirname.join(default_spec.source.path))
                      else
                        default_spec.source == spec.source
                      end

        next if default_spec.version == spec.version && same_source
        next if allow_mismatched_dependencies && transitive_dependencies.include?(spec.name)

        ::Bundler.ui.error("#{spec}#{spec.git_version} in #{lockfile_definition[:lockfile].relative_path_from(Dir.pwd)} does not match the default lockfile's version (@#{default_spec.version}#{default_spec.git_version}); this may be due to a conflicting requirement, which would require manual resolution.")
        success = false
      end

      # now that we have built a list of every gem that is pinned, go through
      # the gems that were in this lockfile, but not the default lockfile, and
      # ensure it's pinned _somehow_
      needs_pin_check.each do |spec|
        pinned = case spec.source
                 when ::Bundler::Source::Git
                   spec.source.ref == spec.source.revision
                 when ::Bundler::Source::Path
                   true
                 when ::Bundler::Source::Rubygems
                   proven_pinned.include?(spec.name)
                 else
                   false
                 end

        unless pinned
          ::Bundler.ui.error("#{spec} in #{lockfile_definition[:lockfile].relative_path_from(Dir.pwd)} has not been pinned to a specific version, which is required since it is not part of the default lockfile.")
          success = false
        end
      end

      success
    end

    private

    def find_pinned_dependencies(proven_pinned, dependencies)
      dependencies.each do |dependency|
        dependency.requirement.requirements.each do |requirement|
          proven_pinned << dependency.name if requirement.first == "="
        end
      end
    end
  end
end
