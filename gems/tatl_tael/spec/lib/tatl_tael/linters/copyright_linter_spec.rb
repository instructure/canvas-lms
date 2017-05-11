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

require 'spec_helper'
require_relative "./shared_constants"
require_relative "./shared_linter_examples"
# pp required for to make fakefs happy, see:
# github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file
require 'pp'
require 'fakefs/safe'

describe TatlTael::Linters::CopyrightLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }
  let(:status) { "added" }
  let(:raw_changes) do
    [
      {
        path: fixture_path,
        path_from_root: fixture_path,
        status: status
      }
    ]
  end
  let(:changes) { raw_changes.map { |c| double(c) } }
  let(:linter) { described_class.new(changes: changes, config: config) }
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

  context "whitelisted file" do
    # doesn't need to exist cuz it'll be ignored before attempting to read
    let(:fixture_path) { Consts::PUBLIC_VENDOR_JS_PATH }
    include_examples "does not comment"
  end

  context "included file" do
    FIXTURE_BASE = File.expand_path("../fixtures/copyright_linter/", __FILE__)
    def fixture_path_for(type, file_name)
      File.expand_path("../fixtures/copyright_linter/#{type}/#{file_name}.#{type}", __FILE__)
    end

    # TL;DR: for each file in spec/lib/tatl_tael/linters/fixtures/copyright_linter:
    #        if file's name starts with "valid", verify the linter does NOT comment.
    #        else, verify the linter DOES comment.
    #
    # found an edge case that needs verification?
    # create a new file in the appropriate fixture directory named:
    # "invalid--some-variant-name.ext" where "some-variant-name" is why it's invalid
    # and "ext" is extension (e.g. coffee).
    Dir.chdir(FIXTURE_BASE) do
      Dir.glob('*').each do |fixture_base_type| # e.g. "coffee"
        Dir.chdir(fixture_base_type) do
          context fixture_base_type do # e.g. context "coffee" do
            Dir.glob('*').each do |fixture_variant| # e.g. "invalid--missing.coffee"
              fixture_variant_name = fixture_variant.split(".").first # e.g. "invalid--missing"
              context fixture_variant_name do # e.g. context "invalid--missing" do
                let(:fixture_path) { fixture_variant }

                around(:each) do |example|
                  # cache linter config so we don't have to clone it into the fake fs
                  TatlTael::Linters.config
                  FakeFS do
                    example.run
                  end
                end

                before :each do
                  real_path = fixture_path_for(fixture_base_type, fixture_variant_name)
                  # clone the fixture into empty/fake fs
                  FakeFS::FileSystem.clone(real_path, fixture_variant)
                end

                expected_to_be_valid = fixture_variant_name.split("--").first == "valid"
                if expected_to_be_valid
                  include_examples "does not comment"
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
