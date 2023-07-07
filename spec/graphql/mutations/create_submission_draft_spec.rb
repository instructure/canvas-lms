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

RSpec.describe Mutations::CreateSubmissionDraft do
  specs_require_sharding
  before(:once) do
    @submission = submission_model
    @attachments = [
      attachment_with_context(@student),
      attachment_with_context(@student)
    ]
    @media_object = factory_with_protected_attributes(MediaObject, media_id: "m-123456")
  end

  def mutation_str(
    submission_id: @submission.id,
    active_submission_type: nil,
    attempt: nil,
    body: nil,
    external_tool_id: nil,
    file_ids: [],
    lti_launch_url: nil,
    media_id: nil,
    resource_link_lookup_uuid: nil,
    url: nil
  )
    <<~GQL
      mutation {
        createSubmissionDraft(input: {
          submissionId: "#{submission_id}"
          #{"activeSubmissionType: #{active_submission_type}" if active_submission_type}
          #{"attempt: #{attempt}" if attempt}
          #{"body: \"#{body}\"" if body}
          #{"externalToolId: \"#{external_tool_id}\"" if external_tool_id}
          fileIds: #{file_ids}
          #{"ltiLaunchUrl: \"#{lti_launch_url}\"" if lti_launch_url}
          #{"mediaId: \"#{media_id}\"" if media_id}
          #{"resourceLinkLookupUuid: \"#{resource_link_lookup_uuid}\"" if resource_link_lookup_uuid}
          #{"url: \"#{url}\"" if url}
        }) {
          submissionDraft {
            _id
            submissionAttempt
            activeSubmissionType
            attachments {
              _id
              displayName
            }
            body
            externalTool {
              _id
            }
            ltiLaunchUrl
            mediaObject {
              _id
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
    result = CanvasSchema.execute(mutation_str(**opts), context: { current_user:, request: ActionDispatch::TestRequest.create })
    result.to_h.with_indifferent_access
  end

  context "when an attachment has been replaced" do
    before do
      @attachments.first.update!(file_state: "deleted", replacement_attachment: @attachments.second)
    end

    it "returns the replacing attachment if the requested attachment has been replaced" do
      result = run_mutation(
        submission_id: @submission.id,
        active_submission_type: "online_upload",
        attempt: @submission.attempt,
        file_ids: [@attachments.first.id]
      )

      expect(
        result.dig(:data, :createSubmissionDraft, :errors)
      ).to be_nil

      expect(
        result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments, 0, :_id)
      ).to eq @attachments.second.id.to_s
    end

    it "does not return duplicates when a replacing attachment and replaced attachment are both requested" do
      result = run_mutation(
        submission_id: @submission.id,
        active_submission_type: "online_upload",
        attempt: @submission.attempt,
        file_ids: @attachments.pluck(:id)
      )

      expect(
        result.dig(:data, :createSubmissionDraft, :errors)
      ).to be_nil

      expect(
        result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).length
      ).to eq 1

      expect(
        result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments, 0, :_id)
      ).to eq @attachments.second.id.to_s
    end

    it "does not fetch attachments with the same local ID, but on different shard, from requested attachments" do
      @student.associate_with_shard(@shard1)

      @shard1.activate do
        @not_requested_attachment = attachment_with_context(@student)
        @not_requested_attachment.update!(id: @attachments.second.local_id)
      end

      result = run_mutation(
        submission_id: @submission.id,
        active_submission_type: "online_upload",
        attempt: @submission.attempt,
        file_ids: @attachments.pluck(:id)
      )

      returned_attachment_ids = result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).pluck("_id")
      expect(returned_attachment_ids).not_to include @not_requested_attachment.global_id.to_s
    end
  end

  it "creates a new submission draft" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: @submission.attempt,
      file_ids: @attachments.map(&:id)
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :_id)
    ).to eq SubmissionDraft.last.id.to_s
  end

  it "updates an existing submission draft" do
    first_result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: @submission.attempt,
      file_ids: @attachments.map(&:id)
    )
    attachment_ids = first_result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).pluck(:_id)
    expect(attachment_ids.count).to eq 2
    @attachments.each do |attachment|
      expect(attachment_ids.include?(attachment[:id].to_s)).to be true
    end

    second_result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: @submission.attempt,
      file_ids: [@attachments[0].id]
    )
    attachment_ids = second_result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).pluck(:_id)
    expect(attachment_ids.count).to eq 1
    expect(attachment_ids[0]).to eq @attachments[0].id.to_s

    expect(
      first_result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
    ).to eq second_result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
  end

  it "allows you to set a body on the submission draft" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_text_entry",
      attempt: @submission.attempt,
      body: "some text body"
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to eq "some text body"
  end

  it "allows you to set a url on the submission draft" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_url",
      attempt: @submission.attempt,
      url: "http://www.google.com"
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to eq "http://www.google.com"
  end

  it "allows you to set a media_object_id on the submission draft" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "media_recording",
      attempt: @submission.attempt,
      media_id: @media_object.media_id
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :mediaObject, :_id)
    ).to eq @media_object.media_id
  end

  it "allows you to set an active_submission_type on the submission draft" do
    result = run_mutation(
      active_submission_type: "online_text_entry",
      attempt: @submission.attempt,
      body: "some text body",
      submission_id: @submission.id
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :activeSubmissionType)
    ).to eq "online_text_entry"
  end

  it "only updates attachments when the active submission type is online_upload" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: @submission.attempt,
      body: "some text body",
      file_ids: @attachments.map(&:id)
    )
    attachment_ids = result.dig(:data, :createSubmissionDraft, :submissionDraft, :attachments).pluck(:_id)

    expect(attachment_ids.count).to eq 2
    @attachments.each do |attachment|
      expect(attachment_ids.include?(attachment[:id].to_s)).to be true
    end

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to be_nil
  end

  it "only updates the body when the active submission type is online_text_entry" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_text_entry",
      attempt: @submission.attempt,
      body: "some text body",
      url: "http://www.google.com"
    )

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to eq "some text body"

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to be_nil
  end

  it "only updates the url when the active submission type is online_url" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_url",
      attempt: @submission.attempt,
      body: "some text body",
      url: "http://www.google.com"
    )

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :body)
    ).to be_nil

    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to eq "http://www.google.com"
  end

  it "returns an error if the active submission type is not included" do
    result = run_mutation(
      attempt: @submission.attempt,
      body: "some text body",
      submission_id: @submission.id
    )
    expect(
      result.dig(:errors, 0, :message)
    ).to include "Argument 'activeSubmissionType' on InputObject 'CreateSubmissionDraftInput' is required"
  end

  it "returns an error if the active submission type is not valid" do
    result = run_mutation(
      active_submission_type: "thundercougarfalconbird",
      attempt: @submission.attempt,
      body: "some text body",
      submission_id: @submission.id
    )
    expect(
      result.dig(:errors, 0, :message)
    ).to include "Expected type 'DraftableSubmissionType!'"
  end

  it "prefixes the url with a scheme if missing" do
    @submission.assignment.update!(submission_types: "online_url")
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_url",
      attempt: @submission.attempt,
      url: "www.google.com"
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :url)
    ).to eq "http://www.google.com"
  end

  it "returns an error if the attachments are not owned by the user" do
    attachment = attachment_with_context(@teacher)
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: @submission.attempt,
      file_ids: [attachment.id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :errors, 0, :message)
    ).to eq "No attachments found for the following ids: [\"#{attachment.id}\"]"
  end

  it "returns an error if the attachments don't have an allowed file extension" do
    @submission.assignment.update!(allowed_extensions: ["lemon"])
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: @submission.attempt,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :errors, 0, :message)
    ).to eq "Invalid file type"
  end

  it "returns a graceful error if the submission is not found" do
    result = run_mutation(
      submission_id: 1337,
      active_submission_type: "online_upload",
      attempt: 0,
      file_ids: []
    )
    expect(
      result.dig(:errors, 0, :message)
    ).to eq "not found"
  end

  it "returns an error if the draft is more then one attempt more the current submission attempt" do
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: 1337,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :errors, 0, :message)
    ).to eq "submission draft cannot be more then one attempt ahead of the current submission"
  end

  it "uses the submission attempt plus one if an explicit attempt is not provided" do
    result = run_mutation(
      active_submission_type: "online_upload",
      submission_id: @submission.id,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
    ).to eq @submission.attempt + 1
  end

  it "uses the given attempt when provided" do
    @submission.update!(attempt: 2)
    result = run_mutation(
      submission_id: @submission.id,
      active_submission_type: "online_upload",
      attempt: 1,
      file_ids: [@attachments[0].id]
    )
    expect(
      result.dig(:data, :createSubmissionDraft, :submissionDraft, :submissionAttempt)
    ).to eq 1
  end

  context "when saving a basic_lti_launch draft" do
    let(:external_tool) do
      @submission.course.context_external_tools.create!(
        consumer_key: "aaaa",
        domain: "somewhere",
        name: "some tool",
        shared_secret: "zzzz"
      )
    end

    it "throws an error if an lti_launch_url is not included" do
      result = run_mutation(submission_id: @submission.id, active_submission_type: "basic_lti_launch", attempt: 1)
      expect(result.dig(:data, :createSubmissionDraft, :errors, 0, :message)).to eq "SubmissionError"
    end

    it "throws an error if external_tool_id is not included" do
      result = run_mutation(
        active_submission_type: "basic_lti_launch",
        attempt: 1,
        lti_launch_url: "http://localhost/some-url",
        submission_id: @submission.id
      )
      expect(result.dig(:data, :createSubmissionDraft, :errors, 0, :message)).to eq "SubmissionError"
    end

    it "throws an error if a matching external tool cannot be found" do
      allow(ContextExternalTool).to receive(:find_external_tool).and_return(nil)
      result = run_mutation(
        active_submission_type: "basic_lti_launch",
        attempt: 1,
        external_tool_id: external_tool.id + 1,
        lti_launch_url: "http://localhost/some-url",
        submission_id: @submission.id
      )
      expect(result.dig(:data, :createSubmissionDraft, :errors, 0, :message)).to eq "no matching external tool found"
    end

    it "saves the draft if lti_launch_url is present and external_tool_id points to a valid tool" do
      allow(ContextExternalTool).to receive(:find_external_tool).and_return(external_tool)
      result = run_mutation(
        active_submission_type: "basic_lti_launch",
        attempt: 1,
        external_tool_id: external_tool.id,
        lti_launch_url: "http://localhost/some-url",
        submission_id: @submission.id
      )

      aggregate_failures do
        expect(result.dig(:data, :createSubmissionDraft, :submissionDraft, :activeSubmissionType)).to eq "basic_lti_launch"
        expect(result.dig(:data, :createSubmissionDraft, :submissionDraft, :ltiLaunchUrl)).to eq "http://localhost/some-url"
        expect(result.dig(:data, :createSubmissionDraft, :submissionDraft, :externalTool, :_id)).to eq external_tool.id.to_s
      end
    end

    it "optionally saves a resource_link_lookup_uuid" do
      allow(ContextExternalTool).to receive(:find_external_tool).and_return(external_tool)
      uuid = SecureRandom.uuid
      result = run_mutation(
        active_submission_type: "basic_lti_launch",
        attempt: 1,
        external_tool_id: external_tool.id,
        lti_launch_url: "http://localhost/some-url",
        resource_link_lookup_uuid: uuid,
        submission_id: @submission.id
      )
      expect(result.dig(:data, :createSubmissionDraft, :submissionDraft, :resourceLinkLookupUuid)).to eq uuid
    end
  end

  context "when dup records exist" do
    before do
      # simulate creating a dup record
      submission_draft = SubmissionDraft.where(
        submission: @submission,
        submission_attempt: @submission.attempt
      ).first_or_create!
      submission_draft.update_attribute(:submission_attempt, @submission.attempt + 1)
      SubmissionDraft.where(
        submission: @submission,
        submission_attempt: @submission.attempt
      ).first_or_create!
      submission_draft.update_attribute(:submission_attempt, @submission.attempt)
    end

    it "updates an existing submission draft without error" do
      result = run_mutation(
        active_submission_type: "online_text_entry",
        attempt: @submission.attempt,
        body: "some text body 123",
        submission_id: @submission.id
      )

      drafts = SubmissionDraft.where(
        submission: @submission, submission_attempt: @submission.attempt
      )
      expect(drafts.first.body).to eq "some text body 123"
      expect(
        result.dig(:data, :createSubmissionDraft, :submissionDraft, :activeSubmissionType)
      ).to eq "online_text_entry"
    end

    it "removes dup records" do
      drafts = SubmissionDraft.where(
        submission: @submission, submission_attempt: @submission.attempt
      )

      expect(drafts.count).to be 2
      run_mutation(
        active_submission_type: "online_text_entry",
        attempt: @submission.attempt,
        body: "some text body 123",
        submission_id: @submission.id
      )

      drafts = SubmissionDraft.where(
        submission: @submission, submission_attempt: @submission.attempt
      )
      expect(drafts.count).to be 1
    end
  end
end
