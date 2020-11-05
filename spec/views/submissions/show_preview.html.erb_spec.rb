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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/submissions/show_preview" do
  it "should render" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show_preview"
    expect(response).not_to be_nil
  end

  it "should load an lti launch" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "external assignment", :submission_types => 'basic_lti_launch')
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user, submission_type: 'basic_lti_launch', url: 'http://www.example.com'))
    render "submissions/show_preview"
    expect(response.body).to match(/courses\/#{@course.id}\/external_tools\/retrieve/)
    expect(response.body).to match(/.*www\.example\.com.*/)
  end

  it "should give a user-friendly explanation why there's no preview" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment", :submission_types => 'on_paper')
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show_preview"
    expect(response.body).to match(/No Preview Available/)
  end

  it "a DocViewer url that includes the submission id" do
    course_with_student
    view_context
    assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
    attachment = Attachment.create!(context: @student, uploaded_data: stub_png_data, filename: "homework.png")
    submission = assignment.submit_homework(@user, attachments: [attachment])
    allow(Canvadocs).to receive(:enabled?).and_return(true)
    allow(Canvadocs).to receive(:config).and_return({a: 1})
    allow(Canvadoc).to receive(:mime_types).and_return("image/png")
    assign(:assignment, assignment)
    assign(:submission, submission)
    render template: "submissions/show_preview", locals: {anonymize_students: assignment.anonymize_students?}
    expect(response.body.include?("%22submission_id%22:#{submission.id}")).to be true
  end

  describe "originality score" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: "an assignment", submission_types: "online_text_entry") }
    let(:student) { course.enroll_student(User.create!, activate_all: true).user }
    let(:teacher) { course.enroll_teacher(User.create!, activate_all: true).user }
    let(:submission) { assignment.submit_homework(student, submission_type: "online_text_entry", body: "zzzz") }

    let(:output) { Nokogiri::HTML.fragment(response.body) }

    before(:each) do
      allow(assignment).to receive(:turnitin_enabled?).and_return(true)
      user_session(teacher)

      assign(:assignment, assignment)
      assign(:context, course)
      assign(:current_user, teacher)
      assign(:submission, submission)
    end

    context "when the New Gradebook Plagiarism Indicator feature is enabled" do
      before(:each) { course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator) }

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
