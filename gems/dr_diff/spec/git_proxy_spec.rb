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
  describe GitProxy do
    describe ".files" do
      context "no sha is given during creation, and directory is dirty" do
        it "calls outstanding_change_files" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(true)
          expect(subject).to receive(:outstanding_change_files)
          subject.files
        end
      end

      context "no sha is given during creation, and directory is clean" do
        it "calls change_files" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(false)
          expect(subject).to receive(:change_files)
          subject.files
        end
      end

      context "a sha is given during creation" do
        it "calls change_files" do
          subject = described_class.new(sha: "12345")
          expect(subject).to receive(:change_files)
          subject.files
        end
      end
    end

    describe ".diff" do
      context "no sha is given during creation, and directory is dirty" do
        it "calls outstanding_change_diff" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(true)
          expect(subject).to receive(:outstanding_change_diff)
          subject.diff
        end
      end

      context "no sha is given during creation, and directory is clean" do
        it "calls outstanding_change_diff" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(false)
          expect(subject).to receive(:change_diff)
          subject.diff
        end
      end

      context "a sha is given during creation" do
        it "calls change_diff" do
          subject = described_class.new(sha: "12345")
          expect(subject).to receive(:change_diff)
          subject.diff
        end
      end
    end

    describe ".wip?" do
      let(:git_proxy) { described_class.new }

      context "first line starts with wip" do
        let(:first_line) { "[WIP] foobar" }

        before do
          allow(git_proxy).to receive(:first_line).and_return(first_line)
        end

        it "returns true" do
          expect(git_proxy.wip?).to be_truthy
        end
      end

      context "first line does not starts with wip" do
        let(:first_line) { "foobar wip yo" }

        before do
          allow(git_proxy).to receive(:first_line).and_return(first_line)
        end

        it "returns false" do
          expect(git_proxy.wip?).to be_falsey
        end
      end
    end

    describe ".changes" do
      let(:git_proxy) { described_class.new(sha: "12443") }
      let(:change_path) { "path/to/some/modified/file" }
      let(:change_status) { "M" }
      let(:change_status_full) { "modified" }
      let(:change_output) { [change_status, change_path].join("\t") }

      it "creates changes from the status and path" do
        allow(git_proxy).to receive(:shell).and_return(change_output)

        results = git_proxy.changes
        expect(results.size).to eq(1)
        change = results.first
        expect(change.path).to eq(change_path)
        expect(change.status).to eq(change_status_full)
      end

      context "dirty" do
        let(:git_proxy) { described_class.new }
        let(:dirty_cmd) { "git diff --name-status" }

        before do
          allow_any_instance_of(described_class).to receive(:dirty?).and_return(true)
        end

        it "uses the dirty command" do
          expect(git_proxy).to receive(:shell)
            .with(dirty_cmd)
            .and_return("")
          git_proxy.changes
        end
      end

      context "not dirty" do
        let(:sha) { "12345abc" }
        let(:git_proxy) { described_class.new(sha:) }
        let(:clean_cmd) { "git diff-tree --no-commit-id --name-status -r #{sha}" }

        before do
          allow(git_proxy).to receive(:dirty?).and_return(false)
        end

        it "uses the clean command" do
          expect(git_proxy).to receive(:shell)
            .with(clean_cmd)
            .and_return("")
          git_proxy.changes
        end
      end
    end
  end
end
