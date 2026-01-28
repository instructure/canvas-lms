# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe DataFixup::SetAttachmentIdOnMediaRecordingSubmissions do
  let(:course) { course_factory(active_course: true) }
  let(:student) { user_factory(active_all: true) }
  let(:assignment) { course.assignments.create!(workflow_state: "published") }

  before do
    course.enroll_student(student, enrollment_state: "active")
  end

  def execute_fixup
    fixup = described_class.new
    fixup.run
    run_jobs
  end

  describe "#run" do
    it "sets attachment_id on media_recording submissions with missing attachment_id" do
      attachment = attachment_model(context: student)
      media_object = MediaObject.create!(
        user: student,
        context: course,
        media_id: "test_media_123",
        media_type: "video",
        attachment_id: attachment.id
      )

      submission = assignment.find_or_create_submission(student)
      submission.update_columns(
        submission_type: "media_recording",
        media_comment_id: media_object.media_id,
        media_object_id: media_object.id,
        attachment_id: nil,
        workflow_state: "submitted"
      )

      expect { execute_fixup }.to change { submission.reload.attachment_id }.from(nil).to(attachment.id)
    end

    it "creates attachment association after setting attachment_id" do
      attachment = attachment_model(context: student)
      media_object = MediaObject.create!(
        user: student,
        context: course,
        media_id: "test_media_234",
        media_type: "video",
        attachment_id: attachment.id
      )

      submission = assignment.find_or_create_submission(student)
      submission.update_columns(
        submission_type: "media_recording",
        media_comment_id: media_object.media_id,
        media_object_id: media_object.id,
        attachment_id: nil,
        workflow_state: "submitted"
      )

      expect(submission.reload.attachment_associations.where(attachment_id: attachment.id)).to be_empty

      execute_fixup

      expect(submission.reload.attachment_associations.where(attachment_id: attachment.id)).to exist
    end

    it "skips submissions without media_object" do
      submission = assignment.find_or_create_submission(student)
      submission.update_columns(
        submission_type: "media_recording",
        media_comment_id: "fake_media_id",
        media_object_id: nil,
        attachment_id: nil,
        workflow_state: "submitted"
      )

      expect { execute_fixup }.not_to change { submission.reload.attachment_id }
    end

    it "sets attachment_id on the most recent submission version" do
      attachment = attachment_model(context: student)
      media_object = MediaObject.create!(
        user: student,
        context: course,
        media_id: "test_media_345",
        media_type: "video",
        attachment_id: attachment.id
      )

      submission = assignment.find_or_create_submission(student)
      submission.update_columns(
        submission_type: "media_recording",
        media_comment_id: media_object.media_id,
        media_object_id: media_object.id,
        attachment_id: nil,
        workflow_state: "submitted"
      )
      submission.update(score: 1)

      versions = submission.reload.versions
      expect(versions.length).to eq(1)
      expect(versions.first.model.attachment_id).to be_nil

      execute_fixup

      versions = submission.reload.versions
      expect(versions.length).to eq(1)
      expect(versions.first.model.attachment_id).to eq(attachment.id)
    end

    it "sets attachment_id for all existing submission versions" do
      attachment1 = attachment_model(context: student)
      media_object1 = MediaObject.create!(
        user: student,
        context: course,
        media_id: "test_media_456",
        media_type: "video",
        attachment_id: attachment1.id
      )

      attachment2 = attachment_model(context: student)
      media_object2 = MediaObject.create!(
        user: student,
        context: course,
        media_id: "test_media_567",
        media_type: "video",
        attachment_id: attachment2.id
      )

      attachment3 = attachment_model(context: student)
      media_object3 = MediaObject.create!(
        user: student,
        context: course,
        media_id: "test_media_678",
        media_type: "video",
        attachment_id: attachment3.id
      )

      assignment.submit_homework(student, submission_type: "media_recording", media_comment_id: media_object1.media_id)
      assignment.submit_homework(student, submission_type: "media_recording", media_comment_id: media_object2.media_id)
      assignment.submit_homework(student, submission_type: "media_recording", media_comment_id: media_object3.media_id)

      submission = assignment.submissions.find_by(user: student)
      submission.update_columns(attachment_id: nil)

      submission.versions.all.each do |version|
        model = version.model
        model.attachment_id = nil
        version.model = model
        version.update_column(:yaml, version.yaml)
      end

      versions = submission.reload.versions
      expect(versions.length).to eq(3)
      expect(versions.all? { |v| v.model.attachment_id.nil? }).to be true

      ActiveRecord::Base.transaction { execute_fixup }

      versions = submission.reload.versions
      expect(versions.length).to eq(3)
      expect(versions[2].model.attachment_id).to eq(attachment1.id)
      expect(versions[1].model.attachment_id).to eq(attachment2.id)
      expect(versions[0].model.attachment_id).to eq(attachment3.id)
    end
  end
end
