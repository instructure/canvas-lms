# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "submissions/show_preview" do
  it "renders" do
    course_with_student
    view_context
    a = @course.assignments.create!(title: "some assignment")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show_preview"
    expect(response).not_to be_nil
  end

  it "loads an lti launch" do
    course_with_student
    view_context
    a = @course.assignments.create!(title: "external assignment", submission_types: "basic_lti_launch")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user, submission_type: "basic_lti_launch", url: "http://www.example.com"))
    render "submissions/show_preview"
    expect(response.body).to match(%r{courses/#{@course.id}/external_tools/retrieve})
    expect(response.body).to match(/.*www\.example\.com.*/)
  end

  it "gives a user-friendly explanation why there's no preview" do
    course_with_student
    view_context
    a = @course.assignments.create!(title: "some assignment", submission_types: "on_paper")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show_preview"
    expect(response.body).to match(/No Preview Available/)
  end

  context "New Quizzes (quiz_lti)" do
    before(:once) do
      course_with_student
    end

    before do
      view_context
      @quiz_lti_tool = @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
    end

    context "with quiz_lti assignment" do
      before do
        @assignment = @course.assignments.create!(
          title: "New Quiz",
          submission_types: "external_tool"
        )
        @assignment.external_tool_tag = ContentTag.new(
          url: "http://example.com/launch",
          new_tab: false,
          content_type: "ContextExternalTool",
          content_id: @quiz_lti_tool.id
        )
        @assignment.external_tool_tag.save!
        assign(:assignment, @assignment)
      end

      it "redirects to tool launch URL when unsubmitted" do
        @submission = @assignment.submissions.find_or_create_by!(user: @student)
        assign(:submission, @submission)
        render "submissions/show_preview"

        expect(response.body).to match(/meta HTTP-EQUIV="REFRESH"/i)
        expect(response.body).to match(%r{courses/#{@course.id}/external_tools/retrieve})
        expect(response.body).to match(/display=borderless/)
        expect(response.body).not_to match(/No Preview Available/)
      end

      it "redirects to tool launch URL when submitted" do
        @submission = @assignment.submit_homework(
          @student,
          submission_type: "basic_lti_launch",
          url: "http://example.com/quiz/result"
        )
        assign(:submission, @submission)
        render "submissions/show_preview"

        expect(response.body).to match(/meta HTTP-EQUIV="REFRESH"/i)
        expect(response.body).to match(%r{courses/#{@course.id}/external_tools/retrieve})
        expect(response.body).to match(/example\.com/)
      end
    end

    it "still shows 'No Preview Available' for non-quiz external_tool assignments" do
      regular_tool = @course.context_external_tools.create!(
        name: "Some Other Tool",
        consumer_key: "key",
        shared_secret: "secret",
        url: "http://other-tool.com/launch"
      )

      assignment = @course.assignments.create!(
        title: "External Tool Assignment",
        submission_types: "external_tool"
      )
      assignment.external_tool_tag = ContentTag.new(
        url: "http://other-tool.com/launch",
        new_tab: false,
        content_type: "ContextExternalTool",
        content_id: regular_tool.id
      )
      assignment.external_tool_tag.save!

      submission = assignment.submissions.find_or_create_by!(user: @student)

      assign(:assignment, assignment)
      assign(:submission, submission)
      render "submissions/show_preview"

      expect(response.body).to match(/No Preview Available/)
    end
  end

  context "when assignment involves DocViewer" do
    before(:once) do
      course_with_student
    end

    before do
      @attachment = Attachment.create!(context: @student, uploaded_data: stub_png_data, filename: "homework.png")
      allow(Canvadocs).to receive_messages(enabled?: true, config: { a: 1 })
      allow(Canvadoc).to receive(:mime_types).and_return(@attachment.content_type)
      view_context
    end

    it "renders a DocViewer url that includes the submission id when assignment takes file uploads" do
      assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
      submission = assignment.submit_homework(@user, attachments: [@attachment])
      assign(:assignment, assignment)
      assign(:submission, submission)
      render template: "submissions/show_preview", locals: { anonymize_students: assignment.anonymize_students? }
      expect(response.body.include?("%22submission_id%22:#{submission.id}")).to be true
    end

    it "renders multiple DocViewer urls that do not have null attributes because of hash attribute deletions in code" do
      assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
      another_attachment = Attachment.create!(context: @student, uploaded_data: stub_png_data, filename: "homework2.png")
      submission = assignment.submit_homework(@user, attachments: [@attachment, another_attachment])
      assign(:assignment, assignment)
      assign(:submission, submission)
      render template: "submissions/show_preview", locals: { anonymize_students: assignment.anonymize_students? }
      expect(response.body.include?("%22enable_annotations%22:null")).to be false
    end

    it "includes an indicator if unread annotations exist" do
      assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
      submission = assignment.submit_homework(@user, attachments: [@attachment])
      assign(:assignment, assignment)
      assign(:submission, submission)
      @student.mark_submission_annotations_unread!(submission)
      render template: "submissions/show_preview", locals: { anonymize_students: assignment.anonymize_students? }
      expect(response.body).to include %(<span class="submission_annotation unread_indicator")
    end

    it "renders an iframe with a src to canvadoc sessions controller when assignment is a student annotation" do
      assignment = @course.assignments.create!(
        annotatable_attachment: @attachment,
        submission_types: "student_annotation",
        title: "some assignment"
      )
      submission = assignment.submit_homework(
        @user,
        annotatable_attachment_id: @attachment.id,
        submission_type: "student_annotation"
      )
      assign(:assignment, assignment)
      assign(:submission, submission)
      render template: "submissions/show_preview", locals: { anonymize_students: assignment.anonymize_students? }
      element = Nokogiri::HTML5.fragment(response.body).at_css("iframe.ef-file-preview-frame")

      aggregate_failures do
        expect(element).not_to be_nil
        expect(element["src"]).to match(%r{/api/v1/canvadoc_session?})
      end
    end
  end

  describe "originality score" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: "an assignment", submission_types: "online_text_entry") }
    let(:student) { course.enroll_student(User.create!, activate_all: true).user }
    let(:teacher) { course.enroll_teacher(User.create!, activate_all: true).user }
    let(:submission) { assignment.submit_homework(student, submission_type: "online_text_entry", body: "zzzz") }

    let(:output) { Nokogiri::HTML5.fragment(response.body) }

    before do
      allow(assignment).to receive(:turnitin_enabled?).and_return(true)
      user_session(teacher)

      assign(:assignment, assignment)
      assign(:context, course)
      assign(:current_user, teacher)
      assign(:submission, submission)
    end

    context "when the New Gradebook Plagiarism Indicator feature is enabled" do
      before { course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator) }

      it "renders a similarity icon if the submission possesses similarity data" do
        submission.originality_reports.create!(
          originality_score: 10,
          workflow_state: "scored"
        )

        render template: "submissions/show_preview"
        expect(output.at_css("i.icon-certified")).to be_present
      end

      it "does not render an icon if there is no similarity data" do
        render template: "submissions/show_preview"
        expect(output.at_css("i.icon-certified")).not_to be_present
      end
    end

    context "when the New Gradebook Plagiarism Indicator feature is disabled" do
      it "renders a similarity icon if the submission possesses similarity data" do
        submission.originality_reports.create!(
          originality_score: 10,
          workflow_state: "scored"
        )

        render template: "submissions/show_preview"
        expect(output.at_css(".turnitin_score_container")).to be_present
      end

      it "does not render an icon if there is no similarity data" do
        render template: "submissions/show_preview"
        expect(output.css(".turnitin_score_container")).not_to be_present
      end
    end
  end

  describe "asset report status containers" do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!, active_all: true).user }

    before do
      assign(:context, course)
      assign(:current_user, student)
    end

    context "when submission is online_upload" do
      let(:assignment) { course.assignments.create!(title: "upload assignment", submission_types: "online_upload") }
      let(:attachment) { Attachment.create!(context: student, uploaded_data: stub_png_data, filename: "homework.png") }
      let(:submission) { assignment.submit_homework(student, submission_type: "online_upload", attachments: [attachment]) }

      before do
        assign(:assignment, assignment)
        assign(:submission, submission)
      end

      it "renders asset report status table header with correct data attributes" do
        render template: "submissions/show_preview", locals: { anonymize_students: false }

        expect(response.body).to include('class="asset-report-status-header"')
        expect(response.body).to match(/class="[^"]*asset-report-status-header[^"]*"[^>]*data-submission-id="#{submission.id}"/)
        expect(response.body).to match(/class="[^"]*asset-report-status-header[^"]*"[^>]*data-submission-type="online_upload"/)
      end

      it "renders asset report status container for each attachment with correct data attributes" do
        render template: "submissions/show_preview", locals: { anonymize_students: false }

        expect(response.body.scan(/class="[^"]*asset-report-status-container[^"]*"/).size).to eq(1)
        expect(response.body).to match(/class="[^"]*asset-report-status-container[^"]*"[^>]*data-attachment-id="#{attachment.id}"/)
        expect(response.body).to match(/class="[^"]*asset-report-status-container[^"]*"[^>]*data-submission-id="#{submission.id}"/)
        expect(response.body).to match(/class="[^"]*asset-report-status-container[^"]*"[^>]*data-submission-type="online_upload"/)
      end

      it "renders asset report status containers for multiple attachments" do
        another_attachment = Attachment.create!(context: student, uploaded_data: stub_png_data, filename: "homework2.png")
        multi_submission = assignment.submit_homework(student, submission_type: "online_upload", attachments: [attachment, another_attachment])
        assign(:submission, multi_submission)

        render template: "submissions/show_preview", locals: { anonymize_students: false }

        expect(response.body.scan(/class="[^"]*asset-report-status-container[^"]*"/).size).to eq(2)
        expect(response.body).to include("data-attachment-id=\"#{attachment.id}\"")
        expect(response.body).to include("data-attachment-id=\"#{another_attachment.id}\"")
      end
    end

    context "when submission is online_text_entry" do
      let(:assignment) { course.assignments.create!(title: "text assignment", submission_types: "online_text_entry") }
      let(:submission) { assignment.submit_homework(student, submission_type: "online_text_entry", body: "my text") }

      before do
        assign(:assignment, assignment)
        assign(:submission, submission)
      end

      it "does not render asset report status containers" do
        render template: "submissions/show_preview", locals: { anonymize_students: false }

        expect(response.body).not_to include('class="asset-report-status-header"')
        expect(response.body).not_to include('class="asset-report-status-container"')
      end
    end

    context "when submission has no attachments" do
      let(:assignment) { course.assignments.create!(title: "upload assignment", submission_types: "online_upload") }
      let(:submission) { assignment.submit_homework(student, submission_type: "online_upload", attachments: []) }

      before do
        assign(:assignment, assignment)
        assign(:submission, submission)
      end

      it "renders empty table with header but no containers" do
        render template: "submissions/show_preview", locals: { anonymize_students: false }

        expect(response.body).not_to include('class="asset-report-status-header"')
        expect(response.body.scan(/class="[^"]*asset-report-status-container[^"]*"/).size).to eq(0)
      end
    end
  end
end
