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

require_relative "../../spec_helper"
require_relative "../views_helper"
require_relative "../../selenium/helpers/groups_common"

describe "gradebooks/speed_grader" do
  include GroupsCommon

  let(:locals) do
    {
      anonymize_students: false
    }
  end

  before(:once) do
    course_with_student(active_all: true)
    view_context
    assign(:students, [@user])

    @group_category = @course.group_categories.create!(name: "Test Group Set")
    @group = @course.groups.create!(name: "a group", group_category: @group_category)
    add_user_to_group(@user, @group, true)
    @assignment = @course.assignments.create!(assignment_valid_attributes.merge(
                                                group_category: @group_category,
                                                grade_group_students_individually: true
                                              ))

    assign(:assignment, @assignment)
    assign(:submissions, [])
    assign(:assessments, [])
    assign(:body_classes, [])

    teacher_in_course(active_all: true)
    assign(:current_user, @teacher)
  end

  it "renders without error" do
    expect do
      render template: "gradebooks/speed_grader", locals:
    end.not_to raise_error
  end

  it "includes a mount pount for submission comments" do
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include '<div id="speed_grader_submission_comments_download_mount_point"></div>'
  end

  it "includes a mount pount for comment textarea" do
    assign(:can_comment_on_submission, true)
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include '<div id="speed_grader_comment_textarea_mount_point"></div>'
  end

  it "includes a mount pount for speed grader settings" do
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include '<span id="speed_grader_settings_mount_point"></span>'
  end

  it "includes a mount point for hide assignment grades tray" do
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include '<div id="hide-assignment-grades-tray"></div>'
  end

  it "includes a mount point for post assignment grades tray" do
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include '<div id="post-assignment-grades-tray"></div>'
  end

  it "includes a mount point for editing submission status" do
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include '<div id="speed_grader_edit_status_mount_point"></div>'
    expect(rendered).to include '<div id="speed_grader_edit_status_secondary_mount_point"></div>'
  end

  it "includes a link back to the gradebook (gradebook by default)" do
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include "a href=\"http://test.host/courses/#{@course.id}/gradebook\""
  end

  it "includes the comment auto-save message" do
    render(template: "gradebooks/speed_grader", locals:)

    expect(rendered).to include "Your comment was auto-saved as a draft."
  end

  it "includes the link to publish" do
    render(template: "gradebooks/speed_grader", locals:)

    expect(rendered).to match(/button.+?class=.+?submit_comment_button/)
  end

  it "renders the plagiarism resubmit button if the assignment has a plagiarism tool" do
    allow_any_instance_of(Assignment).to receive(:assignment_configuration_tool_lookup_ids) { [1] }
    render(template: "gradebooks/speed_grader", locals:)
    expect(rendered).to include "<div id='plagiarism_platform_info_container'>"
  end

  describe "submission comments form" do
    it "is rendered when @can_comment_on_submission is true" do
      assign(:can_comment_on_submission, true)
      render(template: "gradebooks/speed_grader", locals:)

      expect(rendered).to match(/form id="add_a_comment"/)
    end

    it "is not rendered when @can_comment_on_submission is false" do
      assign(:can_comment_on_submission, false)
      render(template: "gradebooks/speed_grader", locals:)

      expect(rendered).not_to match(/form id="add_a_comment"/)
    end
  end

  describe "reassignment wrapper" do
    it "is rendered when @can_comment_on_submission and @can_reassign_submissions are true" do
      assign(:can_comment_on_submission, true)
      assign(:can_reassign_submissions, true)
      render(template: "gradebooks/speed_grader", locals:)
      expect(rendered).to include "<div id=\"reassign_assignment_wrapper\""
    end
  end

  context "when group assignment" do
    before do
      assign(:can_comment_on_submission, true)
    end

    it "shows radio buttons if individually graded" do
      render(template: "gradebooks/speed_grader", locals:)
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css('input[type="radio"][name="submission[group_comment]"]').size).to be 2
      expect(html.css("#submission_group_comment").size).to be 1
    end

    it "renders hidden checkbox if group graded" do
      @assignment.grade_group_students_individually = false
      @assignment.save!
      render(template: "gradebooks/speed_grader", locals:)
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css('input[type="radio"][name="submission[group_comment]"]').size).to be 0
      checkbox = html.css("#submission_group_comment")
      expect(checkbox.attr("checked")).not_to be_nil
      expect(checkbox.attr("style").value).to include("display:none")
    end
  end

  context "grading box" do
    let(:html) do
      render(template: "gradebooks/speed_grader", locals:)
      Nokogiri::HTML5.fragment(response.body)
    end

    it "renders the possible points for a points-based assignment" do
      @assignment.update!(grading_type: "points", points_possible: 999)
      expect(html.at_css("#grading-box-points-possible").text).to include("out of 999")
    end

    it "renders rounded possible points for a non-GPA-scale-based assignment" do
      @assignment.update!(grading_type: "percent", points_possible: 999)
      expect(html.at_css("#grading-box-points-possible").text).to include("/ 999")
    end

    it "renders a placeholder for the submission score for a non-points and non-GPA-scale-based assignment" do
      @assignment.update!(grading_type: "percent", points_possible: 999)
      expect(html.at_css("#grading-box-points-possible .score")).to be_present
    end

    it "does not render a placeholder for the submission score for a GPA-scale-based assignment" do
      @assignment.update!(grading_type: "gpa_scale", points_possible: 999)
      expect(html.at_css("#grading-box-points-possible .score")).not_to be_present
    end
  end

  context "hide student names checkbox" do
    let(:html) do
      render(template: "gradebooks/speed_grader", locals:)
      Nokogiri::HTML5.fragment(response.body)
    end

    before(:once) do
      @assignment = @course.assignments.create!(assignment_valid_attributes)
      assign(:assignment, @assignment)
    end

    it "is not rendered when anonymous grading is enabled" do
      @assignment.update!(anonymous_grading: true)
      expect(html.at_css("#hide_student_names")).not_to be_present
    end

    it "is rendered when anonymous grading is not enabled" do
      @assignment.update!(anonymous_grading: false)
      expect(html.at_css("#hide_student_names")).to be_present
    end
  end
end
