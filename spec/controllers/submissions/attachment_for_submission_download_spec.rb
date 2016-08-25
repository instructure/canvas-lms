# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Submissions::AttachmentForSubmissionDownload do
  before :once do
    course_with_student(active_all: true)
    assignment_model(course: @course)
    submission_model({
      assignment: @assignment,
      body: 'here my assignment',
      submission_type: 'online_text_entry',
      user: @student
    })
    @submission.submitted_at = 3.hours.ago
    @submission.save
    @options = {}
  end

  subject do
    Submissions::AttachmentForSubmissionDownload.new(@submission, @options)
  end

  describe '#attachment' do
    it 'raises ActiveRecord::RecordNotFound when download_id is not present' do
      expect(@options.key?(:download_id)).to be_falsey, 'precondition'
      expect {
        subject.attachment
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when attachment belongs to a submission' do
      before do
        @attachment = @submission.attachment = attachment_model(context: @course)
        @submission.save
        @options = { download: @attachment.id }
      end

      it 'returns the attachment that belongs to the submission' do
        expect(subject.attachment).to eq @attachment
      end
    end

    context 'when submission has prior attachment' do
      before :once do
        @attachment = @submission.attachment = attachment_model(context: @course)
        @submission.submitted_at = 3.hours.ago
        @submission.save
      end

      it 'returns prior attachment' do
        expect(@submission.attachment).not_to be_nil, 'precondition'
        expect {
          @submission.with_versioning(explicit: true) do
            @submission.attachment = nil
            @submission.submitted_at = 1.hour.ago
            @submission.save
          end
        }.to change(@submission.versions, :count), 'precondition'
        @submission.reload
        expect(@submission.attachment).to be_nil, 'precondition'
        @options = { download: @attachment.id }
        expect(subject.attachment).to eq @attachment
      end
    end

    context 'when download id is found in attachments collection ids' do
      before :once do
        @attachment = attachment_model(context: @course)
        AttachmentAssociation.create!(context: @submission, attachment: @attachment)
        @options = { download: @attachment.id }
      end

      it 'returns attachment from attachments collection' do
        expect(subject.attachment).to eq @attachment
      end
    end

    context 'when comment id & download id are present' do
      before :once do
        @original_course = @course
        @original_student = @student
        course_with_student(active_all:true)
        submission_comment_model
        @attachment = attachment_model(context: @assignment)
        @submission_comment.attachments = [@attachment]
        @submission_comment.save
        @options = { comment_id: @submission_comment.id, download: @attachment.id }
      end

      it 'returns submission comment attachment' do
        expect(subject.attachment).to eq @attachment
      end
    end

    context 'when download id is in versioned_attachments' do
      before :once do
        @attachment = attachment_model(context: @assignment)
        @submission.attachment_ids = "#{@attachment.id}"
        @submission.save
        @options = { download: @attachment.id }
      end

      it 'returns attachment from versioned_attachments' do
        expect(@submission.attachment_ids).not_to be_nil
        expect(subject.attachment).to eq @attachment
      end
    end
  end
end
