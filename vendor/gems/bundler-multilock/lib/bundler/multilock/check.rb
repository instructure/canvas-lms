# frozen_string_literal: true

require "set"

require_relative "cache"

module Bundler
  module Multilock
    class Check
      class << self
        def run
          new.run
        end
      end

      def initialize(cache = Cache.new)
        @cache = cache
      end

      def run(skip_base_checks: false)
        return true unless Bundler.default_lockfile(force_original: true).exist?

        success = true
        unless skip_base_checks
          default_lockfile_definition = Multilock.default_lockfile_definition
          default_lockfile_definition ||= { gemfile: Bundler.default_gemfile,
                                            lockfile: Bundler.default_lockfile(force_original: true) }
          base_check(default_lockfile_definition)
        end
        Multilock.lockfile_definitions.each do |lockfile_name, lockfile_definition|
          next if lockfile_name == Bundler.default_lockfile(force_original: true)

          unless lockfile_name.exist?
            Bundler.ui.error("Lockfile #{lockfile_name} does not exist.")
            success = false
            next
          end

          success &&= base_check(lockfile_definition) && deep_check(lockfile_definition)
        end
        success
      end

      # this is mostly equivalent to the built in checks in `bundle check`, but even
      # more conservative, and returns false instead of exiting on failure
      def base_check(lockfile_definition, check_missing_deps: false)
        lockfile_name = lockfile_definition[:lockfile]
        default_root = Bundler.root

        result = @cache.base_check(lockfile_name) do
          next false unless lockfile_name.file?

          Multilock.prepare_block = lockfile_definition[:prepare]
          # root needs to be set so that paths are output relative to the correct root in the lockfile
          Bundler.root = lockfile_definition[:gemfile].dirname

          definition = Definition.build(lockfile_definition[:gemfile], lockfile_name, false)
          next false unless definition.send(:current_platform_locked?)

          begin
            definition.validate_runtime!
            not_installed = Bundler.ui.silence { definition.missing_specs }
          rescue RubyVersionMismatch, GemNotFound, SolveFailure
            next false
          end

          if Bundler.ui.error?
            not_installed.each do |spec|
              @cache.log_missing_spec(spec)
            end
          end

          next false unless not_installed.empty?

          # cache a sentinel so that we can share a cache regardless of the check_missing_deps argument
          next :missing_deps unless (definition.locked_gems.dependencies.values - definition.dependencies).empty?

          true
        end

        return !check_missing_deps if result == :missing_deps

        result
      ensure
        Multilock.prepare_block = nil
        Bundler.root = default_root
      end

      # this checks for mismatches between the parent lockfile and the given lockfile,
      # and for pinned dependencies in lockfiles requiring them
      def deep_check(lockfile_definition)
        lockfile_name = lockfile_definition[:lockfile]
        @cache.deep_check(lockfile_name) do
          success = true
          proven_pinned = Set.new
          needs_pin_check = []
          parser = @cache.parser(lockfile_name)
          lockfile_path = lockfile_name.relative_path_from(Dir.pwd)
          parent_lockfile_name = lockfile_definition[:parent]
          parent_parser = @cache.parser(parent_lockfile_name)
          unless parser.platforms == parent_parser.platforms
            Bundler.ui.error("The platforms in #{lockfile_path} do not match the parent lockfile.")
            success = false
          end
          unless parser.bundler_version == parent_parser.bundler_version
            Bundler.ui.error("bundler (#{parser.bundler_version}) in #{lockfile_path} " \
                             "does not match the parent lockfile's version (@#{parent_parser.bundler_version}).")
            success = false
          end
          unless parser.ruby_version == parent_parser.ruby_version
            Bundler.ui.error("ruby (#{parser.ruby_version || "<none>"}) in #{lockfile_path} " \
                             "does not match the parent lockfile's version (#{parent_parser.ruby_version}).")
            success = false
          end

          # look through top-level explicit dependencies for pinned requirements
          if lockfile_definition[:enforce_pinned_additional_dependencies]
            find_pinned_dependencies(proven_pinned, parser.dependencies.each_value)
          end

          # check for conflicting requirements (and build list of pins, in the same loop)
          parser.specs.each do |spec|
            parent_spec = @cache.specs(parent_lockfile_name)[[spec.name, spec.platform]]

            if lockfile_definition[:enforce_pinned_additional_dependencies]
              # look through what this spec depends on, and keep track of all pinned requirements
              find_pinned_dependencies(proven_pinned, spec.dependencies)

              needs_pin_check << spec unless parent_spec
            end

            next unless parent_spec

            # have to ensure Path sources are relative to their lockfile before comparing
            same_source = if [parent_spec.source, spec.source].grep(Source::Path).length == 2
                            lockfile_name
                              .dirname
                              .join(spec.source.path)
                              .ascend
                              .any?(parent_lockfile_name.dirname.join(parent_spec.source.path))
                          else
                            parent_spec.source == spec.source
                          end

            next if parent_spec.version == spec.version && same_source

            # the version in the parent lockfile cannot possibly satisfy the requirements
            # in this lockfile, and vice versa, so we assume it's intentional and allow it
            if @cache.conflicting_requirements?(lockfile_name, parent_lockfile_name, spec, parent_spec)
              # we're allowing it to differ from the parent, so pin check requirement comes into play
              needs_pin_check << spec if lockfile_definition[:enforce_pinned_additional_dependencies]
              next
            end

            Bundler.ui.error("#{spec}#{spec.git_version} in #{lockfile_path} " \
                             "does not match the parent lockfile's version " \
                             "(@#{parent_spec.version}#{parent_spec.git_version}); " \
                             "this may be due to a conflicting requirement, which would require manual resolution.")
            success = false
          end

          # now that we have built a list of every gem that is pinned, go through
          # the gems that were in this lockfile, but not the parent lockfile, and
          # ensure it's pinned _somehow_
          needs_pin_check.each do |spec|
            pinned = case spec.source
                     when Source::Git
                       spec.source.ref == spec.source.revision
                     when Source::Path
                       true
                     when Source::Rubygems
                       proven_pinned.include?(spec.name)
                     else
                       false
                     end

            next if pinned

            Bundler.ui.error("#{spec} in #{lockfile_path} has not been pinned to a specific version,  " \
                             "which is required since it is not part of the parent lockfile.")
            success = false
          end

          success
        end
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
end
