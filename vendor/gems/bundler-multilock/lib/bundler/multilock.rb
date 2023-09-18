# frozen_string_literal: true

require_relative "multilock/ext/bundler"
require_relative "multilock/ext/definition"
require_relative "multilock/ext/dsl"
require_relative "multilock/ext/plugin"
require_relative "multilock/ext/plugin/dsl"
require_relative "multilock/ext/source_list"
require_relative "multilock/version"

module Bundler
  module Multilock
    class << self
      # @!visibility private
      attr_reader :lockfile_definitions
      # @!visibility private
      attr_accessor :prepare_block

      # @param lockfile [String] The lockfile path (defaults to Gemfile.lock)
      # @param builder [Dsl] The Bundler DSL
      # @param gemfile [String, nil]
      #   The Gemfile for this lockfile (defaults to Gemfile)
      # @param default [Boolean]
      #   If this lockfile should be the default (instead of Gemfile.lock)
      # @param allow_mismatched_dependencies [true, false]
      #   Allows version differences in dependencies between this lockfile and
      #   the default lockfile. Note that even with this option, only top-level
      #   dependencies that differ from the default lockfile, and their transitive
      #   depedencies, are allowed to mismatch.
      # @param enforce_pinned_additional_dependencies [true, false]
      #   If dependencies are present in this lockfile that are not present in the
      #   default lockfile, enforce that they are pinned.
      # @yield
      #   Block executed only when this lockfile is active.
      # @return [true, false] if the lockfile is the current lockfile
      def add_lockfile(lockfile = nil,
                       builder:,
                       gemfile: nil,
                       default: nil,
                       allow_mismatched_dependencies: true,
                       enforce_pinned_additional_dependencies: false,
                       &block)
        # terminology gets confusing here. The "default" param means
        # "use this lockfile when not overridden by BUNDLE_LOCKFILE"
        # but Bundler.defaul_lockfile (usually) means "Gemfile.lock"
        # so refer to the former as "current" internally
        current = default
        current = true if current.nil? && lockfile_definitions.empty? && lockfile.nil? && gemfile.nil?

        # allow short-form lockfile names
        lockfile = "Gemfile.#{lockfile}.lock" if lockfile && !(lockfile.include?("/") || lockfile.end_with?(".lock"))
        # if a gemfile was provided, but not a lockfile, infer the default lockfile for that gemfile
        lockfile ||= "#{gemfile}.lock" if gemfile
        # use absolute paths
        lockfile = Bundler.root.join(lockfile).expand_path if lockfile
        # use the default lockfile (Gemfile.lock) if none was given
        lockfile ||= Bundler.default_lockfile(force_original: true)
        raise ArgumentError, "Lockfile #{lockfile} is already defined" if lockfile_definitions.any? do |definition|
                                                                            definition[:lockfile] == lockfile
                                                                          end

        env_lockfile = ENV["BUNDLE_LOCKFILE"]
        if env_lockfile
          unless env_lockfile.include?("/") || env_lockfile.end_with?(".lock")
            env_lockfile = "Gemfile.#{env_lockfile}.lock"
          end
          env_lockfile = Bundler.root.join(env_lockfile).expand_path
          current = env_lockfile == lockfile
        end

        if current && (old_current = lockfile_definitions.find { |definition| definition[:current] })
          raise ArgumentError, "Only one lockfile (#{old_current[:lockfile]}) can be flagged as the default"
        end

        lockfile_definitions << (lockfile_def = {
          gemfile: (gemfile && Bundler.root.join(gemfile).expand_path) || Bundler.default_gemfile,
          lockfile: lockfile,
          current: current,
          prepare: block,
          allow_mismatched_dependencies: allow_mismatched_dependencies,
          enforce_pinned_additional_dependencies: enforce_pinned_additional_dependencies
        })

        if (defined?(CLI::Check) ||
            defined?(CLI::Install) ||
            defined?(CLI::Lock) ||
            defined?(CLI::Update)) &&
           !defined?(CLI::Cache) && !env_lockfile
          # always use Gemfile.lock for `bundle check`, `bundle install`,
          # `bundle lock`, and `bundle update`. `bundle cache` delegates to
          # `bundle install`, but we want that to run as normal.
          # If they're using BUNDLE_LOCKFILE, then they really do want to
          # use a particular lockfile, and it overrides whatever they
          # dynamically set in their gemfile
          current = lockfile == Bundler.default_lockfile(force_original: true)
        end

        if current
          block&.call
          Bundler.default_lockfile = lockfile

          # we started evaluating the project's primary gemfile, but got told to use a lockfile
          # associated with a different Gemfile. so we need to evaluate that Gemfile instead
          if lockfile_def[:gemfile] != Bundler.default_gemfile
            # share a cache between all lockfiles
            Bundler.cache_root = Bundler.root
            ENV["BUNDLE_GEMFILE"] = lockfile_def[:gemfile].to_s
            Bundler.root = Bundler.default_gemfile.dirname
            Bundler.default_lockfile = lockfile

            builder.eval_gemfile(Bundler.default_gemfile)

            return false
          end
        end
        true
      end

      # @!visibility private
      def after_install_all(install: true)
        loaded!
        previous_recursive = @recursive

        return if lockfile_definitions.empty?
        return if ENV["BUNDLE_LOCKFILE"] # explicitly working against a single lockfile

        # must be running `bundle cache`
        return unless Bundler.default_lockfile == Bundler.default_lockfile(force_original: true)

        require_relative "multilock/check"

        if Bundler.frozen_bundle? && !install
          # only do the checks if we're frozen
          exit 1 unless Check.run
          return
        end

        # this hook will be called recursively when it has to install gems
        # for a secondary lockfile. defend against that
        return if @recursive

        @recursive = true

        require "tempfile"
        require_relative "multilock/lockfile_generator"

        Bundler.ui.info ""

        default_lockfile_contents = Bundler.default_lockfile.read.freeze
        default_specs = LockfileParser.new(default_lockfile_contents).specs.to_h do |spec|
          [[spec.name, spec.platform], spec]
        end
        default_root = Bundler.root

        attempts = 1

        checker = Check.new
        synced_any = false
        Bundler.settings.temporary(cache_all_platforms: true, suppress_install_using_messages: true) do
          lockfile_definitions.each do |lockfile_definition|
            # we already wrote the default lockfile
            next if lockfile_definition[:lockfile] == Bundler.default_lockfile(force_original: true)

            # root needs to be set so that paths are output relative to the correct root in the lockfile
            Bundler.root = lockfile_definition[:gemfile].dirname

            relative_lockfile = lockfile_definition[:lockfile].relative_path_from(Dir.pwd)

            # already up to date?
            up_to_date = false
            Bundler.settings.temporary(frozen: true) do
              Bundler.ui.silence do
                up_to_date = checker.base_check(lockfile_definition) &&
                             checker.check(lockfile_definition, allow_mismatched_dependencies: false)
              end
            end
            if up_to_date
              attempts = 1
              next
            end

            if Bundler.frozen_bundle?
              # if we're frozen, you have to use the pre-existing lockfile
              unless lockfile_definition[:lockfile].exist?
                Bundler.ui.error("The bundle is locked, but #{relative_lockfile} is missing. " \
                                 "Please make sure you have checked #{relative_lockfile} " \
                                 "into version control before deploying.")
                exit 1
              end

              Bundler.ui.info("Installing gems for #{relative_lockfile}...")
              write_lockfile(lockfile_definition, lockfile_definition[:lockfile], install: install)
            else
              Bundler.ui.info("Syncing to #{relative_lockfile}...") if attempts == 1
              synced_any = true

              # adjust locked paths from the default lockfile to be relative to _this_ gemfile
              adjusted_default_lockfile_contents =
                default_lockfile_contents.gsub(/PATH\n  remote: ([^\n]+)\n/) do |remote|
                  remote_path = Pathname.new($1)
                  next remote if remote_path.absolute?

                  relative_remote_path = remote_path.expand_path(default_root).relative_path_from(Bundler.root).to_s
                  remote.sub($1, relative_remote_path)
                end

              # add a source for the current gem
              gem_spec = default_specs[[File.basename(Bundler.root), "ruby"]]

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
                default_lockfile = LockfileParser.new(adjusted_default_lockfile_contents)
                lockfile = LockfileParser.new(lockfile_definition[:lockfile].read)

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
                lockfile.platforms.replace(default_lockfile.platforms).uniq!
                # prune more specific platforms
                lockfile.platforms.delete_if do |p1|
                  lockfile.platforms.any? do |p2|
                    p2 != "ruby" && p1 != p2 && MatchPlatform.platforms_match?(p2, p1)
                  end
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

                had_changes = write_lockfile(lockfile_definition,
                                             temp_lockfile.path,
                                             install: install,
                                             dependency_changes: dependency_changes)
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
        ensure
          Bundler.root = default_root
        end

        exit 1 unless checker.run(skip_base_checks: !synced_any)
      ensure
        @recursive = previous_recursive
      end

      # @!visibility private
      def loaded!
        return if loaded?

        @loaded = true
        return if lockfile_definitions.empty?

        return unless lockfile_definitions.none? { |definition| definition[:current] }

        # Gemfile.lock isn't explicitly specified, otherwise it would be current
        default_lockfile_definition = lockfile_definitions.find do |definition|
          definition[:lockfile] == Bundler.default_lockfile(force_original: true)
        end
        if ENV["BUNDLE_LOCKFILE"] == Bundler.default_lockfile(force_original: true) && default_lockfile_definition
          return
        end

        raise GemfileNotFound, "Could not locate lockfile #{ENV["BUNDLE_LOCKFILE"].inspect}" if ENV["BUNDLE_LOCKFILE"]

        return unless default_lockfile_definition && default_lockfile_definition[:current] == false

        raise GemfileEvalError, "No lockfiles marked as default"
      end

      # @!visibility private
      def loaded?
        @loaded
      end

      # @!visibility private
      def inject_preamble
        minor_version = Gem::Version.new(::Bundler::Multilock::VERSION).segments[0..1].join(".")
        bundle_preamble1_match = %(plugin "bundler-multilock")
        bundle_preamble1 = <<~RUBY
          plugin "bundler-multilock", "~> #{minor_version}"
        RUBY
        bundle_preamble2 = <<~RUBY
          return unless Plugin.installed?("bundler-multilock")

          Plugin.send(:load_plugin, "bundler-multilock")
        RUBY

        gemfile = Bundler.default_gemfile.read

        injection_point = 0
        while gemfile.match?(/^(?:#|\n|source)/, injection_point)
          if gemfile[injection_point] == "\n"
            injection_point += 1
          else
            injection_point = gemfile.index("\n", injection_point)
            injection_point += 1 if injection_point
            injection_point ||= -1
          end
        end

        modified = inject_specific_preamble(gemfile, injection_point, bundle_preamble2, add_newline: true)
        modified = true if inject_specific_preamble(gemfile,
                                                    injection_point,
                                                    bundle_preamble1,
                                                    match: bundle_preamble1_match,
                                                    add_newline: false)

        Bundler.default_gemfile.write(gemfile) if modified
      end

      # @!visibility private
      def reset!
        @lockfile_definitions = []
        @loaded = false
      end

      private

      def inject_specific_preamble(gemfile, injection_point, preamble, add_newline:, match: preamble)
        return false if gemfile.include?(match)

        add_newline = false unless gemfile[injection_point - 1] == "\n"

        gemfile.insert(injection_point, "\n") if add_newline
        gemfile.insert(injection_point, preamble)

        true
      end

      def write_lockfile(lockfile_definition, lockfile, install:, dependency_changes: false)
        prepare_block = lockfile_definition[:prepare]

        gemfile = lockfile_definition[:gemfile]
        # use avoid Definition.build, so that we don't have to evaluate
        # the gemfile multiple times, each time we need a separate definition
        builder = Dsl.new
        builder.eval_gemfile(gemfile, &prepare_block) if prepare_block
        builder.eval_gemfile(gemfile)

        definition = builder.to_definition(lockfile, {})
        definition.instance_variable_set(:@dependency_changes, dependency_changes) if dependency_changes
        orig_definition = definition.dup # we might need it twice

        current_lockfile = lockfile_definition[:lockfile]
        if current_lockfile.exist?
          definition.instance_variable_set(:@lockfile_contents, current_lockfile.read)
          if install
            current_definition = builder.to_definition(current_lockfile, {})
            begin
              current_definition.resolve_only_locally!
              if current_definition.missing_specs.any?
                Bundler.with_default_lockfile(current_lockfile) do
                  Installer.install(gemfile.dirname, current_definition, {})
                end
              end
            rescue RubyVersionMismatch, GemNotFound, SolveFailure
              # ignore
            end
          end
        end

        resolved_remotely = false
        begin
          previous_ui_level = Bundler.ui.level
          Bundler.ui.level = "warn"
          begin
            definition.resolve_with_cache!
          rescue GemNotFound, SolveFailure
            definition = orig_definition

            definition.resolve_remotely!
            resolved_remotely = true
          end
          definition.lock(lockfile_definition[:lockfile], true)
        ensure
          Bundler.ui.level = previous_ui_level
        end

        # if we're running `bundle install` or `bundle update`, and something is missing from
        # the secondary lockfile, install it.
        if install && (definition.missing_specs.any? || resolved_remotely)
          Bundler.with_default_lockfile(lockfile_definition[:lockfile]) do
            Installer.install(lockfile_definition[:gemfile].dirname, definition, {})
          end
        end

        !definition.nothing_changed?
      end
    end

    reset!

    @recursive = false
    @prepare_block = nil
  end
end
