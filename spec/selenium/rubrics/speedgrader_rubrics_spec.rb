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

describe "Rubrics in speedgrader" do
  include_context "in-process server selenium tests"
  include RubricsCommon
  include SpeedGrader

  describe "with ratings" do
    before do
      course_with_teacher_logged_in
      student_in_course
      @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
      @submission = @assignment.find_or_create_submission(@student)
      @course.root_account.enable_feature!(:enhanced_rubrics)
      @rubric = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: largest_rubric_data, points_possible: 30)
      RubricAssociation.create!(rubric: @rubric, context: @course, association_object: @course, purpose: "bookmark")
      @rubric.associate_with(@assignment, @course, purpose: "grading")
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    it "opens the rubric assessment tray when the “View Rubric” button is clicked" do
      Speedgrader.view_rubric_button.click

      expect(RubricAssessmentTray.tray).to be_displayed
    end

    it "allows assessing a submission in traditional view by selecting ratings and clicking submit assessment" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:description])
      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).to include_text(@rubric.data[1][:ratings][1][:description])
      expect(Speedgrader.rating_tiers[1]).to include_text(@rubric.data[1][:ratings][1][:points].to_s)
      expect(Speedgrader.rating_tiers[2]).to include_text(@rubric.data[2][:ratings][2][:description])
      expect(Speedgrader.rating_tiers[2]).to include_text(@rubric.data[2][:ratings][2][:points].to_s)
      expect(Speedgrader.rubric_total_points).to include_text("17")
    end

    it "allows adding comments to each criterion rating in traditional view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click

      RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
      RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("Criterion 2 comment")
      RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("Criterion 3 comment")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text("Criterion 1 comment")
      expect(Speedgrader.rating_tiers[1]).to include_text("Criterion 2 comment")
      expect(Speedgrader.rating_tiers[2]).to include_text("Criterion 3 comment")
    end

    it "allows clearing out a comment with the clear button in traditional view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
      RubricAssessmentTray.clear_comment_button(@rubric.data[0][:id]).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).not_to include_text("Criterion 1 comment")
    end

    it "updates the instructor score as rating selections are made" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      expect(RubricAssessmentTray.rubric_assessment_instructor_score).to include_text("10 pts")
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      expect(RubricAssessmentTray.rubric_assessment_instructor_score).to include_text("17 pts")
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      expect(RubricAssessmentTray.rubric_assessment_instructor_score).to include_text("17 pts")
    end

    it "saves the ratings made in one view when switching to another" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_horizontal_view_option.click

      expect(RubricAssessmentTray.rating_details(@rubric.data[0][:ratings][0][:id])).to include_text(@rubric.data[0][:ratings][0][:description])
      expect(RubricAssessmentTray.rating_details(@rubric.data[1][:ratings][1][:id])).to include_text(@rubric.data[1][:ratings][1][:description])
      expect(RubricAssessmentTray.rating_details(@rubric.data[2][:ratings][2][:id])).to include_text(@rubric.data[2][:ratings][2][:description])
      expect(RubricAssessmentTray.modern_criterion_points_inputs(@rubric.data[0][:id]).attribute(:value)).to eq(@rubric.data[0][:ratings][0][:points].to_s)
      expect(RubricAssessmentTray.modern_criterion_points_inputs(@rubric.data[1][:id]).attribute(:value)).to eq(@rubric.data[1][:ratings][1][:points].to_s)
      expect(RubricAssessmentTray.modern_criterion_points_inputs(@rubric.data[2][:id]).attribute(:value)).to eq(@rubric.data[2][:ratings][2][:points].to_s)
    end

    it "allows assessing a submission in horizontal view by selecting ratings and clicking submit assessment" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_horizontal_view_option.click
      RubricAssessmentTray.modern_rating_button(@rubric.data[0][:ratings][0][:id], 0).click
      RubricAssessmentTray.modern_rating_button(@rubric.data[1][:ratings][1][:id], 1).click
      RubricAssessmentTray.modern_rating_button(@rubric.data[2][:ratings][2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:description])
      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).to include_text(@rubric.data[1][:ratings][1][:description])
      expect(Speedgrader.rating_tiers[1]).to include_text(@rubric.data[1][:ratings][1][:points].to_s)
      expect(Speedgrader.rating_tiers[2]).to include_text(@rubric.data[2][:ratings][2][:description])
      expect(Speedgrader.rating_tiers[2]).to include_text(@rubric.data[2][:ratings][2][:points].to_s)
      expect(Speedgrader.rubric_total_points).to include_text("17")
    end

    it "allows adding comments to each criterion rating in horizontal view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_horizontal_view_option.click

      RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
      RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("Criterion 2 comment")
      RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("Criterion 3 comment")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text("Criterion 1 comment")
      expect(Speedgrader.rating_tiers[1]).to include_text("Criterion 2 comment")
      expect(Speedgrader.rating_tiers[2]).to include_text("Criterion 3 comment")
    end

    it "allows clearing out a comment with the clear button in horizontal view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_vertical_view_option.click
      RubricAssessmentTray.modern_rating_button(@rubric.data[0][:ratings][0][:id], 0).click
      RubricAssessmentTray.modern_rating_button(@rubric.data[1][:ratings][1][:id], 1).click
      RubricAssessmentTray.modern_rating_button(@rubric.data[2][:ratings][2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:description])
      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).to include_text(@rubric.data[1][:ratings][1][:description])
      expect(Speedgrader.rating_tiers[1]).to include_text(@rubric.data[1][:ratings][1][:points].to_s)
      expect(Speedgrader.rating_tiers[2]).to include_text(@rubric.data[2][:ratings][2][:description])
      expect(Speedgrader.rating_tiers[2]).to include_text(@rubric.data[2][:ratings][2][:points].to_s)
      expect(Speedgrader.rubric_total_points).to include_text("17")
    end

    it "allows adding comments to each criterion rating in vertical view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_vertical_view_option.click

      RubricAssessmentTray.comment_text_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
      RubricAssessmentTray.comment_text_area(@rubric.data[1][:id]).send_keys("Criterion 2 comment")
      RubricAssessmentTray.comment_text_area(@rubric.data[2][:id]).send_keys("Criterion 3 comment")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text("Criterion 1 comment")
      expect(Speedgrader.rating_tiers[1]).to include_text("Criterion 2 comment")
      expect(Speedgrader.rating_tiers[2]).to include_text("Criterion 3 comment")
    end

    it "allows assessing the rubric by directly inputting a rating into the scoring text input in traditional view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).send_keys("10")
      RubricAssessmentTray.criterion_score_input(@rubric.data[1][:id]).send_keys("3")
      RubricAssessmentTray.criterion_score_input(@rubric.data[2][:id]).send_keys("1")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).to include_text("3 / 10")
      expect(Speedgrader.rating_tiers[2]).to include_text("1 / 10")
      expect(Speedgrader.rubric_total_points).to include_text("14")
    end

    it "allows assessing the rubric by directly inputting a rating into the scoring text input in horizontal view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_horizontal_view_option.click

      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[0][:id]).send_keys("10")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[1][:id]).send_keys("3")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[2][:id]).send_keys("1")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).to include_text("3 / 10")
      expect(Speedgrader.rating_tiers[2]).to include_text("1 / 10")
      expect(Speedgrader.rubric_total_points).to include_text("14")
    end

    it "allows assessing the rubric by directly inputting a rating into the scoring text input in vertical view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_vertical_view_option.click

      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[0][:id]).send_keys("10")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[1][:id]).send_keys("3")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[2][:id]).send_keys("1")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).to include_text("3 / 10")
      expect(Speedgrader.rating_tiers[2]).to include_text("1 / 10")
      expect(Speedgrader.rubric_total_points).to include_text("14")
    end

    it "allows viewing the criterion longer descriptions by clicking “view longer description" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.view_longer_description_link(0)).to be_displayed
      expect(Speedgrader.view_longer_description_link(1)).to be_displayed
      expect(Speedgrader.view_longer_description_link(2)).to be_displayed
    end
  end

  describe "with free form comments" do
    before do
      course_with_teacher_logged_in
      student_in_course
      @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
      @submission = @assignment.find_or_create_submission(@student)
      @course.root_account.enable_feature!(:enhanced_rubrics)
      @rubric = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: largest_rubric_data, points_possible: 30, free_form_criterion_comments: true)
      RubricAssociation.create!(rubric: @rubric, context: @course, association_object: @course, purpose: "bookmark")
      @rubric.associate_with(@assignment, @course, purpose: "grading")
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    it "allows assessing a rubric with free form comments by commenting and manually assigning a score in traditional view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.free_form_comment_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
      RubricAssessmentTray.free_form_comment_area(@rubric.data[1][:id]).send_keys("Criterion 2 comment")
      RubricAssessmentTray.free_form_comment_area(@rubric.data[2][:id]).send_keys("Criterion 3 comment")
      RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).send_keys("10")
      RubricAssessmentTray.criterion_score_input(@rubric.data[1][:id]).send_keys("3")
      RubricAssessmentTray.criterion_score_input(@rubric.data[2][:id]).send_keys("1")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.free_form_comment_ratings[0]).to include_text("Criterion 1 comment")
      expect(Speedgrader.free_form_comment_ratings[1]).to include_text("Criterion 2 comment")
      expect(Speedgrader.free_form_comment_ratings[2]).to include_text("Criterion 3 comment")
      expect(Speedgrader.free_form_comment_ratings[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.free_form_comment_ratings[1]).to include_text("3 / 10")
      expect(Speedgrader.free_form_comment_ratings[2]).to include_text("1 / 10")
      expect(Speedgrader.rubric_total_points).to include_text("14")
    end

    it "allows assessing a rubric with free form comments by commenting and manually assigning a score in horizontal view" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.rubric_assessment_view_mode_select.click
      RubricAssessmentTray.rubric_horizontal_view_option.click
      RubricAssessmentTray.free_form_comment_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")
      RubricAssessmentTray.free_form_comment_area(@rubric.data[1][:id]).send_keys("Criterion 2 comment")
      RubricAssessmentTray.free_form_comment_area(@rubric.data[2][:id]).send_keys("Criterion 3 comment")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[0][:id]).send_keys("10")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[1][:id]).send_keys("3")
      RubricAssessmentTray.modern_view_points_inputs(@rubric.data[2][:id]).send_keys("1")
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.free_form_comment_ratings[0]).to include_text("Criterion 1 comment")
      expect(Speedgrader.free_form_comment_ratings[1]).to include_text("Criterion 2 comment")
      expect(Speedgrader.free_form_comment_ratings[2]).to include_text("Criterion 3 comment")
      expect(Speedgrader.free_form_comment_ratings[0]).to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.free_form_comment_ratings[1]).to include_text("3 / 10")
      expect(Speedgrader.free_form_comment_ratings[2]).to include_text("1 / 10")
      expect(Speedgrader.rubric_total_points).to include_text("14")
    end

    it "allows saving a comment to be used later on the same criterion when selecting the checkbox and submitting the assessment" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.criterion_score_input(@rubric.data[0][:id]).send_keys("10")
      RubricAssessmentTray.free_form_comment_area(@rubric.data[0][:id]).send_keys("Criterion 1 comment")

      expect(RubricAssessmentTray.save_comment_checkbox(@rubric.data[0][:id])).to be_displayed
    end
  end

  describe "hidden points" do
    before do
      course_with_teacher_logged_in
      student_in_course
      @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
      @submission = @assignment.find_or_create_submission(@student)
      @course.root_account.enable_feature!(:enhanced_rubrics)
      @rubric = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: largest_rubric_data, points_possible: 30)
      RubricAssociation.create!(rubric: @rubric, context: @course, association_object: @course, purpose: "grading")
      ra = @rubric.associate_with(@assignment, @course, purpose: "grading")
      ra.update!(hide_points: true)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    it "does not show point values when assessing a rubric with hide points enabled in traditional view" do
      Speedgrader.view_rubric_button.click

      expect(RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0)).not_to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1)).not_to include_text(@rubric.data[1][:ratings][1][:points].to_s)
      expect(RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2)).not_to include_text(@rubric.data[2][:ratings][2][:points].to_s)
    end

    it "does not show point values in the rubric assessment view in the speedgrader tray after submitting an assessment" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rating_tiers[0]).not_to include_text(@rubric.data[0][:ratings][0][:points].to_s)
      expect(Speedgrader.rating_tiers[1]).not_to include_text(@rubric.data[1][:ratings][1][:points].to_s)
      expect(Speedgrader.rating_tiers[2]).not_to include_text(@rubric.data[2][:ratings][2][:points].to_s)
    end
  end

  describe "used for grading" do
    before do
      course_with_teacher_logged_in
      student_in_course
      @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
      @submission = @assignment.find_or_create_submission(@student)
      @course.root_account.enable_feature!(:enhanced_rubrics)
      @rubric = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: largest_rubric_data, points_possible: 30)
      RubricAssociation.create!(rubric: @rubric, context: @course, association_object: @course, purpose: "grading")
      @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    it "automatically fills in score in speedgrader when rubric is used for grading" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.grade_value).to eq("17")
    end
  end

  describe "hide rubric total" do
    before do
      course_with_teacher_logged_in
      student_in_course
      @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
      @submission = @assignment.find_or_create_submission(@student)
      @course.root_account.enable_feature!(:enhanced_rubrics)
      @rubric = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: largest_rubric_data, points_possible: 30)
      RubricAssociation.create!(rubric: @rubric, context: @course, association_object: @course, purpose: "grading")
      ra = @rubric.associate_with(@assignment, @course, purpose: "grading")
      ra.update!(hide_score_total: true)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    it "omits the total score from assessment results when “Hide score total for assessment results” is enabled" do
      Speedgrader.view_rubric_button.click

      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[0][:id], 0).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[1][:id], 1).click
      RubricAssessmentTray.traditional_grid_rating_button(@rubric.data[2][:id], 2).click
      RubricAssessmentTray.submit_rubric_assessment_button.click

      expect(Speedgrader.rubric_grid).not_to include_text("Total Points")
    end
  end
end
