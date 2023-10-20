# frozen_string_literal: true

# Copyright (C) 2017 - present Instructure, Inc.
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

require "spec_helper"
require_relative "shared_constants"
require_relative "shared_linter_examples"
# pp required for to make fakefs happy, see:
# github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file
require "fakefs/safe"
require "timecop"

FIXTURE_BASE = File.expand_path("fixtures/copyright_linter/", __dir__)

describe TatlTael::Linters::CopyrightLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }
  let(:status) { "added" }
  let(:raw_changes) do
    [
      {
        path: fixture_path,
        path_from_root: fixture_path,
        status:
      }
    ]
  end
  let(:changes) { raw_changes.map { |c| double(c) } }
  let(:linter) { described_class.new(changes:, config:) }
  let(:linter_with_auto_correct) do
    described_class.new(changes:, config:, auto_correct: true)
  end
  let(:comment) do
    {
      path: fixture_path,
      message: config[:message],
      severity: config[:severity],
      position: 0
    }
  end

  shared_examples "does not comment" do
    it "does not comment" do
      expect(linter.run).to be_empty
    end
  end

  shared_examples "comments" do
    it "comments" do
      expect(linter.run.first).to match(hash_including(comment))
    end
  end

  def fixture_path_for(type, file_name)
    File.expand_path("../fixtures/copyright_linter/#{type}/#{file_name}.#{type}", __FILE__)
  end
  shared_examples "comments and auto corrects" do
    let(:linter) { linter_with_auto_correct }
    let(:comment) do
      {
        path: fixture_path,
        message: config[:auto_correct][:message],
        severity: config[:severity],
        position: 0
      }
    end
    include_examples "comments"

    it "auto corrects" do
      linter.run
      path = changes.first.path
      path_parts = path.split(".")
      type = path_parts.last
      corrected_path = [path_parts.first, "--auto-corrected"].join

      # copy the corrected fixture into our fake fs
      real_path = fixture_path_for(type, corrected_path)
      FakeFS::FileSystem.clone(real_path, corrected_path)

      # verify that the original path's contents now match the corrected fixture
      path_contents = File.read(path)
      corrected_path_contents = File.read(corrected_path)
      expect(path_contents).to eq(corrected_path_contents)
    end
  end

  shared_examples "raises during auto correct" do
    let(:linter) { linter_with_auto_correct }
    it "raises" do
      expect { linter.run }.to raise_error(/FOUND TWO COPYRIGHT LINES/)
    end
  end

  context "allowed file" do
    # doesn't need to exist cuz it'll be ignored before attempting to read
    let(:fixture_path) { Consts::PUBLIC_VENDOR_JS_PATH }

    include_examples "does not comment"
  end

  context "included file" do
    # TL;DR: for each file in spec/lib/tatl_tael/linters/fixtures/copyright_linter:
    #        if file's name starts with "valid", verify the linter does NOT comment.
    #        else, verify the linter DOES comment.
    #
    #        additionally, if the fixture name has the "--auto-corrected" suffix,
    #        it'll be ignored. the un-auto-corrected fixture will be auto-corrected
    #        and verified that its new contents match the auto-corrected fixture.
    #
    # found an edge case that needs verification?
    # create a new file in the appropriate fixture directory named:
    # "invalid--some-variant-name.ext" where "some-variant-name" is why it's invalid
    # and "ext" is extension (e.g. coffee).
    Dir.chdir(FIXTURE_BASE) do
      Dir.glob("*").each do |fixture_base_type| # e.g. "coffee"
        Dir.chdir(fixture_base_type) do
          context fixture_base_type do # e.g. context "coffee" do
            Dir.glob("*").each do |fixture_variant| # e.g. "invalid--missing.coffee"
              fixture_variant_name = fixture_variant.split(".").first # e.g. "invalid--missing"
              next if fixture_variant_name.split("--").last == "auto-corrected"

              context fixture_variant_name do # e.g. context "invalid--missing" do
                let(:fixture_path) { fixture_variant }

                around do |example|
                  # cache linter config so we don't have to clone it into the fake fs
                  TatlTael::Linters.config
                  FakeFS do
                    FileUtils.mkdir_p("/tmp") # to make Tempfile happy
                    Timecop.freeze(Time.local(2017, 5, 5), &example)
                  end
                end

                before do
                  real_path = fixture_path_for(fixture_base_type, fixture_variant_name)
                  # clone the fixture into empty/fake fs
                  FakeFS::FileSystem.clone(real_path, fixture_variant)
                end

                expected_to_be_valid = fixture_variant_name.split("__").first == "valid"
                auto_correct_version_exists = File.exist?("#{fixture_variant_name}--auto-corrected.#{fixture_base_type}")
                expected_to_raise = fixture_variant_name.split("--").last == "raises"
                if expected_to_be_valid
                  include_examples "does not comment"
                elsif auto_correct_version_exists
                  if expected_to_raise
                    include_examples "raises during auto correct"
                  else
                    include_examples "comments and auto corrects"
                  end
                else
                  include_examples "comments"
                end
              end
            end
          end
        end
      end
    end
  end
end
