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

require "bundler_lockfile_extensions/bundler"
require "bundler_lockfile_extensions/bundler/definition"
require "bundler_lockfile_extensions/bundler/dsl"
require "bundler_lockfile_extensions/bundler/source_list"

# Extends Bundler to allow arbitrarily many lockfiles (and Gemfiles!)
# for variations of the Gemfile, while keeping all of the lockfiles in sync.
#
# `bundle install`, `bundle lock`, and `bundle update` will operate only on
# the default lockfile (Gemfile.lock), afterwhich all other lockfiles will
# be re-created based on this default lockfile. Additional lockfiles can be
# based on the same Gemfile, but vary at runtime based on something like an
# environment variable, global variable, or constant. When defining such a
# lockfile, you should use a prepare callback that sets up the proper
# environment for that variation, even if that's not what would otherwise
# be selected by the launching environment.
#
# Alternately (or in addition!), you can define a lockfile to use a completely
# different Gemfile. This will have the effect that common dependencies between
# the two Gemfiles will stay locked to the same version in each lockfile.
#
# A lockfile definition can opt in to requiring explicit pinning for
# any dependency that exists in that variation, but does not exist in the default
# lockfile. This is especially useful if for some reason a given
# lockfile will _not_ be committed to version control (such as a variation
# that will include private plugins).
#
# Finally, `bundle check` will enforce additional checks to compare the final
# locked versions of dependencies between the various lockfiles to ensure
# they end up the same. This check might be tripped if Gemfile variations
# (accidentally!) have conflicting version constraints on a dependency, that
# are still self-consistent with that single Gemfile variation.
# `bundle install`, `bundle lock`, and `bundle update` will also verify these
# additional checks. You can additionally explicitly allow version variations
# between explicit dependencies (and their sub-dependencies), for cases where
# the lockfile variation is specifically to transition to a new version of
# a dependency (like a Rails upgrade).
#
module BundlerLockfileExtensions
  class << self
    attr_reader :lockfile_definitions

    def enabled?
      @lockfile_definitions
    end

    # @param lockfile [String] The lockfile path
    # @param Builder [::Bundler::DSL] The Bundler DSL
    # @param gemfile [String, nil]
    #   The Gemfile for this lockfile (defaults to Gemfile)
    # @param current [true, false] If this is the currently active combination
    # @param prepare [Proc, nil]
    #   The callback to set up the environment so your Gemfile knows this is
    #   the intended lockfile, and to select dependencies appropriately.
    # @param allow_mismatched_dependencies [true, false]
    #   Allows version differences in dependencies between this lockfile and
    #   the default lockfile. Note that even with this option, only top-level
    #   dependencies that differ from the default lockfile, and their transitive
    #   depedencies, are allowed to mismatch.
    # @param enforce_pinned_additional_dependencies [true, false]
    #   If dependencies are present in this lockfile that are not present in the
    #   default lockfile, enforce that they are pinned.
    def add_lockfile(lockfile = nil,
                     builder:,
                     gemfile: nil,
                     current: false,
                     prepare: nil,
                     allow_mismatched_dependencies: true,
                     enforce_pinned_additional_dependencies: false)
      enable unless enabled?

      default = gemfile.nil? && lockfile.nil?
      if default && default_lockfile_definition
        raise ArgumentError, "Only one default lockfile (gemfile and lockfile unspecified) is allowed"
      end
      if current && @lockfile_definitions.any? { |definition| definition[:current] }
        raise ArgumentError, "Only one lockfile can be flagged as the current lockfile"
      end

      @lockfile_definitions << (lockfile_def = {
        gemfile: (gemfile && ::Bundler.root.join(gemfile).expand_path) || ::Bundler.default_gemfile,
        lockfile: (lockfile && ::Bundler.root.join(lockfile).expand_path) || ::Bundler.default_lockfile,
        default:,
        current:,
        prepare:,
        allow_mismatched_dependencies:,
        enforce_pinned_additional_dependencies:
      }.freeze)

      # if BUNDLE_LOCKFILE is specified, explicitly use only that lockfile, regardless of the command
      if ENV["BUNDLE_LOCKFILE"]
        if File.expand_path(ENV["BUNDLE_LOCKFILE"]) == lockfile_def[:lockfile].to_s
          prepare&.call
          set_lockfile = true
          # we started evaluating the project's primary gemfile, but got told to use a lockfile
          # associated with a different Gemfile. so we need to evaluate that Gemfile instead
          if lockfile_def[:gemfile] != ::Bundler.default_gemfile
            # share a cache between all lockfiles
            ::Bundler.cache_root = ::Bundler.root
            ENV["BUNDLE_GEMFILE"] = lockfile_def[:gemfile].to_s
            ::Bundler.root = ::Bundler.default_gemfile.dirname
            ::Bundler.default_lockfile = lockfile_def[:lockfile]

            builder.eval_gemfile(::Bundler.default_gemfile)

            return false
          end
        end
      else
        # always use the default lockfile for `bundle check`, `bundle install`,
        # `bundle lock`, and `bundle update`. `bundle cache` delegates to
        # `bundle install`, but we want that to run as-normal.
        set_lockfile = if (defined?(::Bundler::CLI::Check) ||
          defined?(::Bundler::CLI::Install) ||
          defined?(::Bundler::CLI::Lock) ||
          defined?(::Bundler::CLI::Update)) &&
                          !defined?(::Bundler::CLI::Cache)
                         prepare&.call if default
                         default
                       else
                         current
                       end
      end
      ::Bundler.default_lockfile = lockfile_def[:lockfile] if set_lockfile
      true
    end

    # @!visibility private
    def after_install_all(install: true)
      previous_recursive = @recursive

      return unless enabled?
      return if ENV["BUNDLE_LOCKFILE"] # explicitly working against a single lockfile

      # must be running `bundle cache`
      return unless ::Bundler.default_lockfile == default_lockfile_definition[:lockfile]

      require "bundler_lockfile_extensions/check"

      if ::Bundler.frozen_bundle? && !install
        # only do the checks if we're frozen
        exit 1 unless Check.run
        return
      end

      # this hook will be called recursively when it has to install gems
      # for a secondary lockfile. defend against that
      return if @recursive

      @recursive = true

      require "tempfile"
      require "bundler_lockfile_extensions/lockfile_generator"

      ::Bundler.ui.info ""

      default_lockfile_contents = ::Bundler.default_lockfile.read.freeze
      default_specs = ::Bundler::LockfileParser.new(default_lockfile_contents).specs.to_h do |spec| # rubocop:disable Rails/IndexBy
        [[spec.name, spec.platform], spec]
      end
      default_root = ::Bundler.root

      attempts = 1

      checker = Check.new
      ::Bundler.settings.temporary(cache_all_platforms: true, suppress_install_using_messages: true) do
        @lockfile_definitions.each do |lockfile_definition|
          # we already wrote the default lockfile
          next if lockfile_definition[:default]

          # root needs to be set so that paths are output relative to the correct root in the lockfile
          ::Bundler.root = lockfile_definition[:gemfile].dirname

          relative_lockfile = lockfile_definition[:lockfile].relative_path_from(Dir.pwd)

          # already up to date?
          up_to_date = false
          ::Bundler.settings.temporary(frozen: true) do
            ::Bundler.ui.silence do
              up_to_date = checker.base_check(lockfile_definition) && checker.check(lockfile_definition, allow_mismatched_dependencies: false)
            end
          end
          if up_to_date
            attempts = 1
            next
          end

          if ::Bundler.frozen_bundle?
            # if we're frozen, you have to use the pre-existing lockfile
            unless lockfile_definition[:lockfile].exist?
              ::Bundler.ui.error("The bundle is locked, but #{relative_lockfile} is missing. Please make sure you have checked #{relative_lockfile} into version control before deploying.")
              exit 1
            end

            ::Bundler.ui.info("Installing gems for #{relative_lockfile}...")
            write_lockfile(lockfile_definition, lockfile_definition[:lockfile], install:)
          else
            ::Bundler.ui.info("Syncing to #{relative_lockfile}...") if attempts == 1

            # adjust locked paths from the default lockfile to be relative to _this_ gemfile
            adjusted_default_lockfile_contents = default_lockfile_contents.gsub(/PATH\n  remote: ([^\n]+)\n/) do |remote|
              remote_path = Pathname.new($1)
              next remote if remote_path.absolute?

              relative_remote_path = remote_path.expand_path(default_root).relative_path_from(::Bundler.root).to_s
              remote.sub($1, relative_remote_path)
            end

            # add a source for the current gem
            gem_spec = default_specs[[File.basename(::Bundler.root), "ruby"]]

            if gem_spec
              adjusted_default_lockfile_contents += <<~TEXT
                PATH
                  remote: .
                  specs:
                #{gem_spec.to_lock}
              TEXT
            end

            if lockfile_definition[:lockfile].exist?
              # if the lockfile already exists, "merge" it together
              default_lockfile = ::Bundler::LockfileParser.new(adjusted_default_lockfile_contents)
              lockfile = ::Bundler::LockfileParser.new(lockfile_definition[:lockfile].read)

              dependency_changes = false
              # replace any duplicate specs with what's in the default lockfile
              lockfile.specs.map! do |spec|
                default_spec = default_specs[[spec.name, spec.platform]]
                next spec unless default_spec

                dependency_changes ||= spec != default_spec
                default_spec
              end

              lockfile.specs.replace(default_lockfile.specs + lockfile.specs).uniq!
              lockfile.sources.replace(default_lockfile.sources + lockfile.sources).uniq!
              lockfile.platforms.concat(default_lockfile.platforms).uniq!
              # prune more specific platforms
              lockfile.platforms.delete_if do |p1|
                lockfile.platforms.any? { |p2| p2 != "ruby" && p1 != p2 && ::Bundler::MatchPlatform.platforms_match?(p2, p1) }
              end
              lockfile.instance_variable_set(:@ruby_version, default_lockfile.ruby_version)
              lockfile.instance_variable_set(:@bundler_version, default_lockfile.bundler_version)

              new_contents = LockfileGenerator.generate(lockfile)
            else
              # no lockfile? just start out with the default lockfile's contents to inherit its
              # locked gems
              new_contents = adjusted_default_lockfile_contents
            end

            had_changes = false
            # Now build a definition based on the given Gemfile, with the combined lockfile
            Tempfile.create do |temp_lockfile|
              temp_lockfile.write(new_contents)
              temp_lockfile.flush

              had_changes = write_lockfile(lockfile_definition, temp_lockfile.path, install:, dependency_changes:)
            end

            # if we had changes, bundler may have updated some common
            # dependencies beyond the default lockfile, so re-run it
            # once to reset them back to the default lockfile's version.
            # if it's already good, the `check` check at the beginning of
            # the loop will skip the second sync anyway.
            if had_changes && attempts < 3
              attempts += 1
              redo
            else
              attempts = 1
            end
          end
        end
      end

      exit 1 unless checker.run
    ensure
      @recursive = previous_recursive
    end

    private

    def enable
      @lockfile_definitions ||= []

      ::Bundler.singleton_class.prepend(Bundler::ClassMethods)
      ::Bundler::Definition.prepend(Bundler::Definition)
      ::Bundler::SourceList.prepend(Bundler::SourceList)
    end

    def default_lockfile_definition
      @default_lockfile_definition ||= @lockfile_definitions.find { |d| d[:default] }
    end

    def write_lockfile(lockfile_definition, lockfile, install:, dependency_changes: false)
      lockfile_definition[:prepare]&.call
      definition = ::Bundler::Definition.build(lockfile_definition[:gemfile], lockfile, false)
      definition.instance_variable_set(:@dependency_changes, dependency_changes) if dependency_changes

      resolved_remotely = false
      begin
        previous_ui_level = ::Bundler.ui.level
        ::Bundler.ui.level = "warn"
        begin
          definition.resolve_with_cache!
        rescue ::Bundler::GemNotFound, ::Bundler::SolveFailure
          definition = ::Bundler::Definition.build(lockfile_definition[:gemfile], lockfile, false)
          definition.resolve_remotely!
          resolved_remotely = true
        end
        definition.lock(lockfile_definition[:lockfile], true)
      ensure
        ::Bundler.ui.level = previous_ui_level
      end

      # if we're running `bundle install` or `bundle update`, and something is missing from
      # the secondary lockfile, install it.
      if install && (definition.missing_specs.any? || resolved_remotely)
        ::Bundler.with_default_lockfile(lockfile_definition[:lockfile]) do
          ::Bundler::Installer.install(lockfile_definition[:gemfile].dirname, definition, {})
        end
      end

      !definition.nothing_changed?
    end
  end

  @recursive = false
end

Bundler::Dsl.include(BundlerLockfileExtensions::Bundler::Dsl)

# this is terrible, but we can't prepend into any module because we only load
# _inside_ of the CLI commands already running
if defined?(Bundler::CLI::Check)
  require "bundler_lockfile_extensions/check"
  at_exit do
    next unless $!.nil?
    next if $!.is_a?(SystemExit) && !$!.success?

    next if BundlerLockfileExtensions::Check.run

    Bundler.ui.warn("You can attempt to fix by running `bundle install`")
    exit 1
  end
end
if defined?(Bundler::CLI::Lock)
  at_exit do
    next unless $!.nil?
    next if $!.is_a?(SystemExit) && !$!.success?

    BundlerLockfileExtensions.after_install_all(install: false)
  end
end
