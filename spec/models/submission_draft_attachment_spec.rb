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

describe SubmissionDraftAttachment do
  before :once do
    @submission = submission_model
    @submission_draft = SubmissionDraft.create!(
      submission: @submission,
      submission_attempt: @submission.attempt
    )
    @attachment = attachment_model
    @submission_draft_attachment = SubmissionDraftAttachment.create!(
      submission_draft: @submission_draft,
      attachment: @attachment
    )
  end

  it "submission draft attachment has one attachment" do
    expect(@submission_draft_attachment.attachment).to eq @attachment
  end

  it "attachments can have multiple submission draft attachments" do
    submission2 = submission_model
    submission_draft2 = SubmissionDraft.create!(
      submission: submission2,
      submission_attempt: submission2.attempt
    )
    submission_draft_attachment2 = SubmissionDraftAttachment.create!(
      submission_draft: submission_draft2,
      attachment: @attachment
    )
    expect(@attachment.submission_draft_attachments.sort).to eq [
      @submission_draft_attachment,
      submission_draft_attachment2
    ]
  end

  context "validation" do
    it "will not let you have multiple of the same attachment to submission draft" do
      expect do
        SubmissionDraftAttachment.create!(
          submission_draft: @submission_draft,
          attachment: @attachment
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "requires an attachment" do
      expect do
        SubmissionDraftAttachment.create!(
          submission_draft: @submission_draft,
          attachment: nil
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "requires a submission draft" do
      expect do
        SubmissionDraftAttachment.create!(
          submission_draft: nil,
          attachment: @attachment
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "sharding" do
    specs_require_sharding

    before do
      @shard1.activate { @attachment1 = attachment_model(context: course_factory(account: Account.create!)) }
      @shard2.activate { @attachment2 = attachment_model(context: course_factory(account: Account.create!)) }
      @shard1.activate do
        @submission_draft.attachments = [@attachment1, @attachment2]
        @submission_draft.save!
      end
    end

    it "can have attachments saved that are cross shard" do
      @shard1.activate do
        expect(
          @submission_draft.attachments.pluck(:id).sort
        ).to eq [@attachment1.id, @attachment2.global_id].sort
      end

      @shard2.activate do
        expect(
          @submission_draft.attachments.pluck(:id).sort
        ).to eq [@attachment1.global_id, @attachment2.id].sort
      end
    end
  end
end
