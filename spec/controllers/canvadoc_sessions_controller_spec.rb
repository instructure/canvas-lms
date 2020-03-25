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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CanvadocSessionsController do
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course

    @attachment1 = attachment_model :content_type => 'application/pdf',
      :context => @student
  end

  before :each do
    PluginSetting.create! :name => 'canvadocs',
                          :settings => {"base_url" => "https://example.com"}
    allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return "id" => 1234
    allow_any_instance_of(Canvadocs::API).to receive(:session).and_return 'id' => 'SESSION'
    user_session(@teacher)
  end

  describe '#show' do
    before(:once) do
      @assignment = assignment_model(course: @course)
      @submission = submission_model(assignment: @assignment, user: @student)
      @attachment = attachment_model(content_type: 'application/pdf', user: @student)
      @attachment.associate_with(@submission)
      Canvadoc.create!(attachment: @attachment)
    end

    before do
      @blob = {
        attachment_id: @attachment1.global_id,
        user_id: @teacher.global_id,
        type: "canvadoc",
      }
    end

    it "works" do
      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "doesn't upload documents that are already uploaded" do
      @attachment1.submit_to_canvadocs
      expect_any_instance_of(Attachment).to receive(:submit_to_canvadocs).never
      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "needs a valid signed blob" do
      hmac = Canvas::Security.hmac_sha1(@blob.to_json)

      attachment2 = attachment_model :content_type => 'application/pdf',
        :context => @course
      @blob[:attachment_id] = attachment2.id

      get :show, params: {blob: @blob.to_json, hmac: hmac}
      assert_status(401)
    end

    it "should send o365 as a preferred plugin when the 'Prefer Office 365 file viewer' account setting is enabled" do
      Account.default.settings[:canvadocs_prefer_office_online] = true
      Account.default.save!

      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:preferred_plugins]).to eq [
          Canvadocs::RENDER_O365,
          Canvadocs::RENDER_PDFJS,
          Canvadocs::RENDER_BOX,
          Canvadocs::RENDER_CROCODOC
        ]
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should not send o365 as a preferred plugin when the 'Prefer Office 365 file viewer' account setting is not enabled" do
      Account.default.settings[:canvadocs_prefer_office_online] = false
      Account.default.save!

      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:preferred_plugins]).to eq [
          Canvadocs::RENDER_PDFJS,
          Canvadocs::RENDER_BOX,
          Canvadocs::RENDER_CROCODOC
        ]
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should always send PDFjs as a preferred plugin" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:preferred_plugins]).to eq [Canvadocs::RENDER_PDFJS, Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC]
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send canvas_base_url when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:posted_at].class).to eq String
        expect(arg2[:canvas_base_url]).to eq @course.root_account.domain
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send user_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:user_id]).to eq @teacher.id
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send submission_user_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:submission_user_id]).to eq @submission.user_id
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send course_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:course_id]).to eq @assignment.context_id
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send assignment_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:assignment_id]).to eq @assignment.id
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send submission_id when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:submission_id]).to eq @submission.id
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send post_manually when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:post_manually]).to eq @assignment.post_manually?
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send posted_at when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:posted_at]).to eq @submission.posted_at
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "should send assignment_name when annotatable" do
      allow(Attachment).to receive(:find).and_return(@attachment1)
      expect(@attachment1).to receive(:submit_to_canvadocs) do |arg1, arg2|
        expect(arg1).to eq 1
        expect(arg2[:assignment_name]).to eq @assignment.name
      end

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
    end

    it "needs to be run by the blob user" do
      @blob[:user_id] = @student.global_id
      blob = @blob.to_json
      get :show, params: {blob: blob, hmac: Canvas::Security.hmac_sha1(blob)}
      assert_status(401)
    end

    it "doesn't let you use a crocodoc blob" do
      @blob[:type] = "crocodoc"
      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
      assert_status(401)
    end

    it "allows nil users" do
      remove_user_session
      @blob[:user_id] = nil
      blob = @blob.to_json
      get :show, params: {blob: blob, hmac: Canvas::Security.hmac_sha1(blob)}
      expect(response).to redirect_to("https://example.com/sessions/SESSION/view?theme=dark")
    end

    it "fails gracefulishly when canvadocs times out" do
      allow_any_instance_of(Canvadocs::API).to receive(:session).and_raise(Timeout::Error)
      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}
      assert_status(503)
    end

    it "updates attachment.viewed_at if the owner (user that is the context of the attachment) views" do
      last_viewed_at = @attachment1.viewed_at
      @blob[:user_id] = @student.global_id
      blob = @blob.to_json

      user_session(@student)

      get :show, params: {blob: blob, hmac: Canvas::Security.hmac_sha1(blob)}

      @attachment1.reload
      expect(@attachment1.viewed_at).not_to eq(last_viewed_at)
    end

    it "updates attachment.viewed_at if the owner (person in the user attribute of the attachment) views" do
      assignment = @course.assignments.create!(assignment_valid_attributes)
      attachment = attachment_model content_type: 'application/pdf', context: assignment, user: @student
      blob = {attachment_id: attachment.global_id,
             user_id: @student.global_id,
             type: "canvadoc"}.to_json
      hmac = Canvas::Security.hmac_sha1(blob)
      last_viewed_at = attachment.viewed_at

      user_session(@student)

      get :show, params: {blob: blob, hmac: hmac}

      attachment.reload
      expect(attachment.viewed_at).not_to eq(last_viewed_at)
    end

    it "doesn't update attachment.viewed_at for non-owner views" do
      last_viewed_at = @attachment1.viewed_at

      get :show, params: {blob: @blob.to_json, hmac: Canvas::Security.hmac_sha1(@blob.to_json)}

      @attachment1.reload
      expect(@attachment1.viewed_at).to eq(last_viewed_at)
    end

    describe "annotations" do
      before(:once) do
        @assignment = assignment_model(course: @course)
        @submission = submission_model(assignment: @assignment, user: @student)
        @attachment = attachment_model(content_type: 'application/pdf', user: @student)
        @attachment.associate_with(@submission)
        Canvadoc.create!(attachment: @attachment)
      end

      before(:each) do
        allow(Attachment).to receive(:find).with(@attachment.global_id).and_return(@attachment)
        user_session(@student)
      end

      let(:blob) do
        {
          attachment_id: @attachment.global_id,
          user_id: @student.global_id,
          type: "canvadoc",
          enable_annotations: true,
          enrollment_type: 'student',
          submission_id: @submission.id
        }
      end
      let(:hmac) { Canvas::Security.hmac_sha1(blob.to_json) }

      it "sends along the audit url when annotations are enabled and assignment is anonymous" do
        @assignment.update!(anonymous_grading: true)
        domain = @assignment.course.root_account.domain
        url = submission_docviewer_audit_events_url(@submission.id)
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(audit_url: url))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "sends along the audit url when annotations are enabled and assignment is moderated" do
        @assignment.update!(moderated_grading: true, grader_count: 1, final_grader: @teacher)
        domain = @assignment.course.root_account.domain
        url = submission_docviewer_audit_events_url(@submission.id)
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(audit_url: url))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "does not send the audit url when annotations are enabled but assignment is neither anonymous nor moderated" do
        domain = @assignment.course.root_account.domain
        url = "https://#{domain}/submissions/#{@submission.id}/docviewer_audit_events"
        expect(@attachment.canvadoc).not_to receive(:session_url).with(hash_including(audit_url: url))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "disables submission annotations when passed enable_annotations false" do
        custom_blob = blob.merge(enable_annotations: false).to_json
        custom_hmac = Canvas::Security.hmac_sha1(custom_blob)
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(enable_annotations: false))

        get :show, params: {blob: custom_blob, hmac: custom_hmac}
      end

      it "enables submission annotations when passed enable_annotations true" do
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(enable_annotations: true))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "passes user information based on the submission (if past submission / missing attachment assocation)" do
        @submission.attachment_associations.destroy_all
        expect(@attachment.canvadoc).to receive(:session_url).with(hash_including(user_id: @student.global_id.to_s))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "sends anonymous_instructor_annotations when true in the blob" do
        blob[:anonymous_instructor_annotations] = true

        expect_any_instance_of(Canvadoc).to receive(:session_url).
          with(hash_including(anonymous_instructor_annotations: true))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "doesn't send anonymous_instructor_annotations when false in the blob" do
        blob[:anonymous_instructor_annotations] = false

        expect_any_instance_of(Canvadoc).to receive(:session_url).
          with(hash_excluding(:anonymous_instructor_annotations))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      it "doesn't send anonymous_instructor_annotations when missing" do
        expect_any_instance_of(Canvadoc).to receive(:session_url).
          with(hash_excluding(:anonymous_instructor_annotations))

        get :show, params: {blob: blob.to_json, hmac: hmac}
      end

      context "when the attachment belongs to a non-anonymously-graded assignment" do
        it "enables submission annotations if enable_annotations is true" do
          expect_any_instance_of(Canvadoc).to receive(:session_url).
            with(hash_including(enable_annotations: true))

          get :show, params: {blob: blob.to_json, hmac: hmac}
        end

        it "disables submission annotations if enable_annotations is false" do
          disabled_blob = {
            attachment_id: @attachment.global_id,
            user_id: @student.global_id,
            type: "canvadoc",
            enable_annotations: false
          }
          disabled_hmac = Canvas::Security.hmac_sha1(disabled_blob.to_json)

          expect_any_instance_of(Canvadoc).to receive(:session_url).
            with(hash_including(enable_annotations: false))

          get :show, params: {blob: disabled_blob.to_json, hmac: disabled_hmac}
        end
      end
    end
  end
end
