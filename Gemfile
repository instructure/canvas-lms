# frozen_string_literal: true

# What have they done to the Gemfile???
#
# Relax. Breathe deep. All the gems are still there; they're just loaded in
# various files in Gemfile.d/. This allows us to require gems locally that we
# might not want to commit to our public repo. We can maintain a customized
# list of gems for development and debuggery, without affecting our ability to
# merge with canvas-lms
#
# NOTE: some files in Gemfile.d/ will have certain required gems indented.
# While this may seem arbitrary, it actually has semantic significance. An
# indented gem required in Gemfile is a gem that is NOT directly used by
# Canvas, but required by a gem that is used by Canvas. We lock into specific
# versions of these gems to prevent regression, and the indentation serves to
# alert us to the relationship between the gem and canvas-lms

source "https://rubygems.org/"

plugin "bundler_lockfile_extensions", path: "gems/bundler_lockfile_extensions"

# Bundler's first pass parses the entire Gemfile and calls to additional sources
# makes it actually go and retrieve metadata from them even though the plugin will
# never exist there. Short-circuit it here if we're in the plugin-specific DSL
# phase to prevent that from happening.
return if method(:source).owner == ::Bundler::Plugin::DSL

require File.expand_path("config/canvas_rails_switcher", __dir__)

if Plugin.installed?('bundler_lockfile_extensions')
  Plugin.send(:load_plugin, 'bundler_lockfile_extensions') if !defined?(BundlerLockfileExtensions)

  # Specifically exclude private plugins + private sources so that we can share a Gemfile.lock
  # with OSS users without needing to encrypt / put it in a different repo. In order to actually
  # pin any plugin-specific dependencies, the following constraints are introduced:
  #
  # 1. All dependencies under a private source must be pinned in the private plugin gemspec
  # 2. All sub-dependencies of (1) must be pinned in plugins.rb
  # 3. All additional public dependencies of private plugins must be pinned in plugins.rb
  #
  install_filter = lambda do |lockfile, source|
    return false if (
      source.to_s.match(/plugins\/(?!academic_benchmark|account_reports|moodle_importer|qti_exporter|respondus_soap_endpoint|simply_versioned)/)
    )

    source_md5 = ::Digest::MD5.hexdigest(source.to_s)

    return false if (
      source_md5 == "52288aac483aed012b58e6707e1660a5" || # rubygems repository <redacted>
      source_md5 == "252f6aa6a56f69f01f8a19275e91f0d8" # rubygems repository <redacted> or installed locally
    )

    true
  end

  base_gemfile = ENV.fetch("BUNDLE_GEMFILE", "Gemfile")
  lockfile_defs = SUPPORTED_VERSIONS.map do |x|
    prepare_environment = lambda do
      Object.send(:remove_const, :CANVAS_RAILS)
      ::CANVAS_RAILS = x
    end

    ["#{base_gemfile}.rails#{x.delete(".")}.lock", {
      default: x == CANVAS_RAILS,
      install_filter: install_filter,
      prepare_environment: prepare_environment,
    }]
  end.to_h

  BundlerLockfileExtensions.enable(lockfile_defs)
end

Dir[File.join(File.dirname(__FILE__), "gems/plugins/*/Gemfile.d/_before.rb")].each do |file|
  eval(File.read(file), nil, file) # rubocop:disable Security/Eval
end

Dir.glob(File.join(File.dirname(__FILE__), "Gemfile.d", "*.rb")).sort.each do |file|
  eval(File.read(file), nil, file) # rubocop:disable Security/Eval
end
