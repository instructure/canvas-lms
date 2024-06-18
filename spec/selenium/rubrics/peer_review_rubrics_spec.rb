# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../helpers/rubrics_common"
require_relative "../grades/pages/speedgrader_page"
require_relative "../rubrics/pages/rubrics_assessment_tray"
require_relative "../assignments_v2/page_objects/student_assignment_page_v2"

describe "Peer reviews with in rubrics" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  before do
    Account.default.enable_feature!(:assignments_2_student)
    Account.default.enable_feature!(:peer_reviews_for_a2)
    Account.default.enable_feature!(:enhanced_rubrics)
    @course = course_factory(name: "course", active_course: true)
    @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    @student1 = student_in_course(name: "Student 1", course: @course, enrollment_state: :active).user
    @student2 = student_in_course(name: "Student 2", course: @course, enrollment_state: :active).user
    @peer_review_assignment = assignment_model({
                                                 course: @course,
                                                 peer_reviews: true,
                                                 automatic_peer_reviews: false,
                                                 points_possible: 10,
                                                 submission_types: "online_text_entry"
                                               })
    @peer_review_assignment.assign_peer_review(@student1, @student2)
    @peer_review_assignment.assign_peer_review(@student2, @student1)
    @rubric = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: largest_rubric_data, points_possible: 30)
    RubricAssociation.create!(rubric: @rubric, context: @course, association_object: @course, purpose: "bookmark")
    @ra = @rubric.associate_with(@peer_review_assignment, @course, purpose: "grading")
    @peer_review_assignment.submit_homework(@student1, body: "student 1 submission")
    @peer_review_assignment.submit_homework(@student2, body: "student 2 submission")
    user_session(@student1)
  end

  it "displays a rubric to student when submitting to the assignment in read only mode" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    expect(RubricAssessmentTray.traditional_grid_rubric_assessment_view).to be_displayed
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).attribute(:readonly)).to eq("true")
  end

  it "students are shown a notification reading “Fill out the rubric below after reviewing the student submission to complete this review.” with a button to open the rubric" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/?reviewee_id=#{@student2.id}"

    expect(StudentAssignmentPageV2.rubric_toggle).to include_text("Fill out the rubric below after reviewing the student submission to complete this review.")
  end

  it "students can assess with the traditional rubric view" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/?reviewee_id=#{@student2.id}"

    RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
    RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("comment 1")
    RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
    RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("comment 2")
    RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
    RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("comment 3")
    RubricAssessmentTray.submit_rubric_assessment_button.click

    expect(StudentAssignmentPageV2.peer_review_prompt_modal).to include_text("You have completed your Peer Reviews!")
  end

  it "students can assess with the horizontal rubric view" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/?reviewee_id=#{@student2.id}"

    RubricAssessmentTray.rubric_assessment_view_mode_select.click
    RubricAssessmentTray.rubric_horizontal_view_option.click
    RubricAssessmentTray.modern_rating_button(@rubric.data[0][:ratings][0][:id], 0).click
    RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("comment 1")
    RubricAssessmentTray.modern_rating_button(@rubric.data[1][:ratings][1][:id], 1).click
    RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("comment 2")
    RubricAssessmentTray.modern_rating_button(@rubric.data[2][:ratings][2][:id], 2).click
    RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("comment 3")
    RubricAssessmentTray.submit_rubric_assessment_button.click

    expect(StudentAssignmentPageV2.peer_review_prompt_modal).to include_text("You have completed your Peer Reviews!")
  end

  it "students can assess with the vertical rubric view" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/?reviewee_id=#{@student2.id}"

    RubricAssessmentTray.rubric_assessment_view_mode_select.click
    RubricAssessmentTray.rubric_vertical_view_option.click
    RubricAssessmentTray.modern_rating_button(@rubric.data[0][:ratings][0][:id], 0).click
    RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("comment 1")
    RubricAssessmentTray.modern_rating_button(@rubric.data[1][:ratings][1][:id], 1).click
    RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("comment 2")
    RubricAssessmentTray.modern_rating_button(@rubric.data[2][:ratings][2][:id], 2).click
    RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("comment 3")
    RubricAssessmentTray.submit_rubric_assessment_button.click

    expect(StudentAssignmentPageV2.peer_review_prompt_modal).to include_text("You have completed your Peer Reviews!")
  end

  it "after receiving a rubric assessment from a peer a student can see the assessments on the assignment page" do
    RubricAssessment.create!({
                               artifact: @assignment.find_or_create_submission(@student1),
                               assessment_type: "peer_review",
                               assessor: @student2,
                               rubric: @rubric,
                               user: @student1,
                               score: 10.0,
                               data: [],
                               rubric_association: @ra,
                             })
    RubricAssessment.create!({
                               artifact: @assignment.find_or_create_submission(@student2),
                               assessment_type: "peer_review",
                               assessor: @student1,
                               rubric: @rubric,
                               user: @student2,
                               score: 10.0,
                               data: [],
                               rubric_association: @ra,
                             })
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    expect(StudentAssignmentPageV2.grader_select_dropdown.attribute(:value)).to eq("Student 2 (Student)")
  end

  it "after submitting the peer review, the student should have access to a read only version of their assessment" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/?reviewee_id=#{@student2.id}"

    RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
    RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("comment 1")
    RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
    RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("comment 2")
    RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
    RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("comment 3")
    RubricAssessmentTray.submit_rubric_assessment_button.click
    StudentAssignmentPageV2.peer_review_prompt_modal_close_button.click
    StudentAssignmentPageV2.view_rubric_button.click

    expect(RubricAssessmentTray.tray).to include_text("Peer Review Score")
    expect(RubricAssessmentTray.tray).to include_text("17 pts")
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).attribute(:readonly)).to eq("true")
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).attribute(:value)).to eq("10")
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[1][:id]).attribute(:readonly)).to eq("true")
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[1][:id]).attribute(:value)).to eq("7")
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[2][:id]).attribute(:readonly)).to eq("true")
    expect(RubricAssessmentTray.criterion_score_input(@rubric.data[2][:id]).attribute(:value)).to eq("0")
  end

  it "students can fill out free form rubric for a peer review" do
    @rubric.update!(free_form_criterion_comments: true)
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/?reviewee_id=#{@student2.id}"

    RubricAssessmentTray.free_form_comment_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
    RubricAssessmentTray.free_form_comment_area(@rubric.data[1][:id]).send_keys("Criterion 2 comment")
    RubricAssessmentTray.free_form_comment_area(@rubric.data[2][:id]).send_keys("Criterion 3 comment")
    RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).send_keys("10")
    RubricAssessmentTray.criterion_score_input(@rubric.data[1][:id]).send_keys("3")
    RubricAssessmentTray.criterion_score_input(@rubric.data[2][:id]).send_keys("1")
    RubricAssessmentTray.submit_rubric_assessment_button.click

    expect(StudentAssignmentPageV2.peer_review_prompt_modal).to include_text("You have completed your Peer Reviews!")
  end
end
