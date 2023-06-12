# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

describe BasicLTI::QuizzesNextSubmissionReverter do
  subject { described_class.new(submission, launch_url, -1) }

  before do
    course_model(workflow_state: "available")
    @root_account = @course.root_account
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    @course.update_attribute(:account, @account)
    @user = factory_with_protected_attributes(User, name: "some user", workflow_state: "registered")
    @course.enroll_student(@user)
  end

  let(:assignment) do
    @course.assignments.create!(
      {
        title: "value for title",
        description: "value for description",
        due_at: Time.zone.now + 1000,
        points_possible: "1.5",
        submission_types: "external_tool",
        external_tool_tag_attributes: { url: tool.url }
      }
    )
  end

  let(:tool) do
    @course.context_external_tools.create(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret", tool_id: "Quizzes 2")
  end

  describe "#revert_attempt (without unsubmitted padding version)" do
    let(:submission_version_data) do
      time_now = Time.zone.now
      [
        { score: 50, url: "http://url1", submitted_at: time_now - 10.days },
        { score: 25, url: "http://url2", submitted_at: time_now - 8.days },
        { score: 55, url: "http://url1", submitted_at: time_now - 9.days },
        { score: 75, url: "http://url3", submitted_at: time_now - 3.days }
      ]
    end

    let(:submission) do
      s = assignment.submissions.first || Submission.find_or_initialize_by(assignment:, user: @user)

      submission_version_data.each do |d|
        s.score = d[:score]
        s.submitted_at = d[:submitted_at]
        s.grader_id = -1
        s.url = d[:url]
        s.with_versioning(explicit: true) { s.save! }
      end
      s
    end

    context "without a submission" do
      let(:submission) { nil }
      let(:launch_url) { "http://url3" }

      it "does nothing to revert" do
        expect(subject).not_to receive(:version_to_be_reverted)
        subject.revert_attempt
        expect(subject.send(:valid_revert?)).to be_falsey
      end
    end

    context "with nil launch_url passed" do
      let(:launch_url) { nil }

      it "does nothing to revert" do
        expect(subject).not_to receive(:version_to_be_reverted)
        subject.revert_attempt
        expect(submission.score).to eq(75)
      end
    end

    context "when passed launch_url is not in submission history" do
      let(:launch_url) { "http://url4" }

      it "does nothing to revert" do
        expect(subject).not_to receive(:version_to_be_reverted)
        subject.revert_attempt
        expect(submission.score).to eq(75)
      end
    end

    context "when a submission has history versions" do
      let(:launch_url) { "http://url3" }

      it "creates a new version" do
        expect { subject.revert_attempt }.to change { submission.versions.count }.by(1)
      end

      it "maintains versions with expected data" do
        subject.revert_attempt
        expect(submission.versions.count).to be(submission_version_data.count + 1)
        versions = submission.versions.map(&:model).sort_by(&:submitted_at)
        data = submission_version_data.sort_by { |x| x[:submitted_at] }
        4.times do |i|
          d = data[i]
          v = versions[i]
          expect(d[:submitted_at]).to eq(v.submitted_at)
          expect(d[:score]).to eq(v.score)
          expect(d[:url]).to eq(v.url)
        end
        expect(versions.last.score).to be_nil
      end

      it "reverts submission to the last attempt" do
        subject.revert_attempt
        expect(submission.score).to eq(25)
      end
    end

    context "when it is a new submission with history from current attempt" do
      let(:submission_version_data) do
        time_now = Time.zone.now
        [
          { score: 75, url: "http://url3", submitted_at: time_now - 3.days }
        ]
      end

      let(:launch_url) { "http://url3" }

      it "has a nil score" do
        subject.revert_attempt
        expect(submission.score).to be_nil
      end

      it "reuses the last version (without creating a new version)" do
        subject.revert_attempt
        expect(submission.versions.count).to be(1)
      end
    end

    context "when it is a new submission without history" do
      let(:submission_version_data) { [] }

      let(:launch_url) { "http://url3" }

      it "has a nil score" do
        expect(submission.versions.count).to be(0)
        expect { subject.revert_attempt }.not_to change { submission.versions.count }
      end
    end
  end

  describe "#revert_attempt (with unsubmitted padding version)" do
    let(:submission_version_data) do
      time_now = Time.zone.now
      [
        { score: 50, url: "http://url1", submitted_at: time_now - 10.days },
        { score: 55, url: "http://url1", submitted_at: time_now - 9.days },
        { score: 75, url: "http://url1", submitted_at: time_now - 3.days }
      ]
    end

    let(:submission) do
      s = assignment.submissions.first || Submission.find_or_initialize_by(assignment:, user: @user)

      s.with_versioning(explicit: true) { s.save! }
      submission_version_data.each do |d|
        s.score = d[:score]
        s.submitted_at = d[:submitted_at]
        s.grader_id = -1
        s.url = d[:url]
        s.with_versioning(explicit: true) { s.save! }
      end
      s
    end

    context "when a submission has history versions" do
      let(:launch_url) { "http://url1" }

      it "creates a new version" do
        expect { subject.revert_attempt }.to change { submission.versions.count }.by(1)
      end

      it "has expected # of versions" do
        # 1 padding version (unsubmitted) + 3 actual versions
        expect(submission.versions.count).to be(4)
        subject.revert_attempt
        # the last of the 3 actual versions is reused as masking version
        # one new version to unsubmit the submission
        expect(submission.reload.versions.count).to be(5)
        expect(submission.submitted_at).to be_nil

        # make sure the last of the 3 actual versions is reused
        ver_minus_1 = submission.versions.current.previous
        ver = ver_minus_1.model
        expect(ver.score).to be_nil

        ver_minus_2 = ver_minus_1.previous
        ver = ver_minus_2.model
        expect(ver.score).to eq(55)

        ver_minus_3 = ver_minus_2.previous
        ver = ver_minus_3.model
        expect(ver.score).to eq(50)
      end
    end
  end
end
