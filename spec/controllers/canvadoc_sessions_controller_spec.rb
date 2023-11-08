# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe CanvadocSessionsController do
  include HmacHelper

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)

    @attachment1 = attachment_model content_type: "application/pdf",
                                    context: @student
  end

  before do
    PluginSetting.create! name: "canvadocs",
                          settings: { "base_url" => "https://example.com" }
    allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return "id" => 1234
    allow_any_instance_of(Canvadocs::API).to receive(:session).and_return "id" => "SESSION"
    user_session(@teacher)
  end

  describe "#create" do
    before(:once) do
      @assignment = assignment_model(course: @course)
      @submission = submission_model(assignment: @assignment, user: @student)
      @attachment = attachment_model(content_type: "application/pdf", user: @student)
      Canvadoc.create!(attachment: @attachment)
    end

    before do
      @assignment.update!(annotatable_attachment_id: @attachment.id)
      user_session(@student)
    end

    let(:params) do
      {
        submission_attempt: "draft",
        submission_id: @submission.id
      }
    end

    let(:canvadocs_session_url_params) do
      json_response = json_parse(response.body)
      Rack::Utils.parse_query(URI(json_response["canvadocs_session_url"]).query)
    end

    it "is unauthorized for teachers attempting to access a draft" do
      user_session(@teacher)
      post(:create, params:)
      expect(response).to have_http_status(:unauthorized)
    end

    it "is authorized for teachers attempting to access a non-draft" do
      user_session(@teacher)
      @submission.canvadocs_annotation_contexts.create!(attachment: @attachment, submission_attempt: 1)
      post :create, params: params.merge(submission_attempt: 1)
      expect(response).to be_successful
    end

    it "renders unauthorized if the assignment is not annotatable" do
      @assignment.update!(annotatable_attachment_id: nil)
      post(:create, params:)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized if the submission is deleted" do
      new_student = @course.enroll_student(User.create!).user
      new_submission = @assignment.submissions.find_by(user: new_student)
      new_submission.update!(workflow_state: :deleted)

      user_session(new_student)
      post :create, params: { submission_attempt: "draft", submission_id: new_submission.id }
      expect(response).to have_http_status(:unauthorized)
    end

    it "renders bad_request if submission is out of attempts and draft is true" do
      @assignment.update!(allowed_attempts: 2)
      @submission.update!(attempt: 2)

      post(:create, params:)

      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(json_parse(response.body)["error"]).to eq "There are no more attempts available for this submission"
      end
    end

    it "renders bad_request if the submission_attempt does not match any CanvadocsAnnotationContext" do
      new_student = @course.enroll_student(User.create!).user
      new_submission = @assignment.submissions.find_by(user: new_student)

      user_session(new_student)
      post :create, params: { submission_attempt: 1000, submission_id: new_submission.id }

      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(json_parse(response.body)["error"]).to eq "No annotations associated with that submission_attempt"
      end
    end

    it "renders OK response if the user observes the submission" do
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      user_session(observer)

      post(:create, params:)
      expect(response).to have_http_status(:ok)
    end

    it "contains a canvadocs_session_url in the response" do
      post(:create, params:)
      expect(json_parse(response.body)["canvadocs_session_url"]).not_to be_nil
    end

    it "contains the annotation context launch id in the response" do
      post(:create, params:)

      launch_id = @submission.annotation_context(draft: true).launch_id
      expect(json_parse(response.body)["annotation_context_launch_id"]).to eq(launch_id)
    end

    it "contains a blob param in the returned canvadocs_session_url" do
      post(:create, params:)
      expect(canvadocs_session_url_params["blob"]).not_to be_nil
    end

    it "contains an hmac param in the returned canvadocs_session_url" do
      post(:create, params:)
      expect(canvadocs_session_url_params["hmac"]).not_to be_nil
    end

    it "successfully signed the blob" do
      post(:create, params:)
      expect do
        extract_blob(canvadocs_session_url_params["hmac"], canvadocs_session_url_params["blob"])
      end.not_to raise_error
    end

    it "creates a CanvadocsAnnotationContext when one does not exist" do
      new_student = @course.enroll_student(User.create!).user
      new_submission = @assignment.submissions.find_by(user: new_student)

      user_session(new_student)

      expect do
        post :create, params: { submission_attempt: "draft", submission_id: new_submission.id }
      end.to change {
        new_submission.canvadocs_annotation_contexts.where(attachment: @attachment, submission_attempt: nil).count
      }.by(1)
    end

    describe "blob params" do
      let(:blob) do
        extract_blob(canvadocs_session_url_params["hmac"], canvadocs_session_url_params["blob"])
      end

      it "contains an annotation_context" do
        annotation_context = @submission.canvadocs_annotation_contexts.create!(
          attachment: @attachment,
          submission_attempt: 1
        )
        post :create, params: params.merge(submission_attempt: 1)
        expect(blob["annotation_context"]).to eq annotation_context.launch_id
      end

      it "contains the attachment_id" do
        post(:create, params:)
        expect(blob["attachment_id"]).to be @attachment.id
      end

      it "contains the submission_id" do
        post(:create, params:)
        expect(blob["submission_id"]).to be @submission.id
      end

      it "disables the annotation notifications" do
        post(:create, params:)
        expect(blob["disable_annotation_notifications"]).to be true
      end

      it "disables annotations when observing draft" do
        observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
        user_session(observer)

        post(:create, params:)
        expect(blob["enable_annotations"]).to be false
      end
    end
  end

  describe "#show" do
    before(:once) do
      @assignment = assignment_model(course: @course)
      @submission = submission_model(assignment: @assignment, user: @student)
      @attachment = attachment_model(content_type: "application/pdf", user: @student)
      @attachment.associate_with(@submission)
      Canvadoc.create!(attachment: @attachment)
    end

    before do
      @blob = {
        attachment_id: @attachment1.global_id,
        user_id: @teacher.global_id,
        type: "canvadoc"
      }
    end

    it "works" do
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "doesn't upload documents that are already uploaded" do
      @attachment1.submit_to_canvadocs
      expect_any_instance_of(Attachment).not_to receive(:submit_to_canvadocs)
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "needs a valid signed blob" do
      hmac = Canvas::Security.hmac_sha1(@blob.to_json)

      attachment2 = attachment_model content_type: "application/pdf",
                                     context: @course
      @blob[:attachment_id] = attachment2.id

      get :show, params: { blob: @blob.to_json, hmac: }
      assert_status(401)
    end

    it "sends o365 as a preferred plugin when the 'Prefer Office 365 file viewer' account setting is enabled" do
      Account.default.settings[:canvadocs_prefer_office_online] = true
      Account.default.save!

      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:preferred_plugins]).to eq [
          Canvadocs::RENDER_O365,
          Canvadocs::RENDER_PDFJS,
          Canvadocs::RENDER_BOX,
          Canvadocs::RENDER_CROCODOC
        ]
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "does not send o365 as a preferred plugin when the 'Prefer Office 365 file viewer' account setting is not enabled" do
      Account.default.settings[:canvadocs_prefer_office_online] = false
      Account.default.save!

      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:preferred_plugins]).to eq [
          Canvadocs::RENDER_PDFJS,
          Canvadocs::RENDER_BOX,
          Canvadocs::RENDER_CROCODOC
        ]
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "always sends PDFjs as a preferred plugin" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:preferred_plugins]).to eq [Canvadocs::RENDER_PDFJS, Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC]
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends canvas_base_url when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:canvas_base_url]).to eq @course.root_account.domain
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "contains multiple submission_user_ids when group assignment" do
      group = @course.groups.create(name: "some group")
      student2 = User.create
      group.add_user(@student, "accepted", true)
      group.add_user(student2, "accepted", true)
      group_assignment = assignment_model(course: @course, assignment_group: @group)
      group_submission = submission_model(assignment: group_assignment, user: @student)
      group_attachment = attachment_model(content_type: "application/pdf", user: @student)
      group_attachment.associate_with(group_submission)
      Canvadoc.create!(attachment: group_attachment)

      allow(Attachment).to receive(:find).and_return(group_attachment)
      expect(group_attachment).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:submission_user_ids].length).to eq 2
        expect(opts[:submission_user_ids]).to match_array [@student.id, student2.id]
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends user_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:user_id]).to eq @teacher.id
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends submission_user_ids when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:submission_user_ids]).to match_array [@submission.user_id]
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends course_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:course_id]).to eq @assignment.context_id
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends assignment_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:assignment_id]).to eq @assignment.id
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends submission_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:submission_id]).to eq @submission.id
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends disable_annotation_notifications as false by default" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |_, **opts|
        expect(opts[:disable_annotation_notifications]).to be false
      end
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends disable_annotation_notifications as true" do
      @blob[:disable_annotation_notifications] = true
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |_, **opts|
        expect(opts[:disable_annotation_notifications]).to be true
      end
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends post_manually when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:post_manually]).to eq @assignment.post_manually?
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends posted_at when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:posted_at]).to eq @submission.posted_at
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "sends assignment_name when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, **opts|
        expect(arg1).to eq 1
        expect(opts[:assignment_name]).to eq @assignment.name
      end

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
    end

    it "needs to be run by the blob user" do
      @blob[:user_id] = @student.global_id
      blob = @blob.to_json
      get :show, params: { blob:, hmac: Canvas::Security.hmac_sha1(blob) }
      assert_status(401)
    end

    it "doesn't let you use a crocodoc blob" do
      @blob[:type] = "crocodoc"
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
      assert_status(401)
    end

    it "allows nil users" do
      remove_user_session
      @blob[:user_id] = nil
      blob = @blob.to_json
      get :show, params: { blob:, hmac: Canvas::Security.hmac_sha1(blob) }
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "fails gracefulishly when canvadocs times out" do
      allow_any_instance_of(Canvadocs::API).to receive(:session).and_raise(Timeout::Error)
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
      assert_status(503)
    end

    it "fails with a reasonable error when canvadocs has heavy load" do
      allow_any_instance_of(Canvadocs::API).to receive(:session).and_raise(Canvadocs::HeavyLoadError)
      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }
      assert_status(503)
      expect(response.body).to eq "Service is currently unavailable. Try again later."
    end

    it "updates attachment.viewed_at if the owner (user that is the context of the attachment) views" do
      last_viewed_at = @attachment1.viewed_at
      @blob[:user_id] = @student.global_id
      blob = @blob.to_json

      user_session(@student)

      get :show, params: { blob:, hmac: Canvas::Security.hmac_sha1(blob) }

      @attachment1.reload
      expect(@attachment1.viewed_at).not_to eq(last_viewed_at)
    end

    it "updates attachment.viewed_at if the owner (person in the user attribute of the attachment) views" do
      assignment = @course.assignments.create!(assignment_valid_attributes)
      attachment = attachment_model content_type: "application/pdf", context: assignment, user: @student
      blob = { attachment_id: attachment.global_id,
               user_id: @student.global_id,
               type: "canvadoc" }.to_json
      hmac = Canvas::Security.hmac_sha1(blob)
      last_viewed_at = attachment.viewed_at

      user_session(@student)

      get :show, params: { blob:, hmac: }

      attachment.reload
      expect(attachment.viewed_at).not_to eq(last_viewed_at)
    end

    it "doesn't update attachment.viewed_at for non-owner views" do
      last_viewed_at = @attachment1.viewed_at

      get :show, params: { blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json) }

      @attachment1.reload
      expect(@attachment1.viewed_at).to eq(last_viewed_at)
    end

    describe "annotations" do
      before(:once) do
        @assignment = assignment_model(course: @course)
        @submission = submission_model(assignment: @assignment, user: @student)
        @attachment = attachment_model(content_type: "application/pdf", user: @student)
        @attachment.associate_with(@submission)
        Canvadoc.create!(attachment: @attachment)
      end

      before do
        allow(Attachment).to receive(:find).with(@attachment.global_id).and_return(@attachment)
        user_session(@student)
      end

      let(:blob) do
        {
          attachment_id: @attachment.global_id,
          user_id: @student.global_id,
          type: "canvadoc",
          enable_annotations: true,
          enrollment_type: "student",
          submission_id: @submission.id
        }
      end
      let(:hmac) { Canvas::Security.hmac_sha1(blob.to_json) }

      context "when annotation_context is present" do
        before do
          @assignment.update!(annotatable_attachment: @attachment, submission_types: "online_text_entry,student_annotation")
          @assignment.submit_homework(
            @student,
            submission_type: "student_annotation",
            annotatable_attachment_id: @attachment.id
          )

          @submission.reload
        end

        let(:annotation_context) do
          @submission.canvadocs_annotation_contexts.find_by(attachment: @attachment, submission_attempt: 1)
        end

        it "sends along the annotation_context" do
          custom_blob = blob.merge(annotation_context: annotation_context.launch_id).to_json
          custom_hmac = Canvas::Security.hmac_sha1(custom_blob)

          expect(@attachment.canvadoc)
            .to receive(:session_url)
            .with(hash_including(annotation_context: annotation_context.launch_id))

          get :show, params: { blob: custom_blob, hmac: custom_hmac }
        end

        context "when on a test environment named 'foo'" do
          before do
            allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "foo")
          end

          # this check is important to ensure test envs that share the prod DocViewer environment don't affect prod annotations. see CAS-1551
          it "appends the test environment to the annotation context given to docviewer" do
            custom_blob = blob.merge(annotation_context: annotation_context.launch_id).to_json
            custom_hmac = Canvas::Security.hmac_sha1(custom_blob)

            expect(@attachment.canvadoc)
              .to receive(:session_url)
              .with(hash_including(annotation_context: annotation_context.launch_id.to_s + "-foo"))

            get :show, params: { blob: custom_blob, hmac: custom_hmac }
          end
        end

        it "shows all annotations for past attempts when the most recent attempt is not an annotation" do
          Timecop.freeze(10.minutes.from_now(@submission.submitted_at)) do
            @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "hi")
            custom_blob = blob.merge(annotation_context: annotation_context.launch_id).to_json
            custom_hmac = Canvas::Security.hmac_sha1(custom_blob)
            expect(@attachment.canvadoc)
              .to receive(:session_url)
              .with(hash_including(restrict_annotations_to_user_filter: false, user_filter: []))

            get :show, params: { blob: custom_blob, hmac: custom_hmac }
          end
        end

        context "when the user is a student" do
          before do
            user_session(@student)
          end

          it "sets read_only to true if the CanvadocsAnnotationContext is not a draft" do
            custom_blob = blob.merge(annotation_context: annotation_context.launch_id).to_json
            custom_hmac = Canvas::Security.hmac_sha1(custom_blob)

            expect(@attachment.canvadoc)
              .to receive(:session_url)
              .with(hash_including(read_only: true))

            get :show, params: { blob: custom_blob, hmac: custom_hmac }
          end

          it "sets read_only to false if the CanvadocsAnnotationContext is a draft" do
            draft_annotation_context = @submission.annotation_context(draft: true)
            custom_blob = blob.merge(annotation_context: draft_annotation_context.launch_id).to_json
            custom_hmac = Canvas::Security.hmac_sha1(custom_blob)

            expect(@attachment.canvadoc)
              .to receive(:session_url)
              .with(hash_including(read_only: false))

            get :show, params: { blob: custom_blob, hmac: custom_hmac }
          end
        end

        it "sets read_only to false when the teacher has permission to grade" do
          user_session(@teacher)
          custom_blob = blob.merge(
            annotation_context: annotation_context.launch_id,
            enrollment_type: "teacher",
            user_id: @teacher.global_id
          ).to_json
          custom_hmac = Canvas::Security.hmac_sha1(custom_blob)

          expect(@attachment.canvadoc)
            .to receive(:session_url)
            .with(hash_including(read_only: false))

          get :show, params: { blob: custom_blob, hmac: custom_hmac }
        end

        it "sets read_only to true when the teacher does not have permission to grade" do
          @course.root_account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: false)
          user_session(@teacher)
          custom_blob = blob.merge(
            annotation_context: annotation_context.launch_id,
            enrollment_type: "teacher",
            user_id: @teacher.global_id
          ).to_json
          custom_hmac = Canvas::Security.hmac_sha1(custom_blob)

          expect(@attachment.canvadoc)
            .to receive(:session_url)
            .with(hash_including(read_only: true))

          get :show, params: { blob: custom_blob, hmac: custom_hmac }
        end
      end

      it "sends along the audit url when annotations are enabled and assignment is anonymous" do
        @assignment.update!(anonymous_grading: true)
        url = submission_docviewer_audit_events_url(@submission.id)
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(audit_url: url))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "sends along the audit url when annotations are enabled and assignment is moderated" do
        @assignment.update!(moderated_grading: true, grader_count: 1, final_grader: @teacher)
        url = submission_docviewer_audit_events_url(@submission.id)
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(audit_url: url))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "does not send the audit url when annotations are enabled but assignment is neither anonymous nor moderated" do
        domain = @assignment.course.root_account.domain
        url = "https://#{domain}/submissions/#{@submission.id}/docviewer_audit_events"
        expect(@attachment.canvadoc).not_to receive(:session_url).with(hash_including(audit_url: url))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "disables submission annotations when passed enable_annotations false" do
        custom_blob = blob.merge(enable_annotations: false).to_json
        custom_hmac = Canvas::Security.hmac_sha1(custom_blob)
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(enable_annotations: false))

        get :show, params: { blob: custom_blob, hmac: custom_hmac }
      end

      it "enables submission annotations when passed enable_annotations true" do
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(enable_annotations: true))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "marks unread annotations read" do
        @student.mark_submission_annotations_unread!(@submission)
        expect(@student.unread_submission_annotations?(@submission)).to be true
        get :show, params: { blob: blob.to_json, hmac: }
        expect(@student.unread_submission_annotations?(@submission)).to be false
      end

      it "passes use_cloudfront as true" do
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(use_cloudfront: true))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "passes send_usage_metrics as true" do
        Account.default.settings[:enable_usage_metrics] = true
        Account.default.save!
        Account.default.enable_feature! :send_usage_metrics

        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(send_usage_metrics: true))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "passes user information based on the submission (if past submission / missing attachment association)" do
        @submission.attachment_associations.destroy_all
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(user_id: @student.global_id.to_s))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "sends anonymous_instructor_annotations when true in the blob" do
        blob[:anonymous_instructor_annotations] = true

        expect_any_instance_of(Canvadoc).to receive(:session_url)
          .with(hash_including(anonymous_instructor_annotations: true))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "doesn't send anonymous_instructor_annotations when false in the blob" do
        blob[:anonymous_instructor_annotations] = false

        expect_any_instance_of(Canvadoc).to receive(:session_url)
          .with(hash_excluding(:anonymous_instructor_annotations))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "doesn't send anonymous_instructor_annotations when missing" do
        expect_any_instance_of(Canvadoc).to receive(:session_url)
          .with(hash_excluding(:anonymous_instructor_annotations))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      it "gets the user role if not passed as a parameter" do
        expect_any_instance_of(Canvadoc).to receive(:session_url)
          .with(hash_including(enrollment_type: "student"))

        get :show, params: { blob: blob.to_json, hmac: }
      end

      context "when the attachment belongs to a non-anonymously-graded assignment" do
        it "enables submission annotations if enable_annotations is true" do
          expect_any_instance_of(Canvadoc).to receive(:session_url)
            .with(hash_including(enable_annotations: true))

          get :show, params: { blob: blob.to_json, hmac: }
        end

        it "disables submission annotations if enable_annotations is false" do
          disabled_blob = {
            attachment_id: @attachment.global_id,
            user_id: @student.global_id,
            type: "canvadoc",
            enable_annotations: false
          }
          disabled_hmac = Canvas::Security.hmac_sha1(disabled_blob.to_json)

          expect_any_instance_of(Canvadoc).to receive(:session_url)
            .with(hash_including(enable_annotations: false))

          get :show, params: { blob: disabled_blob.to_json, hmac: disabled_hmac }
        end
      end
    end
  end
end
