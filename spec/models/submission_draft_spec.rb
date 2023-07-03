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

require_relative "../spec_helper"

RSpec.describe SubmissionDraft do
  before(:once) do
    @submission = submission_model
    @submission_draft = SubmissionDraft.create!(
      submission: @submission,
      submission_attempt: @submission.attempt
    )
    @media_object = factory_with_protected_attributes(MediaObject, media_id: "m-123456", title: "CreedThoughts")
  end

  describe "cross-shard attachments" do
    specs_require_sharding

    before do
      @shard1.activate { @cross_shard_attachment = attachment_model }
      @shard2.activate do
        @same_shard_attachment = attachment_model
        account = Account.create!
        course_with_student(account:, active_all: true)
        assignment = assignment_model(course: @course)
        submission = submission_model(assignment:, user: @student)
        @draft = submission.submission_drafts.create!(submission_attempt: 1)
      end
    end

    it "attachments association returns attachments that live cross-shard" do
      @shard2.activate do
        @draft.attachments << @cross_shard_attachment
        expect(@draft.reload.attachments).to include @cross_shard_attachment
      end
    end

    it "cleans up cross-shard submission_draft_attachments when the draft is destroyed" do
      @shard2.activate do
        @draft.attachments << @cross_shard_attachment
        @draft.destroy
      end

      @shard1.activate do
        expect(SubmissionDraftAttachment.where(submission_draft: @draft)).to be_empty
      end
    end

    it "attachments association returns attachments that live on the same shard" do
      @shard2.activate do
        @draft.attachments << @same_shard_attachment
        expect(@draft.reload.attachments).to include @same_shard_attachment
      end
    end

    context "finding cross-shard attachments using the attachments association and a where query" do
      it "returns attachments using the 'attachments.id' form in the where query" do
        @shard2.activate do
          @draft.attachments << @cross_shard_attachment
          attachments = @draft.reload.attachments.where("attachments.id": @cross_shard_attachment)
          expect(attachments).to include @cross_shard_attachment
        end
      end

      it "returns attachments using AR association syntax in the where query" do
        @shard2.activate do
          @draft.attachments << @cross_shard_attachment
          attachments = @draft.reload.attachments.where(attachments: { id: @cross_shard_attachment })
          expect(attachments).to include @cross_shard_attachment
        end
      end
    end
  end

  describe "attachments" do
    before(:once) do
      @attachment1 = attachment_model
      @attachment2 = attachment_model
      @attachment3 = attachment_model
      @submission_draft.attachments = [@attachment1, @attachment2, @attachment3]
    end

    it "can be accessed on a submission draft" do
      expect(@submission_draft.attachments).to eq [@attachment1, @attachment2, @attachment3]
    end

    it "can set different attachments on a submission draft" do
      attachment4 = attachment_model
      @submission_draft.attachments = [attachment4]
      expect(@submission_draft.attachments).to eq [attachment4]
    end

    it "are deleted if a submission draft is deleted" do
      @submission_draft.destroy!
      expect(SubmissionDraftAttachment.count).to eq 0
    end
  end

  describe "media_object" do
    before(:once) do
      @submission_draft.media_object_id = @media_object.media_id
    end

    it "can be accessed on a submission draft" do
      expect(@submission_draft.media_object).to eq @media_object
    end

    it "can be changed by updating the media_object_id" do
      media_object = factory_with_protected_attributes(MediaObject, media_id: "m-654321", title: "BeetsBearsBattleStarGalactica")
      @submission_draft.media_object_id = media_object.media_id
      expect(@submission_draft.media_object.media_id).to eq(media_object.media_id)
      expect(@submission_draft.media_object.title).to eq(media_object.title)
    end
  end

  describe "validation" do
    it "submission cannot be nil" do
      expect do
        SubmissionDraft.create!(submission: nil, submission_attempt: @submission.attempt)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "submission_attempt cannot be nil" do
      expect do
        SubmissionDraft.create!(submission: @submission, submission_attempt: nil)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "cannot have duplicate drafts for the same submission and attempt" do
      expect do
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "submission_attempt can be one attempt ahead of the current submissions" do
      expect do
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt + 1)
      end.not_to raise_error
    end

    it "submission_attempt cannot be more then one attempt ahead of the current submissions" do
      expect do
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt + 2)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "cannot have a media_object_it that does not correspond to a media object" do
      expect do
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt, media_object_id: "oogyboogy")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#validates_url" do
    context "the assignment is an online_url type" do
      before(:once) do
        @submission.assignment.submission_types = "online_url"
      end

      it "prefixes the url with a scheme if missing" do
        @submission_draft.update!(url: "www.google.com")
        expect(@submission_draft.url).to eq("http://www.google.com")
      end
    end
  end

  describe "#meets_media_recording_criteria?" do
    before(:once) do
      @submission.assignment.submission_types = "media_recording"
    end

    it "returns true if there is a media_object_id" do
      @submission_draft.media_object_id = @media_object.media_id
      expect(@submission_draft.meets_media_recording_criteria?).to be(true)
    end

    it "returns false if there is no media_object_id" do
      expect(@submission_draft.meets_media_recording_criteria?).to be(false)
    end
  end

  describe "#meets_assignment_criteria?" do
    context "the assignment is an online_text_entry type" do
      before(:once) do
        @submission.assignment.submission_types = "online_text_entry"
      end

      it "returns true if there is a text body" do
        @submission_draft.body = "some body"
        expect(@submission_draft.meets_assignment_criteria?).to be(true)
      end

      it "returns false if the text body is empty" do
        @submission_draft.body = ""
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if drafts exist for a different type" do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end
    end

    context "the assignment is an online_upload type" do
      before(:once) do
        @submission.assignment.submission_types = "online_upload"
      end

      it "returns true if there are any attachments" do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to be(true)
      end

      it "returns false if attachments is an empty array" do
        @submission_draft.attachments = []
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if drafts exist for a different type" do
        @submission_draft.body = "some body"
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns true if a valid lti_launch_url is present" do
        @submission_draft.lti_launch_url = "http://localhost/some-url"
        expect(@submission_draft).to be_meets_assignment_criteria
      end

      it "returns false if there are no attachments and lti_launch_url is invalid" do
        @submission_draft.lti_launch_url = "oh no"
        expect(@submission_draft).not_to be_meets_assignment_criteria
      end
    end

    context "the assignment is an online_url type" do
      before(:once) do
        @submission.assignment.submission_types = "online_url"
      end

      it "returns true if there is a url" do
        @submission_draft.url = "http://www.google.com"
        expect(@submission_draft.meets_assignment_criteria?).to be(true)
      end

      it "returns false if the url is not valid" do
        @submission_draft.url = "oogy boogy"
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if the url is malformed" do
        @submission_draft.url = "http:www.google.com"
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if the url is empty" do
        @submission_draft.url = ""
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if drafts exist for a different type" do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end
    end

    context "the assignment is a media_recording type" do
      before(:once) do
        @submission.assignment.submission_types = "media_recording"
      end

      it "returns true if there is a media_object_id" do
        @submission_draft.media_object_id = @media_object.media_id
        expect(@submission_draft.meets_assignment_criteria?).to be(true)
      end

      it "returns false if the media_object_id is empty" do
        @submission_draft.media_object_id = ""
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if drafts exist for a different type" do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end
    end

    context "the assignment is a student_annotation type" do
      before(:once) do
        @submission.assignment.update!(submission_types: "student_annotation")
      end

      it "returns true if there is an annotation context draft" do
        annotatable_attachment = attachment_model
        @submission.assignment.annotatable_attachment_id = annotatable_attachment.id
        @submission.annotation_context(draft: true)
        expect(@submission_draft).to be_meets_assignment_criteria
      end

      it "returns false if the submission does not have an annotation context draft" do
        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end

      it "returns false if drafts exist for a different type" do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to be(false)
      end
    end

    context "there are multiple submission types" do
      before(:once) do
        @submission.assignment.submission_types = "online_text_entry,online_upload"
      end

      it "returns true if a draft exists for any of the submission types" do
        @submission_draft.body = "some body"
        expect(@submission_draft.meets_assignment_criteria?).to be(true)
      end
    end

    it "returns false if there are no draft states" do
      expect(@submission_draft.meets_assignment_criteria?).to be(false)
    end
  end
end
