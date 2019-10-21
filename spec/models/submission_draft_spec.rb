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

require_relative '../spec_helper'

RSpec.describe SubmissionDraft do
  before(:once) do
    @submission = submission_model
    @submission_draft = SubmissionDraft.create!(
      submission: @submission,
      submission_attempt: @submission.attempt
    )
    @media_object = factory_with_protected_attributes(MediaObject, :media_id => 'm-123456', :title => 'CreedThoughts')
  end

  describe 'attachments' do
    before(:once) do
      @attachment1 = attachment_model
      @attachment2 = attachment_model
      @attachment3 = attachment_model
      @submission_draft.attachments = [@attachment1, @attachment2, @attachment3]
    end

    it 'can be accessed on a submission draft' do
      expect(@submission_draft.attachments).to eq [@attachment1, @attachment2, @attachment3]
    end

    it 'can set different attachments on a submission draft' do
      attachment4 = attachment_model
      @submission_draft.attachments = [attachment4]
      expect(@submission_draft.attachments).to eq [attachment4]
    end

    it 'are deleted if a submission draft is deleted' do
      @submission_draft.destroy!
      expect(SubmissionDraftAttachment.count).to eq 0
    end
  end

  describe 'media_object' do
    before(:once) do
      @submission_draft.media_object_id = @media_object.media_id
    end

    it 'can be accessed on a submission draft' do
      expect(@submission_draft.media_object).to eq @media_object
    end

    it 'can be changed by updating the media_object_id' do
      media_object = factory_with_protected_attributes(MediaObject, :media_id => 'm-654321', :title => 'BeetsBearsBattleStarGalactica')
      @submission_draft.media_object_id = media_object.media_id
      expect(@submission_draft.media_object.media_id).to eq(media_object.media_id)
      expect(@submission_draft.media_object.title).to eq(media_object.title)
    end
  end

  describe 'validation' do
    it 'submission cannot be nil' do
      expect{
        SubmissionDraft.create!(submission: nil, submission_attempt: @submission.attempt)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'submission_attempt cannot be nil' do
      expect{
        SubmissionDraft.create!(submission: @submission, submission_attempt: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'cannot have duplicate drafts for the same submission and attempt' do
      expect{
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'submission_attempt can be one attempt ahead of the current submissions' do
      expect{
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt + 1)
      }.not_to raise_error
    end

    it 'submission_attempt cannot be more then one attempt ahead of the current submissions' do
      expect{
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt + 2)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'cannot have a media_object_it that does not correspond to a media object' do
      expect{
        SubmissionDraft.create!(submission: @submission, submission_attempt: @submission.attempt, media_object_id: 'oogyboogy')
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#validates_url' do
    context 'the assignment is an online_url type' do
      before(:once) do
        @submission.assignment.submission_types = 'online_url'
      end

      it 'prefixes the url with a scheme if missing' do
        @submission_draft.update!(url: 'www.google.com')
        expect(@submission_draft.url).to eq('http://www.google.com')
      end
    end
  end

  describe '#meets_assignment_criteria?' do
    context 'the assignment is an online_text_entry type' do
      before(:once) do
        @submission.assignment.submission_types = 'online_text_entry'
      end

      it 'returns true if there is a text body' do
        @submission_draft.body = 'some body'
        expect(@submission_draft.meets_assignment_criteria?).to eq(true)
      end

      it 'returns false if the text body is empty' do
        @submission_draft.body = ''
        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end

      it 'returns false if drafts exist for a different type' do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end
    end

    context 'the assignment is an online_upload type' do
      before(:once) do
        @submission.assignment.submission_types = 'online_upload'
      end

      it 'returns true if there are any attachments' do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to eq(true)
      end

      it 'returns false if attachments is an empty array' do
        @submission_draft.attachments = []
        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end

      it 'returns false if drafts exist for a different type' do
        @submission_draft.body = 'some body'
        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end
    end

    context 'the assignment is an online_url type' do
      before(:once) do
        @submission.assignment.submission_types = 'online_url'
      end

      it 'returns true if there is a url' do
        @submission_draft.url = 'http://www.google.com'
        expect(@submission_draft.meets_assignment_criteria?).to eq(true)
      end

      it 'returns false if the url is not valid' do
        @submission_draft.url = 'oogy boogy'
        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end

      it 'returns false if the url is empty' do
        @submission_draft.url = ''
        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end

      it 'returns false if drafts exist for a different type' do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end
    end

    context 'the assignment is a media_recording type' do
      before(:once) do
        @submission.assignment.submission_types = 'media_recording'
      end

      it 'returns true if there is a media_object_id' do
        @submission_draft.media_object_id = @media_object.media_id
        expect(@submission_draft.meets_assignment_criteria?).to eq(true)
      end

      it 'returns false if the media_object_id is empty' do
        @submission_draft.media_object_id = ''
        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end

      it 'returns false if drafts exist for a different type' do
        attachment = attachment_model
        @submission_draft.attachments = [attachment]

        expect(@submission_draft.meets_assignment_criteria?).to eq(false)
      end
    end

    context 'there are multiple submission types' do
      before(:once) do
        @submission.assignment.submission_types = 'online_text_entry,online_upload'
      end

      it 'returns true if a draft exists for any of the submission types' do
        @submission_draft.body = 'some body'
        expect(@submission_draft.meets_assignment_criteria?).to eq(true)
      end
    end

    it 'returns false if there are no draft states' do
      expect(@submission_draft.meets_assignment_criteria?).to eq(false)
    end
  end
end
