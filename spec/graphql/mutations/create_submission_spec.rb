# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::CreateSubmission do
  before(:once) do
    course_with_student(active_all: true)
    @assignment =
      @course.assignments.create!(title: "Example Assignment", submission_types: "online_upload")
    @attachment1 = attachment_with_context(@student)
    @attachment2 = attachment_with_context(@student)
    @media_object =
      factory_with_protected_attributes(MediaObject, media_id: "m-123456", title: "neato-vid")
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
  end

  def mutation_str(
    annotatable_attachment_id: nil,
    assignment_id: @assignment.id,
    submission_type: "online_upload",
    body: nil,
    file_ids: [],
    media_id: nil,
    resource_link_lookup_uuid: nil,
    url: nil,
    student_id: nil
  )
    <<~GQL
      mutation {
        createSubmission(input: {
          #{"annotatableAttachmentId: \"#{annotatable_attachment_id}\"" if annotatable_attachment_id}
          assignmentId: "#{assignment_id}"
          submissionType: #{submission_type}
          #{"body: \"#{body}\"" if body}
          fileIds: #{file_ids}
          #{"mediaId: \"#{media_id}\"" if media_id}
          #{"resourceLinkLookupUuid: \"#{resource_link_lookup_uuid}\"" if resource_link_lookup_uuid}
          #{"url: \"#{url}\"" if url}
          #{"studentId: \"#{student_id}\"" if student_id}
        }) {
          submission {
            _id
            attempt
            attachments {
              _id
              displayName
            }
            body
            mediaObject {
              _id
              title
            }
            resourceLinkLookupUuid
            url
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "creates a new submission" do
    result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
    expect(result.dig(:data, :createSubmission, :submission, :_id)).to eq Submission.last.id.to_s
  end

  context "read permissions check" do
    it "returns an error if the assignment is unpublished" do
      @assignment.unpublish!
      result = run_mutation
      expect(result.dig(:errors, 0, :message)).to eq "not found"
    end
  end

  context "submit permissions check" do
    it "returns an error if the assignment is locked" do
      @assignment.update!(lock_at: 1.day.ago)
      result = run_mutation
      expect(result.dig(:errors, 0, :message)).to eq "not found"
    end
  end

  context "when the submission_type is student_annotation" do
    it "requires annotatable_attachment_id to be present" do
      result = run_mutation(submission_type: "student_annotation")
      error_message =
        "Student Annotation submissions require an annotatable_attachment_id to submit"
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq error_message
    end

    it "changes a CanvadocsAnnotationContext from draft attempt to the current attempt" do
      @assignment.update!(
        annotatable_attachment: @attachment,
        submission_types: "student_annotation"
      )
      submission = @assignment.submissions.find_by(user: @student)
      submission.update!(attempt: 7)
      annotation_context = submission.annotation_context(draft: true)
      result =
        run_mutation(
          annotatable_attachment_id: @attachment.id,
          submission_type: "student_annotation"
        )

      aggregate_failures do
        expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to be_nil
        expect(annotation_context.reload.submission_attempt).to be 8
      end
    end
  end

  context "when the submission_type is a media_recording" do
    it "returns an error if there is no media_id" do
      @assignment.update(submission_types: "media_recording")
      result = run_mutation(submission_type: "media_recording")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "media_recording submissions require a media_id to submit"
    end

    it "returns an error if the media_id does not match a media object" do
      @assignment.update(submission_types: "media_recording")
      result = run_mutation(submission_type: "media_recording", media_id: "not_a_media_id")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "The media_id does not correspond to an existing media object"
    end

    it "saves the media_object on the submission" do
      @assignment.update(submission_types: "media_recording")
      result = run_mutation(submission_type: "media_recording", media_id: @media_object.media_id)
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.workflow_state).to eq "submitted"
      media_object = submission.media_object
      expect(media_object.title).to eq @media_object.title
      expect(media_object.media_id).to eq @media_object.media_id
    end
  end

  context "when the submission_type is an online_upload" do
    specs_require_sharding
    it "returns an error if there are no attachments" do
      @assignment.update!(submission_types: "online_upload")
      result = run_mutation(submission_type: "online_upload")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "You must attach at least one file to this assignment"
    end

    it "returns an error if any of the file_ids are not found" do
      @assignment.update!(submission_types: "online_upload")
      id_offset = [@attachment1.id, @attachment2.id].max
      unaffiliated_ids = [id_offset + 1, id_offset + 2, id_offset + 3]
      result = run_mutation(submission_type: "online_upload", file_ids: unaffiliated_ids)
      expected_message =
        "No attachments found for the following ids: [#{unaffiliated_ids.map { |i| "\"#{i}\"" }.join(", ")}]"
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq expected_message
    end

    it "returns an error if the returned attachment does not have an allowed file extension" do
      @assignment.update!(submission_types: "online_upload", allowed_extensions: "allowed")
      result =
        run_mutation(submission_type: "online_upload", file_ids: [@attachment1.id, @attachment2.id])
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq "Invalid file type"
    end

    it "stores the correct attachments on the submission" do
      @assignment.update!(submission_types: "online_upload")
      result =
        run_mutation(submission_type: "online_upload", file_ids: [@attachment1.id, @attachment2.id])
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.workflow_state).to eq "submitted"

      ids = submission.attachment_ids.split(",")
      expect(
        ids.include?(result.dig(:data, :createSubmission, :submission, :attachments, 0, :_id))
      ).to be true
      expect(
        ids.include?(result.dig(:data, :createSubmission, :submission, :attachments, 1, :_id))
      ).to be true
    end

    it "allows cross-shard users to upload a group assignment" do
      group_model
      @assignment.update!(submission_types: "online_upload", group_category: @course.group_categories.create)
      @cross_shard_student = @shard2.activate { user_factory(name: "Shard2 User") }
      GroupMembership.create(user_id: @cross_shard_student.id, group_id: @group.id, workflow_state: "accepted")
      @attachment3 = attachment_with_context(@group)
      @course.enroll_user(@cross_shard_student, "StudentEnrollment", enrollment_state: "active")
      result = run_mutation({ submission_type: "online_upload", file_ids: [@attachment3.id], assignment_id: @assignment.id }, @cross_shard_student)
      expect(result.dig(:data, :createSubmission, :submission, :_id)).to eq Submission.last.id.to_s
    end

    it "allows cross-shard users to upload non-group assignments" do
      @assignment.update!(submission_types: "online_upload")
      @cross_shard_student = @shard2.activate { user_factory(name: "Shard2 User") }
      @attachment3 = attachment_with_context(@cross_shard_student)
      @course.enroll_user(@cross_shard_student, "StudentEnrollment", enrollment_state: "active")
      result = run_mutation({ submission_type: "online_upload", file_ids: [@attachment3.id], assignment_id: @assignment.id }, @cross_shard_student)
      expect(result.dig(:data, :createSubmission, :submission, :_id)).to eq Submission.last.id.to_s
    end

    it "logs as a proxy submission if student_id if provided" do
      teacher_role =
        Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      RoleOverride.create!(
        permission: "proxy_assignment_submission",
        enabled: true,
        role: teacher_role,
        account: @course.root_account
      )
      @assignment.update!(submission_types: "online_upload")
      result =
        run_mutation(
          {
            submission_type: "online_upload",
            student_id: @student.id,
            file_ids: [@attachment1.id]
          },
          @teacher
        )

      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.proxy_submitter).to eq @teacher
    end

    it "allows proxy submissions for cross-shard users" do
      teacher_role =
        Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      RoleOverride.create!(
        permission: "proxy_assignment_submission",
        enabled: true,
        role: teacher_role,
        account: @course.root_account
      )
      @cross_shard_student = @shard2.activate { user_factory(name: "Shard2 User") }
      @attachment3 = attachment_with_context(@cross_shard_student)
      @attachment3.save_shadow_record(target_shard: @shard2)
      @course.enroll_user(@cross_shard_student, "StudentEnrollment", enrollment_state: "active")
      @assignment.update!(submission_types: "online_upload")
      result =
        run_mutation(
          {
            submission_type: "online_upload",
            student_id: @cross_shard_student.id,
            file_ids: [@attachment3.id]
          },
          @teacher
        )
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))
      expect(submission.shard).not_to eq @cross_shard_student.shard
      expect(submission.proxy_submitter).to eq @teacher
    end

    it "requires proxy_assignment_submission to log a proxy submission" do
      # RoleOverride.create!(
      #   permission: 'proxy_assignment_submission',
      #   enabled: true,
      #   role: teacher_role,
      #   account: @course.root_account
      # )
      RoleOverride.where(permission: "proxy_assignment_submission").destroy_all
      @assignment.update!(submission_types: "online_upload")
      result =
        run_mutation(
          {
            submission_type: "online_upload",
            student_id: @student.id,
            file_ids: [@attachment1.id]
          },
          @teacher
        )

      submission = Submission.find_by(id: result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission).to be_nil
    end
  end

  context "when the submission_type is an online_text_entry" do
    it "returns an error if the body is not provided" do
      @assignment.update!(submission_types: "online_text_entry")
      result = run_mutation(submission_type: "online_text_entry")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "Text entry submission cannot be empty"
    end

    it "returns an error if the body is empty" do
      @assignment.update!(submission_types: "online_text_entry")
      result = run_mutation(submission_type: "online_text_entry", body: "")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "Text entry submission cannot be empty"
    end

    it "saves the body to the submission" do
      result = run_mutation(submission_type: "online_text_entry", body: "thundercougarfalconbird")
      @assignment.update!(submission_types: "online_text_entry")
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.workflow_state).to eq "submitted"
      expect(result.dig(:data, :createSubmission, :submission, :body)).to eq(
        "thundercougarfalconbird"
      )
    end
  end

  context "when the submission_type is online_url" do
    it "returns an error if the url is not provided" do
      @assignment.update!(submission_types: "online_url")
      result = run_mutation(submission_type: "online_url")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "URL entry submission cannot be empty"
    end

    it "returns an error if the url is not valid" do
      @assignment.update!(submission_types: "online_url")
      result = run_mutation(submission_type: "online_url", url: "not a valid url")
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq "is not a valid URL"
    end

    it "saves the url to the submission" do
      @assignment.update!(submission_types: "online_url")
      result = run_mutation(submission_type: "online_url", url: "http://www.google.com")
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.workflow_state).to eq "submitted"
      expect(result.dig(:data, :createSubmission, :submission, :url)).to eq "http://www.google.com"
    end
  end

  context "when the submission_type is basic_lti_launch" do
    it "saves the submission type as basic_lti_launch" do
      result = run_mutation(submission_type: "basic_lti_launch", url: "http://localhost/some-url")
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.submission_type).to eq "basic_lti_launch"
    end

    it "saves the url to the submission" do
      result = run_mutation(submission_type: "basic_lti_launch", url: "http://localhost/some-url")
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.url).to eq "http://localhost/some-url"
    end

    it "saves the resource_link_lookup_uuid to the submission" do
      uuid = SecureRandom.uuid
      result =
        run_mutation(
          resource_link_lookup_uuid: uuid,
          submission_type: "basic_lti_launch",
          url: "http://localhost/some-url"
        )
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))
      expect(submission.resource_link_lookup_uuid).to eq uuid
    end

    it "returns an error if no URL is provided" do
      result = run_mutation(submission_type: "basic_lti_launch")
      expect(
        result.dig(:data, :createSubmission, :errors, 0, :message)
      ).to eq "LTI submissions require a URL to submit"
    end

    it "returns an error if an invalid URL is provided" do
      result = run_mutation(submission_type: "basic_lti_launch", url: "bad url")
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq "is not a valid URL"
    end
  end

  it "respects assignment overrides for the given user" do
    @assignment.update!(lock_at: 1.day.ago)
    create_adhoc_override_for_assignment(@assignment, @student, { lock_at: 1.day.from_now })
    result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
    expect(result.dig(:data, :createSubmission, :submission, :_id)).to eq Submission.last.id.to_s
  end

  it "can do resubmissions" do
    (1..3).each do |i|
      result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
      expect(result.dig(:data, :createSubmission, :submission, :attempt)).to eq i
    end
  end

  it "returns a graceful error if the assignment is not found" do
    result = run_mutation(assignment_id: 12_345)
    expect(result.dig(:errors, 0, :message)).to eq "not found"
  end

  it "returns a graceful error if model validation failed" do
    @assignment.update!(allowed_attempts: 1)
    Submission.find_by(user_id: @student.id).update!(attempt: 1)
    result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
    expect(
      result.dig(:data, :createSubmission, :errors, 0, :message)
    ).to eq "you have reached the maximum number of allowed attempts for this assignment"
  end
end
