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
plugin "bundler-multilock", "1.3.0", path: "vendor/gems/bundler-multilock"
# the extra check here is in case `bundle check` or `bundle exec` gets run before `bundle install`,
# and is also fixed by the same PR
raise GemNotFound, "bundler-multilock plugin is not installed" if !is_a?(Bundler::Plugin::DSL) && !Plugin.installed?("bundler-multilock")
return unless Plugin.installed?("bundler-multilock")

Plugin.send(:load_plugin, "bundler-multilock")

return if is_a?(Bundler::Plugin::DSL)

gemfile_root.glob("gems/plugins/*/Gemfile.d/_before.rb") do |file|
  eval_gemfile(file)
end

unless dependencies.empty?
  Bundler.ui.error("_before.rb from plugins should only modify the Gemfile logic, not introduce gem dependencies")
  exit 1
end

require_relative "config/canvas_rails_switcher"

if Bundler.default_gemfile == gemfile
  SUPPORTED_RAILS_VERSIONS.product([nil, true]).each do |rails_version, include_plugins|
    lockfile = ["rails#{rails_version.delete(".")}", include_plugins && "plugins"].compact.join(".")
    if rails_version == SUPPORTED_RAILS_VERSIONS.first
      lockfile = nil unless include_plugins
    elsif include_plugins
      parent = "rails#{rails_version.delete(".")}"
    end

    active = rails_version == $canvas_rails && !!include_plugins

    lockfile(lockfile,
             active:,
             parent:,
             enforce_pinned_additional_dependencies: include_plugins) do
      $canvas_rails = rails_version
      @include_plugins = include_plugins
    end
  end

  (gemfile_root.glob("Gemfile.d/*.lock") + gemfile_root.glob("gems/*/*.lock")).each do |gem_lockfile_name|
    parent = gem_lockfile_name.basename
    parent = nil unless parent.to_s.match?(/\.rails\d+\.lock$/)
    gemfile = gem_lockfile_name.to_s.sub(/(?:.rails\d+)?\.lock$/, "")
    return unless lockfile(gem_lockfile_name,
                           gemfile:,
                           parent:)
  end
end

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

gemfile_root.glob("Gemfile.d/*.rb").each do |file|
  eval_gemfile(file)
end
