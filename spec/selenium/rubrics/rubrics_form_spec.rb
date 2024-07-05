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
require_relative "pages/rubrics_index_page"
require_relative "pages/rubrics_form_page"
require_relative "pages/rubrics_assessment_tray"

describe "Rubric form page" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  before do
    course_with_teacher_logged_in
    student_in_course
    @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
    @submission = @assignment.find_or_create_submission(@student)
    @rubric1 = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: larger_rubric_data, points_possible: 12)
    @rubric2 = @course.rubrics.create!(title: "Rubric 2", user: @user, context: @course, data: smallest_rubric_data, points_possible: 10, free_form_criterion_comments: true)
    RubricAssociation.create!(rubric: @rubric1, context: @course, association_object: @course, purpose: "bookmark")
    rubric_assoc = RubricAssociation.generate(@teacher, @rubric2, @course, ActiveSupport::HashWithIndifferentAccess.new({
                                                                                                                          hide_score_total: "0",
                                                                                                                          purpose: "grading",
                                                                                                                          skip_updating_points_possible: false,
                                                                                                                          update_if_existing: true,
                                                                                                                          use_for_grading: "1",
                                                                                                                          association_object: @assignment
                                                                                                                        }))
    @rubric2.associate_with(@assignment, @course, purpose: "grading")
    RubricAssessment.create!({
                               artifact: @submission,
                               assessment_type: "grading",
                               assessor: @teacher,
                               rubric: @rubric2,
                               user: @student,
                               rubric_association: rubric_assoc,
                               data: [{ points: 3.0, description: "hello", comments: "hey hey" }]
                             })
    @course.root_account.enable_feature!(:enhanced_rubrics)
    get "/courses/#{@course.id}/rubrics"
  end

  it "does not allow a criterion to be saved without a name" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.add_criterion_button.click
    RubricsForm.save_criterion_button.click
    expect(RubricsForm.rubric_criterion_modal).to include_text("Criteria Name Required")

    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    expect(RubricsForm.criteria_row_names[0]).to include_text("Criterion 1")
  end

  it "does not allow a rubric to be saved without a name and one criterion" do
    RubricsIndex.create_rubric_button.click
    expect(RubricsForm.save_rubric_button).to be_disabled

    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    expect(RubricsForm.save_rubric_button).to be_disabled

    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click

    expect(RubricsForm.save_rubric_button).not_to be_disabled
  end

  it "does not save the rubric if cancel is selected" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.cancel_rubric_button.click

    expect(RubricsIndex.saved_rubrics_panel).not_to include_text("Rubric 4")
  end

  it "allows rubrics to be created" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.save_rubric_button.click

    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 4")
  end

  it "allows rubrics to be saved as a draft" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.save_as_draft_button.click

    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 4")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Draft")
  end

  it "allows creating rubrics with ratings scaled high to low" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.rubric_rating_order_select.click
    RubricsForm.high_low_rating_order.click
    RubricsForm.preview_rubric_button.click

    expect(RubricsForm.traditional_grid_rating_button(0)).to include_text("Exceeds")
    expect(RubricsForm.traditional_grid_rating_button(0)).to include_text("4 pts")
    expect(RubricsForm.traditional_grid_rating_button(4)).to include_text("No Evidence")
    expect(RubricsForm.traditional_grid_rating_button(4)).to include_text("0 pts")
  end

  it "allows creating rubrics with ratings scaled low to high" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.rubric_rating_order_select.click
    RubricsForm.low_high_rating_order.click
    RubricsForm.preview_rubric_button.click

    expect(RubricsForm.traditional_grid_rating_button(0)).to include_text("No Evidence")
    expect(RubricsForm.traditional_grid_rating_button(0)).to include_text("0 pts")
    expect(RubricsForm.traditional_grid_rating_button(4)).to include_text("Exceeds")
    expect(RubricsForm.traditional_grid_rating_button(4)).to include_text("4 pts")
  end

  it "creates criterion with an optional description" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.criterion_description_input.send_keys("Description 1")
    RubricsForm.save_criterion_button.click

    expect(RubricsForm.criteria_row_names[0]).to include_text("Criterion 1")
    expect(RubricsForm.criteria_row_description).to include_text("Description 1")
  end

  it "creates a default criterion with 5 ratings indexed 4 through 0" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.criterion_row_rating_accordion.click

    expect(RubricsForm.criterion_row_rating_accordion).to include_text("Rating Scale: 5")
    expect(RubricsForm.criterion_rating_scale_accordion_items[0]).to include_text("Exceeds")
    expect(RubricsForm.criterion_rating_scale_accordion_items[0]).to include_text("4 pts")
    expect(RubricsForm.criterion_rating_scale_accordion_items[2]).to include_text("Near")
    expect(RubricsForm.criterion_rating_scale_accordion_items[2]).to include_text("2 pts")
    expect(RubricsForm.criterion_rating_scale_accordion_items[4]).to include_text("No Evidence")
    expect(RubricsForm.criterion_rating_scale_accordion_items[4]).to include_text("0 pts")
  end

  it "allows adding a rating to the list" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.add_rating_row_button.click
    RubricsForm.rating_name_inputs[0].send_keys("new rating")
    RubricsForm.rating_description_inputs[0].send_keys("new rating description")
    RubricsForm.save_criterion_button.click
    RubricsForm.criterion_row_rating_accordion.click

    expect(RubricsForm.criterion_row_rating_accordion).to include_text("Rating Scale: 6")
    expect(RubricsForm.criterion_rating_scale_accordion_items[0]).to include_text("new rating")
    expect(RubricsForm.criterion_rating_scale_accordion_items[0]).to include_text("new rating description")
  end

  it "allows deleting a rating from the list" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.remove_rating_buttons[0].click
    RubricsForm.save_criterion_button.click
    RubricsForm.criterion_row_rating_accordion.click

    expect(RubricsForm.criterion_row_rating_accordion).to include_text("Rating Scale: 4")
  end

  it "does not allow adding a rating without a name" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.add_rating_row_button.click
    RubricsForm.save_criterion_button.click

    expect(RubricsForm.rubric_criterion_modal).to include_text("Rating Name Required")
  end

  it "allows deleting a criterion from an exisiting rubric" do
    expect(RubricsIndex.rubric_criterion_count(0)).to include_text("2")

    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.rubric_criteria_row_delete_button.click
    RubricsForm.save_rubric_button.click

    expect(RubricsIndex.rubric_criterion_count(0)).to include_text("1")
  end

  it "it will adjust the index of the other ratings when a rating is deleted" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")

    expect(RubricsForm.criterion_rating_scales.length).to eq(5)
    expect(RubricsForm.criterion_rating_scales[0]).to include_text("4")
    RubricsForm.remove_rating_buttons[2].click
    expect(RubricsForm.criterion_rating_scales.length).to eq(4)
    expect(RubricsForm.criterion_rating_scales[0]).to include_text("3")
  end

  it "does not save the criterion if cancel is selected" do
    expect(RubricsIndex.rubric_criterion_count(0)).to include_text("2")

    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.add_criterion_button.click
    RubricsForm.cancel_criterion_button.click
    RubricsForm.save_rubric_button.click

    expect(RubricsIndex.rubric_criterion_count(0)).to include_text("2")
  end

  it "allows duplicating any exisiting criterion" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.rubric_criteria_row_duplicate_buttons[0].click
    RubricsForm.criterion_name_input.send_keys(" Copy")
    RubricsForm.save_criterion_button.click

    expect(RubricsForm.criteria_row_names[2]).to include_text("Crit1 Copy")
  end

  it "allows changing the points associated with a rating and will change the order of points associated with ratings if out of order after edit" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.criterion_row_edit_buttons[0].click
    RubricsForm.criterion_rating_points_inputs[0].send_keys(:backspace)
    RubricsForm.criterion_rating_points_inputs[0].send_keys(:backspace)
    RubricsForm.criterion_rating_points_inputs[0].send_keys("5")
    RubricsForm.criterion_rating_points_inputs[0].send_keys(:tab)

    expect(RubricsForm.criterion_rating_points_inputs[0].attribute("value")).to eq("7")
    expect(RubricsForm.criterion_rating_points_inputs[1].attribute("value")).to eq("5")
  end

  it "informs the user that the rubric is in limited edit mode when a rubric is associated with an assignment" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click

    expect(RubricsForm.limited_edit_mode_message).to include_text("Editing is limited for this rubric as it has already been used for grading.")
  end

  it "does not allow changing the points associated with a rating when the rubric is in limited edit mode" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.criterion_row_edit_buttons[0].click

    expect(RubricsForm.non_editable_rating_points[0]).to include_text("10")
  end

  it "allows changing the rubric name when in limited edit mode" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.rubric_title_input.send_keys(" Edited")
    RubricsForm.save_rubric_button.click

    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 2 Edited")
  end

  it "allows changing the criterion name when in limited edit mode" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.criterion_row_edit_buttons[0].click
    RubricsForm.criterion_name_input.send_keys(" Edited")
    RubricsForm.save_criterion_button.click

    expect(RubricsForm.criteria_row_names[0]).to include_text("Crit1 Edited")
  end

  it "allows changing the criterion description when in limited edit mode" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.criterion_row_edit_buttons[0].click
    RubricsForm.criterion_description_input.send_keys(" Edited")
    RubricsForm.save_criterion_button.click

    expect(RubricsForm.criteria_row_description).to include_text("Edited")
  end

  it "allows changing the rating name when in limited edit mode" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.criterion_row_edit_buttons[0].click
    RubricsForm.rating_name_inputs[0].send_keys(" Edited")
    RubricsForm.save_criterion_button.click
    RubricsForm.criterion_row_rating_accordion.click

    expect(RubricsForm.criterion_rating_scale_accordion_items[0]).to include_text("A Edited")
  end

  it "allows changing the rating description when in limited edit mode" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.criterion_row_edit_buttons[0].click

    expect(RubricsForm.rating_description_inputs[0]).to_not be_disabled
  end

  it "allows previewing a rubric" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("Rubric 4")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.preview_rubric_button.click

    expect(RubricsForm.traditional_grid_rating_button(0)).to include_text("Exceeds")
    expect(RubricsForm.traditional_grid_rating_button(0)).to include_text("4 pts")
    expect(RubricsForm.traditional_grid_rating_button(4)).to include_text("No Evidence")
    expect(RubricsForm.traditional_grid_rating_button(4)).to include_text("0 pts")
  end

  it "allows free form comment rubrics to be previewed" do
    RubricsIndex.rubric_popover(@rubric2.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.preview_rubric_button.click

    expect(RubricAssessmentTray.free_form_comment_area(@rubric2.data[0][:id])).to be_displayed
    expect(RubricAssessmentTray.save_comment_checkbox(@rubric2.data[0][:id])).to be_displayed
  end

  it "preview mode allows input and updates the instructor score" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.preview_rubric_button.click
    RubricAssessmentTray.traditional_grid_rating_button(@rubric1.data[0][:id], 0).click

    expect(RubricAssessmentTray.rubric_assessment_instructor_score).to include_text("10 pts")
  end
end
