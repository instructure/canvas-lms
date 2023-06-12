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

describe Submissions::AnonymousDownloadsController do
  describe "GET :show" do
    before do
      course_with_student_and_submitted_homework
      @course.account.enable_service(:avatars)
      @context = @course
      user_session(@student)
    end

    context "when attachment belongs to submission" do
      before do
        @attachment = @submission.attachment = attachment_model(context: @context)
        @submission.save!
      end

      it "sets attachment the submission belongs to by default" do
        get :show, params: {
          course_id: @context.id,
          assignment_id: @assignment.id,
          anonymous_id: @submission.anonymous_id,
          download: @submission.attachment_id
        }
        expect(assigns(:attachment)).to eq @attachment
        expect(response).to redirect_to(course_file_download_url(@context, @attachment, {
                                                                   download_frd: true,
                                                                   inline: nil,
                                                                   verifier: @attachment.uuid
                                                                 }))
      end

      it "renders as json" do
        request.accept = Mime[:json].to_s
        get :show,
            params: {
              course_id: @context.id,
              assignment_id: @assignment.id,
              anonymous_id: @submission.anonymous_id,
              download: @submission.attachment_id
            },
            format: :json
        expect(response.parsed_body["attachment"]["id"]).to eq @submission.attachment_id
      end
    end

    it "sets attachment from submission history if present" do
      attachment = @submission.attachment = attachment_model(context: @context)
      @submission.submitted_at = 3.hours.ago
      @submission.save!
      expect(@submission.attachment).not_to be_nil, "precondition"
      expect do
        @submission.with_versioning(explicit: true) do
          @submission.attachment = nil
          @submission.submitted_at = 1.hour.ago
          @submission.save!
        end
      end.to change(@submission.versions, :count), "precondition"
      expect(@submission.attachment).to be_nil, "precondition"

      get :show, params: {
        course_id: @context.id,
        assignment_id: @assignment.id,
        anonymous_id: @submission.anonymous_id,
        download: attachment.id
      }
      expect(assigns(:attachment)).not_to be_nil
      expect(assigns(:attachment)).to eq attachment
    end

    it "sets attachment from attachments collection when attachment_id is not present" do
      attachment = attachment_model(context: @context)
      AttachmentAssociation.create!(context: @submission, attachment:)
      get :show, params: {
        course_id: @context.id,
        assignment_id: @assignment.id,
        anonymous_id: @submission.anonymous_id,
        download: @submission.attachments.first.id
      }
      expect(assigns(:attachment)).not_to be_nil
      expect(@submission.attachments).to include assigns(:attachment)
    end

    context "and params[:comment_id]" do
      before do
        # our factory system is broken
        @original_context = @context
        @original_student = @student
        course_with_student(active_all: true)
        @course.account.enable_service(:avatars)
        submission_comment_model
        @attachment = attachment_model(context: @assignment)
        @submission_comment.attachments = [@attachment]
        @submission_comment.save!
      end

      it "sets attachment from comment_id & download_id" do
        expect(@assignment.attachments).to include(@attachment), "precondition"
        expect(@submission_comment.attachments).to include(@attachment), "precondition"

        get :show, params: {
          course_id: @original_context.id,
          assignment_id: @assignment.id,
          anonymous_id: @submission.anonymous_id,
          download: @attachment.id,
          comment_id: @submission_comment.id
        }
        expect(assigns(:attachment)).to eq @attachment
        expect(response).to redirect_to(file_download_url(@attachment, {
                                                            download_frd: true,
                                                            inline: nil,
                                                            verifier: @attachment.uuid
                                                          }))
      end
    end

    it "redirects download requests with the download_frd parameter" do
      # This is because the files controller looks for download_frd to indicate a forced download
      course_with_teacher_logged_in
      @course.account.enable_service(:avatars)
      assignment = assignment_model(course: @course)
      student_in_course
      att = attachment_model(uploaded_data: stub_file_data("test.txt", "asdf", "text/plain"), context: @student)
      submission_model(
        course: @course,
        assignment:,
        submission_type: "online_upload",
        attachment_ids: att.id,
        attachments: [att],
        user: @student
      )
      get :show, params: { assignment_id: assignment.id, course_id: @course.id, anonymous_id: @submission.anonymous_id, download: att.id }

      expect(response).to be_redirect
      expect(response.headers["Location"]).to match %r{users/#{@student.id}/files/#{att.id}/download\?download_frd=true}
    end
  end
end
