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

# cleanup local envs automatically from the old plugin
Plugin.uninstall(["bundler_lockfile_extensions"], {}) if Plugin.installed?("bundler_lockfile_extensions")

# vendored until https://github.com/rubygems/rubygems/pull/6957 is merged and released
plugin "bundler-multilock", "1.0.10", path: "vendor/gems/bundler-multilock"
# the extra check here is in case `bundle check` or `bundle exec` gets run before `bundle install`,
# and is also fixed by the same PR
raise GemNotFound, "bundler-multilock plugin is not installed" if !is_a?(Bundler::Plugin::DSL) && !Plugin.installed?("bundler-multilock")
return unless Plugin.installed?("bundler-multilock")

Plugin.send(:load_plugin, "bundler-multilock")

require_relative "config/canvas_rails_switcher"

# Bundler evaluates this from a non-global context for plugins, so we have
# to explicitly pop up to set global constants
# rubocop:disable Style/RedundantConstantBase

# will already be defined during the second Gemfile evaluation
::CANVAS_INCLUDE_PLUGINS = true unless defined?(::CANVAS_INCLUDE_PLUGINS)

SUPPORTED_RAILS_VERSIONS.product([nil, true]).each do |rails_version, include_plugins|
  lockfile = ["rails#{rails_version.delete(".")}", include_plugins && "plugins"].compact.join(".")
  lockfile = nil if rails_version == SUPPORTED_RAILS_VERSIONS.first && !include_plugins

  default = rails_version == CANVAS_RAILS && !!include_plugins

  lockfile(lockfile,
           default:,
           allow_mismatched_dependencies: rails_version != SUPPORTED_RAILS_VERSIONS.first,
           enforce_pinned_additional_dependencies: include_plugins) do
    Object.send(:remove_const, :CANVAS_RAILS)
    ::CANVAS_RAILS = rails_version
    Object.send(:remove_const, :CANVAS_INCLUDE_PLUGINS)
    ::CANVAS_INCLUDE_PLUGINS = include_plugins
  end
end

(gemfile_root.glob("Gemfile.d/*.lock") + gemfile_root.glob("gems/*/Gemfile.lock")).each do |gem_lockfile_name|
  return unless lockfile(gem_lockfile_name,
                         gemfile: gem_lockfile_name.to_s.sub(/\.lock$/, ""),
                         allow_mismatched_dependencies: false)
end
# rubocop:enable Style/RedundantConstantBase

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
  gemfile_root.glob("gems/plugins/*/Gemfile.d/_before.rb") do |file|
    eval_gemfile(file)
  end
end

gemfile_root.glob("Gemfile.d/*.rb").each do |file|
  eval_gemfile(file)
end
