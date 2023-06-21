# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DrDiff
  describe Manager do
    describe ".files" do
      let(:git_files_output) do
        %(lib/dr_diff.rb
spec/dr_diff_spec.rb)
      end

      let(:file_list) { git_files_output.split("\n") }

      before do
        allow(File).to receive(:exist?).and_return(true)
      end

      it "excludes files that do not exist" do
        git = double("git", files: git_files_output + "\nREADME.md")
        subject = described_class.new(git:)
        allow(File).to receive(:exist?).with("README.md").and_return(false)
        expect(subject.files).to eq(file_list)
      end

      context "regex is given" do
        let(:git) { double("git", files: git_files_output + "\nbuild.js") }
        let(:subject) { described_class.new(git:) }
        let(:ruby_regex) { /\.rb$/ }

        it "excludes files do not match the regex" do
          expect(subject.files(ruby_regex)).to eq(file_list)
        end
      end

      context "git_dir is given" do
        let(:git_dir) { "some/path/" }
        let(:git) { double("git", files: git_files_output) }
        let(:subject) { described_class.new(git:, git_dir:) }

        it "prepends the results with the git_dir" do
          expect(subject.files(/\.rb$/)).to eq(file_list.map { |f| git_dir + f })
        end
      end
    end

    describe ".comments" do
      let(:format) { "rubocop" }
      let(:command) { "rubocop" }
      let(:diff_parser) { double("diff parser") }
      let(:command_capture) { double("command capture") }
      let(:git) { double("git", diff: "diff") }
      let(:subject) { described_class.new(git:) }

      let(:command_capture_comments) do
        [
          { path: "gems/plugins/custom_reports/lib/custom_reports.rb",
            message: "[rubocop] Avoid using sleep.\n\n       sleep 1\n       ^^^^^^^\n",
            position: 5,
            severity: "convention" }
        ]
      end

      before do
        expect(DiffParser).to receive(:new).with(git.diff, raw: true, campsite: true).and_return(diff_parser)
        expect(CommandCapture).to receive(:run).with(format, command).and_return(command_capture_comments)
        allow(diff_parser).to receive(:relevant?).and_return(true)
      end

      it "returns all relevant comments" do
        result = subject.comments(format:, command:)
        expect(result.length).to eq(1)
      end

      it "does not return irrelevant comments" do
        allow(diff_parser).to receive(:relevant?).and_return(false)
        result = subject.comments(format:, command:)
        expect(result.length).to eq(0)
      end

      context "git_dir exists" do
        let(:git_dir) { "gems/plugins/custom_reports/" }
        let(:subject) { described_class.new(git:, git_dir:) }

        it "removes git_dir from path when determining if relevant" do
          comment = command_capture_comments.first
          path_without_git_dir = comment[:path][git_dir.length..]
          expect(diff_parser).to receive(:relevant?).with(path_without_git_dir,
                                                          comment[:position],
                                                          severe: false)
          subject.comments(format:, command:)
        end

        context "include_git_dir_in_output is true" do
          it "includes the git_dir in the output" do
            full_comment_path = command_capture_comments.first[:path]
            result = subject.comments(format:, command:, include_git_dir_in_output: true)
            expect(result.first[:path]).to eq(full_comment_path)
          end
        end

        context "include_git_dir_in_output is false" do
          it "does not include the git_dir in the output" do
            full_comment_path = command_capture_comments.first[:path]
            comment_path_without_git_dir = full_comment_path[git_dir.length..]
            result = subject.comments(format:, command:)
            expect(result.first[:path]).to eq(comment_path_without_git_dir)
          end
        end
      end

      context "git_dir does not exist" do
        let(:subject) { described_class.new(git:) }

        it "passes the entire comment path in to determine if it is relevant" do
          comment = command_capture_comments.first
          expect(diff_parser).to receive(:relevant?).with(comment[:path],
                                                          comment[:position],
                                                          severe: false)
          subject.comments(format:, command:)
        end
      end
    end
  end
end
