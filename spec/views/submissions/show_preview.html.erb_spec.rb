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
end
