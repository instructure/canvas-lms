# frozen_string_literal: true

# What have they done to the Gemfile???
#
# Relax. Breathe deep. All the gems are still there; they're just loaded in
# various files in Gemfile.d/. This allows us to require gems locally that we
# might not want to commit to our public repo. We can maintain a customized
# list of gems for development and debuggery, without affecting our ability to
# merge with canvas-lms
#

source "https://rubygems.org/"

plugin "bundler_lockfile_extensions", path: "gems/bundler_lockfile_extensions"

require File.expand_path("config/canvas_rails_switcher", __dir__)

# Bundler evaluates this from a non-global context for plugins, so we have
# to explicitly pop up to set global constants
# rubocop:disable Style/RedundantConstantBase

# will already be defined during the second Gemfile evaluation
::CANVAS_INCLUDE_PLUGINS = true unless defined?(::CANVAS_INCLUDE_PLUGINS)

if Plugin.installed?("bundler_lockfile_extensions")
  Plugin.send(:load_plugin, "bundler_lockfile_extensions") unless defined?(BundlerLockfileExtensions)

  unless BundlerLockfileExtensions.enabled?
    default = true
    SUPPORTED_RAILS_VERSIONS.product([nil, true]).each do |rails_version, include_plugins|
      prepare = lambda do
        Object.send(:remove_const, :CANVAS_RAILS)
        ::CANVAS_RAILS = rails_version
        Object.send(:remove_const, :CANVAS_INCLUDE_PLUGINS)
        ::CANVAS_INCLUDE_PLUGINS = include_plugins
      end

      lockfile = ["Gemfile", "rails#{rails_version.delete(".")}", include_plugins && "plugins", "lock"].compact.join(".")
      lockfile = nil if default
      # only the first lockfile is the default
      default = false

      current = rails_version == CANVAS_RAILS && include_plugins

      add_lockfile(lockfile,
                   current:,
                   prepare:,
                   allow_mismatched_dependencies: rails_version != SUPPORTED_RAILS_VERSIONS.first,
                   enforce_pinned_additional_dependencies: include_plugins)
    end

    Dir["Gemfile.d/*.lock", "gems/*/Gemfile.lock", base: Bundler.root].each do |gem_lockfile_name|
      return unless add_lockfile(gem_lockfile_name,
                                 gemfile: gem_lockfile_name.sub(/\.lock$/, ""),
                                 allow_mismatched_dependencies: false)
    end
  end
end
# rubocop:enable Style/RedundantConstantBase

# Bundler's first pass parses the entire Gemfile and calls to additional sources
# makes it actually go and retrieve metadata from them even though the plugin will
# never exist there. Short-circuit it here if we're in the plugin-specific DSL
# phase to prevent that from happening.
return if method(:source).owner == Bundler::Plugin::DSL

module PreferGlobalRubyGemsSource
  def rubygems_sources
    [global_rubygems_source] + non_global_rubygems_sources
  end
end
Bundler::SourceList.prepend(PreferGlobalRubyGemsSource)

module GemOverride
  def gem(name, *version, path: nil, **kwargs)
    # Bundler calls `gem` internally by passing a splat with a hash as the
    # last argument, instead of properly using kwargs. Detect that.
    if version.last.is_a?(Hash) && kwargs.empty?
      kwargs = version.pop
    end
    vendor_path = File.expand_path("vendor/#{name}", __dir__)
    if File.directory?(vendor_path)
      super(name, path: vendor_path, **kwargs)
    else
      super(name, *version, path:, **kwargs)
    end
  end
end
Bundler::Dsl.prepend(GemOverride)

if CANVAS_INCLUDE_PLUGINS
  Dir[File.join(File.dirname(__FILE__), "gems/plugins/*/Gemfile.d/_before.rb")].each do |file|
    eval_gemfile(file)
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "Gemfile.d", "*.rb")).each do |file|
  eval_gemfile(file)
end
