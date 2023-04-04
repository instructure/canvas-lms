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
  it "generates a default Gemfile.lock when loaded, but not configured" do
    contents = <<-RUBY
      gem "concurrent-ruby", "1.2.0"
    RUBY

    with_gemfile(contents) do |file|
      output = invoke_bundler("install", file.path)

      expect(output).to include("1.2.0")
      expect(File.read("#{file.path}.lock")).to include("1.2.0")
    end
  end

  it "generates custom lockfiles with varying versions and excluded gems" do
    contents = <<-RUBY
      unless BundlerLockfileExtensions.enabled?
        BundlerLockfileExtensions.enable({
          "\#{__FILE__}.old.lock": {
            default: true,
            prepare_environment: -> { ::GEM_VERSION = "1.1.10" },
          },
          "\#{__FILE__}.new.lock": {
            default: false,
            prepare_environment: -> { ::GEM_VERSION = "1.2.0" },
          },
        })
      end

      gem "concurrent-ruby", ::GEM_VERSION
    RUBY

    with_gemfile(contents) do |file|
      output = invoke_bundler("install", file.path)

      expect(output).to include("1.1.10")
      expect(File.read("#{file.path}.old.lock")).to include("1.1.10")
      expect(File.read("#{file.path}.new.lock")).to include("1.2.0")
    end
  end

  it "generates lockfiles with a subset of gems" do
    contents = <<-RUBY
      unless BundlerLockfileExtensions.enabled?
        BundlerLockfileExtensions.enable({
          "\#{__FILE__}.lock": {
            default: true,
            install_filter: lambda { |_, x| !x.to_s.include?("test_local") },
          },
        })
      end

      gem "test_local", path: "test_local"
      gem "concurrent-ruby", "1.2.0"
    RUBY

    with_gemfile(contents) do |file, dir|
      create_local_gem(dir, "test_local", "")

      invoke_bundler("install", file.path)

      expect(File.read("#{file.path}.lock")).to include("test_local")
      expect(File.read("#{file.path}.lock.partial")).not_to include("test_local")

      expect(File.read("#{file.path}.lock")).to include("concurrent-ruby")
      expect(File.read("#{file.path}.lock.partial")).to include("concurrent-ruby")
    end
  end

  it "regenerates the lockfile when a source is completely removed and its dependencies no longer exist" do
    contents = <<-RUBY
      unless BundlerLockfileExtensions.enabled?
        BundlerLockfileExtensions.enable({
          "\#{__FILE__}.lock": {
            default: true,
            install_filter: lambda { |_, x| !x.to_s.include?("test_local") },
          },
        })
      end

      if ENV["USE_TEST_LOCAL_GEM"] == "1"
        gem "test_local", path: "test_local"
      end

      gem "concurrent-ruby", "1.2.0"
    RUBY

    with_gemfile(contents) do |file, dir|
      create_local_gem(dir, "test_local", <<-RUBY)
        spec.add_dependency "dummy", "0.9.6"
      RUBY

      invoke_bundler("install", file.path, env: { "USE_TEST_LOCAL_GEM" => "1" })

      expect(File.read("#{file.path}.lock")).to include("dummy")
      expect(File.read("#{file.path}.lock")).to include("test_local")
      expect(File.read("#{file.path}.lock.partial")).to include("dummy")
      expect(File.read("#{file.path}.lock.partial")).not_to include("test_local")

      invoke_bundler("install", file.path, env: { "USE_TEST_LOCAL_GEM" => "0" })

      expect(File.read("#{file.path}.lock")).not_to include("dummy")
      expect(File.read("#{file.path}.lock")).not_to include("test_local")
      expect(File.read("#{file.path}.lock.partial")).not_to include("dummy")
      expect(File.read("#{file.path}.lock.partial")).not_to include("test_local")
    end
  end

  it "fails if an additional lockfile contains an invalid gem" do
    contents = <<-RUBY
      unless BundlerLockfileExtensions.enabled?
        BundlerLockfileExtensions.enable({
          "\#{__FILE__}.old.lock": {
            default: true,
          },
          "\#{__FILE__}.new.lock": {
            default: false,
          },
        })
      end

      gem "concurrent-ruby", ">= 1.2.0"
    RUBY

    with_gemfile(contents) do |file|
      invoke_bundler("install", file.path)
      replace_gemfile_lock_pin("#{file.path}.new.lock", "concurrent-ruby", "9.9.9")

      expect { invoke_bundler("install", file.path) }.to raise_error(/concurrent-ruby\s+\(9\.9\.9\)\s+has\s+removed\s+it/m)
    end
  end

  # This section tests that the following constraint is adhered to:
  # 1. All dependencies under a private source must be pinned in the private plugin gemspec
  context "filtered dependency pins" do
    let(:gemfile_contents) do
      <<-RUBY
        unless BundlerLockfileExtensions.enabled?
          BundlerLockfileExtensions.enable({
            "\#{__FILE__}.v1.lock": {
              default: true,
              install_filter: lambda { |_, x| !x.to_s.include?("packagecloud") && !x.to_s.include?("test_local") },
              prepare_environment: -> { ::VERSION = "1" },
            },
            "\#{__FILE__}.v2.lock": {
              default: false,
              install_filter: lambda { |_, x| !x.to_s.include?("packagecloud") && !x.to_s.include?("test_local") },
              prepare_environment: -> { ::VERSION = "2" },
            },
          })
        end

        gem "test_local", path: "test_local"
        gem "concurrent-ruby", "1.2.0"

        eval(File.read("\#{__dir__}/test_local/Gemfile"))
      RUBY
    end

    let(:private_gemfile_contents) do
      <<-RUBY
        if ::VERSION == ENV["USE_VERSION"]
          source "https://packagecloud.io/instructure/rubygems-public/" do
            gem "hola", ">= 0.1.3"
          end
        end
      RUBY
    end

    it "fails if a filtered dependency isn't included in the gemspec" do
      with_gemfile(gemfile_contents) do |file, dir|
        create_local_gem(dir, "test_local", "")

        File.write("#{dir}/test_local/Gemfile", private_gemfile_contents)

        expect { invoke_bundler("install", file.path, env: { "USE_VERSION" => "1" }) }.to raise_error(/unable to prove that private gem hola was pinned/)
        expect { invoke_bundler("install", file.path, env: { "USE_VERSION" => "2" }) }.to raise_error(/unable to prove that private gem hola was pinned/)
      end
    end

    it "fails if a filtered dependency isn't pinned to an exact version in the gemspec" do
      with_gemfile(gemfile_contents) do |file, dir|
        create_local_gem(dir, "test_local", <<-RUBY)
          spec.add_dependency "dummy", ">= 0.9.6"
        RUBY

        File.write("#{dir}/test_local/Gemfile", private_gemfile_contents)

        expect { invoke_bundler("install", file.path, env: { "USE_VERSION" => "1" }) }.to raise_error(/unable to prove that private gem hola was pinned/)
        expect { invoke_bundler("install", file.path, env: { "USE_VERSION" => "2" }) }.to raise_error(/unable to prove that private gem hola was pinned/)
      end
    end
  end

  private

  def create_local_gem(dir, name, content)
    FileUtils.mkdir_p("#{dir}/#{name}")
    File.write("#{dir}/#{name}/#{name}.gemspec", <<-RUBY)
      Gem::Specification.new do |spec|
        spec.name          = "#{name}"
        spec.version       = "0.0.1"
        spec.authors       = ["Instructure"]
        spec.summary       = "for testing only"

        #{content}
      end
    RUBY
  end

  def with_gemfile(content)
    dir = Dir.mktmpdir
    file = Tempfile.new("Gemfile", dir).tap do |f|
      f.write(<<-RUBY)
        source "https://rubygems.org"
        plugin "bundler_lockfile_extensions", path: "#{File.dirname(__FILE__)}/.."
        Plugin.send(:load_plugin, 'bundler_lockfile_extensions') if Plugin.installed?('bundler_lockfile_extensions') && !defined?(BundlerLockfileExtensions)
        #{content}
      RUBY
      f.rewind
    end

    yield(file, dir)
  ensure
    FileUtils.remove_dir(dir, true)
  end

  def invoke_bundler(subcommand, gemfile_path, env: {})
    output = nil
    bundler_version = ENV.fetch("BUNDLER_VERSION")
    command = "bundle _#{bundler_version}_ #{subcommand}"
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e({ "BUNDLE_GEMFILE" => gemfile_path }.merge(env), command)

      raise "bundle #{subcommand} failed: #{output}" unless status.success?
    end
    output
  end

  def replace_gemfile_lock_pin(path, name, version)
    new_contents = File.read(path).gsub(%r{#{name} \([0-9.]+\)}, "#{name} (#{version})")

    File.write(path, new_contents)
  end
end
