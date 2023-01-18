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

  private

  def source_included?(source)
    BundlerLockfileExtensions.lockfile_filter.call(BundlerLockfileExtensions.lockfile_path, source)
  end
end

module BundlerLockfileExtensions
  class << self
    attr_accessor :lockfile_default, :lockfile_defs, :lockfile_filter, :lockfile_path, :lockfile_writes_enabled

    def enable(lockfile_defs)
      lockfile_default = lockfile_defs.find { |x| !!x[1][:default] }[0]

      BundlerLockfileExtensions.lockfile_default = lockfile_default
      BundlerLockfileExtensions.lockfile_defs = lockfile_defs

      BundlerLockfileExtensions.lockfile_path =
        if defined?(Bundler::CLI::Install) || defined?(Bundler::CLI::Update)
          # Sadly, this is the only place where the lockfile_path can be set correctly for the installation-like paths.
          # Ideally, it would go into before-install-all, but that is called after the lockfile is already loaded.
          BundlerLockfileExtensions.install_filter_lockfile_name(lockfile_default)
        else
          lockfile_default
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
            Pathname.new(BundlerLockfileExtensions.lockfile_path)
          end
        end
      end

      Bundler::Definition.prepend(BundlerDefinitionFilterableSources)
    end

    def each_lockfile_for_writing(lock)
      lock_def = @lockfile_defs[lock]

      @lockfile_writes_enabled = true

      @lockfile_path = lock
      yield @lockfile_path

      if lock_def[:install_filter]
        @lockfile_filter = lock_def[:install_filter]
        @lockfile_path = install_filter_lockfile_name(lock)
        yield @lockfile_path

        @lockfile_filter = nil
      end

      @lockfile_writes_enabled = false
    end

    def install_filter_lockfile_name(lock)
      "#{lock}.partial"
    end

    def write_all_lockfiles
      current_definition = Bundler.definition
      unlock = current_definition.instance_variable_get(:@unlock)

      # Always prepare the default lockfiles first so that we don't re-resolve dependencies remotely
      each_lockfile_for_writing(lockfile_default) { |x| current_definition.lock(x) }

      lockfile_defs.each do |lock, opts|
        next if lock == lockfile_default

        @lockfile_path = install_filter_lockfile_name(lock)
        opts[:prepare_environment].call

        definition = Bundler::Definition.build(Bundler.default_gemfile, @lockfile_path, unlock)
        definition.resolve_remotely!

        each_lockfile_for_writing(lock) { |x| definition.lock(x) }
      end
    end
  end
end
