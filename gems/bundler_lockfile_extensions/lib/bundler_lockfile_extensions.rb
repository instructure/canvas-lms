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

module BundlerDefinitionFilterableSources
  def dependencies
    return super unless BundlerLockfileExtensions.lockfile_writes_enabled && BundlerLockfileExtensions.lockfile_filter

    super.filter { |x| source_included?(x.instance_variable_get(:@source)) }
  end

  def sources
    return super unless BundlerLockfileExtensions.lockfile_writes_enabled && BundlerLockfileExtensions.lockfile_filter

    res = super.clone
    res.instance_variable_get(:@path_sources).filter! { |x| source_included?(x) }
    res.instance_variable_get(:@rubygems_sources).filter! { |x| source_included?(x) }
    res
  end

  def lock(...)
    return unless BundlerLockfileExtensions.lockfile_writes_enabled

    super(...)
  end

  def nothing_changed?
    locked_specs = instance_variable_get(:@locked_specs).to_hash.keys
    actual_specs = converge_locked_specs.to_hash.keys

    super && (locked_specs - actual_specs).empty?
  end

  def ensure_filtered_dependencies_pinned
    return unless BundlerLockfileExtensions.lockfile_filter

    check_dependencies = []

    @sources.instance_variable_get(:@rubygems_sources).each do |x|
      next if source_included?(x)

      specs = resolve.select { |s| x.can_lock?(s) }

      specs.each do |s|
        check_dependencies << s.name
      end
    end

    proven_pinned = check_dependencies.map { |x| [x, false] }.to_h

    valid_sources = []

    valid_sources.push(*@sources.instance_variable_get(:@path_sources))
    valid_sources.push(*@sources.instance_variable_get(:@rubygems_sources))

    valid_sources.each do |x|
      next if source_included?(x)

      specs = resolve.select { |s| x.can_lock?(s) }

      specs.each do |s|
        s.dependencies.each do |d|
          next unless proven_pinned.key?(d.name)

          d.requirement.requirements.each do |r|
            proven_pinned[d.name] = true if r[0] == "="
          end
        end
      end
    end

    proven_pinned.each do |k, v|
      raise BundlerLockfileExtensions::Error, "unable to prove that private gem #{k} was pinned - make sure it is pinned to only one resolveable version in the gemspec" unless v
    end
  end

  private

  def source_included?(source)
    BundlerLockfileExtensions.lockfile_filter.call(BundlerLockfileExtensions.lockfile_path, source)
  end
end

module BundlerLockfileExtensions
  class Error < Bundler::BundlerError; status_code(99); end

  class << self
    attr_accessor :lockfile_default, :lockfile_defs, :lockfile_filter, :lockfile_path, :lockfile_writes_enabled

    def enabled?
      !!@lockfile_defs
    end

    def enable(lockfile_defs)
      @lockfile_default = lockfile_defs.find { |x| !!x[1][:default] }[0]
      @lockfile_defs = lockfile_defs

      @lockfile_path =
        if defined?(Bundler::CLI::Cache) || defined?(Bundler::CLI::Lock)
          @lockfile_writes_enabled = true
          lockfile_default.to_s
        elsif (!Bundler.settings[:deployment] && defined?(Bundler::CLI::Install)) || defined?(Bundler::CLI::Update)
          # Sadly, this is the only place where the lockfile_path can be set correctly for the installation-like paths.
          # Ideally, it would go into before-install-all, but that is called after the lockfile is already loaded.
          install_lockfile_name(lockfile_default)
        else
          lockfile_default.to_s
        end

      Bundler::Dsl.class_eval do
        def to_definition(_lockfile, unlock)
          @sources << @rubygems_source if @sources.respond_to?(:include?) && !@sources.include?(@rubygems_source)
          Bundler::Definition.new(Bundler.default_lockfile, @dependencies, @sources, unlock, @ruby_version)
        end
      end

      Bundler::SharedHelpers.class_eval do
        class << self
          def default_lockfile
            Pathname.new(BundlerLockfileExtensions.lockfile_path).expand_path
          end
        end
      end

      Bundler::Definition.prepend(BundlerDefinitionFilterableSources)

      @lockfile_defs[lockfile_default][:prepare_environment]&.call
    end

    def each_lockfile_for_writing(lock)
      lock_def = @lockfile_defs[lock]

      @lockfile_writes_enabled = true

      @lockfile_path = lock.to_s
      yield @lockfile_path

      if lock_def[:install_filter]
        @lockfile_filter = lock_def[:install_filter]
        @lockfile_path = install_filter_lockfile_name(lock).to_s
        yield @lockfile_path

        @lockfile_filter = nil
      end

      @lockfile_writes_enabled = false
    end

    def install_filter_lockfile_name(lock)
      "#{lock}.partial"
    end

    def install_lockfile_name(lock)
      if @lockfile_defs[lock][:install_filter]
        install_filter_lockfile_name(lock)
      else
        lock.to_s
      end
    end

    def write_all_lockfiles
      current_definition = Bundler.definition
      unlock = current_definition.instance_variable_get(:@unlock)

      # Always prepare the default lockfiles first so that we don't re-resolve dependencies remotely
      each_lockfile_for_writing(lockfile_default) do |x|
        current_definition.ensure_filtered_dependencies_pinned
        current_definition.lock(x)
      end

      lockfile_defs.each do |lock, opts|
        next if lock == lockfile_default

        @lockfile_path = install_lockfile_name(lock)
        opts[:prepare_environment]&.call

        definition = Bundler::Definition.build(Bundler.default_gemfile, @lockfile_path, unlock)
        definition.resolve_remotely!
        definition.specs

        each_lockfile_for_writing(lock) do |x|
          definition.ensure_filtered_dependencies_pinned
          definition.lock(x)
        end
      end
    end
  end
end
