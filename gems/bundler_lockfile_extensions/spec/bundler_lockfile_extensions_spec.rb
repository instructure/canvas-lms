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

require "tempfile"
require "open3"
require "fileutils"

require_relative "spec_helper"

describe "BundlerLockfileExtensions" do
  # the definition section for a gemfile with two lockfiles; one
  # that will have more gems than the default.
  let(:all_gems_definitions) do
    <<~RUBY
      add_lockfile(
        prepare: -> { ::INCLUDE_ALL_GEMS = false },
        current: false
      )
      add_lockfile(
        "Gemfile.full.lock",
        prepare: -> { ::INCLUDE_ALL_GEMS = true },
        current: true
      )
    RUBY
  end

  let(:all_gems_preamble) do
    "::INCLUDE_ALL_GEMS = true unless defined?(::INCLUDE_ALL_GEMS)"
  end

  it "generates a default Gemfile.lock when loaded, but not configured" do
    contents = <<~RUBY
      gem "concurrent-ruby", "1.2.2"
    RUBY

    with_gemfile("", contents) do
      output = invoke_bundler("install")

      expect(output).to include("1.2.2")
      expect(File.read("Gemfile.lock")).to include("1.2.2")
    end
  end

  it "disallows multiple default lockfiles" do
    with_gemfile(<<~RUBY) do
      add_lockfile()
      add_lockfile()
    RUBY
      expect { invoke_bundler("install") }.to raise_error(/Only one default lockfile/)
    end
  end

  it "disallows multiple current lockfiles" do
    with_gemfile(<<~RUBY) do
      add_lockfile(current: true)
      add_lockfile("Gemfile.new.lock", current: true)
    RUBY
      expect { invoke_bundler("install") }.to raise_error(/Only one lockfile/)
    end
  end

  it "generates custom lockfiles with varying versions" do
    definitions = <<~RUBY
      add_lockfile(
        prepare: -> { ::GEM_VERSION = "1.1.10" }
      )
      add_lockfile(
        "Gemfile.new.lock",
        prepare: -> { ::GEM_VERSION = "1.2.2" }
      )
    RUBY

    contents = <<~RUBY
      ::GEM_VERSION = "1.1.10" unless defined?(::GEM_VERSION)
      gem "concurrent-ruby", ::GEM_VERSION
    RUBY

    with_gemfile(definitions, contents) do
      invoke_bundler("install")

      expect(File.read("Gemfile.lock")).to include("1.1.10")
      expect(File.read("Gemfile.lock")).not_to include("1.2.2")
      expect(File.read("Gemfile.new.lock")).not_to include("1.1.10")
      expect(File.read("Gemfile.new.lock")).to include("1.2.2")
    end
  end

  it "generates lockfiles with a subset of gems" do
    contents = <<~RUBY
      if ::INCLUDE_ALL_GEMS
        gem "test_local", path: "test_local"
      end
      gem "concurrent-ruby", "1.2.2"
    RUBY

    with_gemfile(all_gems_definitions, contents, all_gems_preamble) do
      create_local_gem("test_local", "")

      invoke_bundler("install")

      expect(File.read("Gemfile.lock")).not_to include("test_local")
      expect(File.read("Gemfile.full.lock")).to include("test_local")

      expect(File.read("Gemfile.lock")).to include("concurrent-ruby")
      expect(File.read("Gemfile.full.lock")).to include("concurrent-ruby")
    end
  end

  it "fails if an additional lockfile contains an invalid gem" do
    definitions = <<~RUBY
      add_lockfile()
      add_lockfile(
        "Gemfile.new.lock"
      )
    RUBY

    contents = <<~RUBY
      gem "concurrent-ruby", ">= 1.2.2"
    RUBY

    with_gemfile(definitions, contents) do
      invoke_bundler("install")

      replace_lockfile_pin("Gemfile.new.lock", "concurrent-ruby", "9.9.9")

      expect { invoke_bundler("check") }.to raise_error(/concurrent-ruby.*does not match/m)
    end
  end

  it "preserves the locked version of a gem in an alternate lockfile when updating a different gem in common" do
    contents = <<~RUBY
      gem "net-ldap", "0.17.0"

      if ::INCLUDE_ALL_GEMS
        gem "net-smtp", "0.3.2"
      end
    RUBY

    with_gemfile(all_gems_definitions, contents, all_gems_preamble) do
      invoke_bundler("install")

      expect(invoke_bundler("info net-ldap")).to include("0.17.0")
      expect(invoke_bundler("info net-smtp")).to include("0.3.2")

      # loosen the requirement on both gems
      write_gemfile(all_gems_definitions, <<~RUBY, all_gems_preamble)
        gem "net-ldap", "~> 0.17"

        if ::INCLUDE_ALL_GEMS
          gem "net-smtp", "~> 0.3"
        end
      RUBY

      # but only update net-ldap
      invoke_bundler("update net-ldap")

      # net-smtp should be untouched, even though it's no longer pinned
      expect(invoke_bundler("info net-ldap")).not_to include("0.17.0")
      expect(invoke_bundler("info net-smtp")).to include("0.3.2")
    end
  end

  it "maintains consistency across multiple Gemfiles" do
    definitions = <<~RUBY
      add_lockfile()
      add_lockfile(
        "local_test/Gemfile.lock",
        gemfile: "local_test/Gemfile")
    RUBY

    contents = <<~RUBY
      gem "net-smtp", "0.3.2"
    RUBY

    with_gemfile(definitions, contents) do
      create_local_gem("local_test", <<~RUBY)
        spec.add_dependency "net-smtp", "~> 0.3"
      RUBY

      invoke_bundler("install")

      # locks to 0.3.2 in the local gem's lockfile, even though the local
      # gem itself would allow newer
      expect(File.read("local_test/Gemfile.lock")).to include("0.3.2")
    end
  end

  it "whines about non-pinned dependencies in flagged gemfiles" do
    definitions = <<~RUBY
      add_lockfile(
        prepare: -> { ::INCLUDE_ALL_GEMS = false },
        current: false
      )
      add_lockfile(
        "Gemfile.full.lock",
        prepare: -> { ::INCLUDE_ALL_GEMS = true },
        current: true,
        enforce_pinned_additional_dependencies: true
      )
    RUBY

    contents = <<~RUBY
      gem "net-ldap", "0.17.0"

      if ::INCLUDE_ALL_GEMS
        gem "net-smtp", "~> 0.3"
      end
    RUBY

    with_gemfile(definitions, contents, all_gems_preamble) do
      expect { invoke_bundler("install") }.to raise_error(/net-smtp \([0-9.]+\) in Gemfile.full.lock has not been pinned/)

      # not only have to pin net-smtp, but also its transitive dependencies
      write_gemfile(definitions, <<~RUBY, all_gems_preamble)
        gem "net-ldap", "0.17.0"

        if ::INCLUDE_ALL_GEMS
          gem "net-smtp", "0.3.2"
            gem "net-protocol", "0.2.1"
            gem "timeout", "0.3.2"
        end
      RUBY

      invoke_bundler("install") # no error, because it's now pinned
    end
  end

  context "with mismatched dependencies disallowed" do
    let(:all_gems_definitions) do
      <<~RUBY
        add_lockfile(
          prepare: -> { ::INCLUDE_ALL_GEMS = false },
          current: false
        )
        add_lockfile(
          "Gemfile.full.lock",
          prepare: -> { ::INCLUDE_ALL_GEMS = true },
          allow_mismatched_dependencies: false,
          current: true
        )
      RUBY
    end

    it "notifies about mismatched versions between different lockfiles" do
      contents = <<~RUBY
        if ::INCLUDE_ALL_GEMS
          gem "activesupport", "7.0.4.3"
        else
          gem "activesupport", "~> 6.1.0"
        end
      RUBY

      with_gemfile(all_gems_definitions, contents, all_gems_preamble) do
        expect { invoke_bundler("install") }.to raise_error(/activesupport \(7.0.4.3\) in Gemfile.full.lock does not match the default lockfile's version/)
      end
    end

    it "notifies about mismatched versions between different lockfiles for sub-dependencies" do
      definitions = <<~RUBY
        add_lockfile(
          prepare: -> { ::INCLUDE_ALL_GEMS = false },
          current: false
        )
        add_lockfile(
          "Gemfile.full.lock",
          prepare: -> { ::INCLUDE_ALL_GEMS = true },
          allow_mismatched_dependencies: false,
          current: true
        )
      RUBY

      contents = <<~RUBY
        gem "activesupport", "7.0.4.3" # depends on tzinfo ~> 2.0, so will get >= 2.0.6

        if ::INCLUDE_ALL_GEMS
          gem "tzinfo", "2.0.5"
        end
      RUBY

      with_gemfile(definitions, contents, all_gems_preamble) do
        expect { invoke_bundler("install") }.to raise_error(/tzinfo \(2.0.5\) in Gemfile.full.lock does not match the default lockfile's version/)
      end
    end
  end

  it "allows mismatched explicit dependencies by default" do
    contents = <<~RUBY
      if ::INCLUDE_ALL_GEMS
        gem "activesupport", "7.0.4.3"
      else
        gem "activesupport", "~> 6.1.0"
      end
    RUBY

    with_gemfile(all_gems_definitions, contents, all_gems_preamble) do
      invoke_bundler("install") # no error
      expect(File.read("Gemfile.lock")).to include("6.1.")
      expect(File.read("Gemfile.lock")).not_to include("7.0.4.3")
      expect(File.read("Gemfile.full.lock")).not_to include("6.1.")
      expect(File.read("Gemfile.full.lock")).to include("7.0.4.3")
    end
  end

  it "disallows mismatched implicit dependencies" do
    definitions = <<~RUBY
      add_lockfile()
      add_lockfile(
        "local_test/Gemfile.lock",
        allow_mismatched_dependencies: false,
        gemfile: "local_test/Gemfile")
    RUBY
    contents = <<~RUBY
      gem "activesupport", "7.0.4.3"
      gem "concurrent-ruby", "1.0.2"
    RUBY

    with_gemfile(definitions, contents) do
      create_local_gem("local_test", <<~RUBY)
        spec.add_dependency "activesupport", "7.0.4.3"
      RUBY

      expect { invoke_bundler("install") }.to raise_error(%r{concurrent-ruby \([0-9.]+\) in local_test/Gemfile.lock does not match the default lockfile's version \(@1.0.2\)})
    end
  end

  private

  def create_local_gem(name, content)
    FileUtils.mkdir_p(name)
    File.write("#{name}/#{name}.gemspec", <<~RUBY)
      Gem::Specification.new do |spec|
        spec.name          = #{name.inspect}
        spec.version       = "0.0.1"
        spec.authors       = ["Instructure"]
        spec.summary       = "for testing only"

        #{content}
      end
    RUBY

    File.write("#{name}/Gemfile", <<~RUBY)
      source "https://rubygems.org"

      gemspec
    RUBY
  end

  # creates a new temporary directory, writes the gemfile to it, and yields
  #
  # @param (see #write_gemfile)
  # @yield
  def with_gemfile(definitions, content = nil, preamble = nil)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        write_gemfile(definitions, content, preamble)

        invoke_bundler("config frozen false")

        yield
      end
    end
  end

  # @param definitions [String]
  #   Ruby code to set up lockfiles by calling add_lockfile. Called inside a
  #   conditional for when BundlerLockfileExtensions is loaded the first time.
  # @param content [String]
  #   Additional Ruby code for adding gem requirements to the Gemfile
  # @param preamble [String]
  #   Additional Ruby code to execute prior to installing the plugin.
  def write_gemfile(definitions, content = nil, preamble = nil)
    raise ArgumentError, "Did you mean to use `with_gemfile`?" if block_given?

    File.write("Gemfile", <<~RUBY)
      source "https://rubygems.org"

      #{preamble}

      plugin "bundler_lockfile_extensions", path: #{File.dirname(__dir__).inspect}
      if Plugin.installed?("bundler_lockfile_extensions")
        Plugin.send(:load_plugin, "bundler_lockfile_extensions") unless defined?(BundlerLockfileExtensions)

        unless BundlerLockfileExtensions.enabled?
          #{definitions}
        end
      end

      #{content}
    RUBY
  end

  # Shells out to a new instance of bundler, with a clean bundler env
  #
  # @param subcommand [String] Args to pass to bundler
  # @raise [RuntimeError] if the bundle command fails
  def invoke_bundler(subcommand, env: {})
    output = nil
    bundler_version = ENV.fetch("BUNDLER_VERSION")
    command = "bundle _#{bundler_version}_ #{subcommand}"
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e(env, command)

      raise "bundle #{subcommand} failed: #{output}" unless status.success?
    end
    output
  end

  # Directly modifies a lockfile to adjust the version of a gem
  #
  # Useful for simulating certain unusual situations that can arise.
  #
  # @param lockfile [String] The lockfile's location
  # @param gem [String] The gem's name
  # @param version [String] The new version to "pin" the gem to
  def replace_lockfile_pin(lockfile, gem, version)
    new_contents = File.read(lockfile).gsub(%r{#{gem} \([0-9.]+\)}, "#{gem} (#{version})")

    File.write(lockfile, new_contents)
  end
end
