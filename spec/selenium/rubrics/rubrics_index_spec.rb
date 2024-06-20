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

describe "Rubric index page" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  before do
    course_with_teacher_logged_in
    @assignment = @course.assignments.create!(name: "Assignment 1", points_possible: 30)
    @course.root_account.enable_feature!(:enhanced_rubrics)
    @rubric1 = @course.rubrics.create!(title: "Rubric 1", user: @user, context: @course, data: larger_rubric_data, points_possible: 12)
    @rubric2 = @course.rubrics.create!(title: "Rubric 2", user: @user, context: @course, data: largest_rubric_data, points_possible: 30)
    @rubric3 = @course.rubrics.create!(title: "Rubric 3", user: @user, context: @course, data: smallest_rubric_data, points_possible: 10)
    RubricAssociation.create!(rubric: @rubric1, context: @course, association_object: @course, purpose: "bookmark")
    RubricAssociation.create!(rubric: @rubric2, context: @course, association_object: @course, purpose: "bookmark")
    RubricAssociation.create!(rubric: @rubric3, context: @course, association_object: @course, purpose: "bookmark")
    @rubric2.associate_with(@assignment, @course, purpose: "grading")
    @rubric3.update!(workflow_state: "archived")
    get "/courses/#{@course.id}/rubrics"
  end

  it "lists saved rubrics under the saved rubrics tab" do
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 1")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 2")
  end

  it "lists archived rubrics under the archived rubrics tab" do
    RubricsIndex.archived_rubrics_tab.click

    expect(RubricsIndex.archived_rubrics_panel).to include_text("Rubric 3")
  end

  it "displays the total points associated with each rubric listed" do
    expect(RubricsIndex.rubric_total_points(0)).to include_text(@rubric1.points_possible.to_i.to_s)
    expect(RubricsIndex.rubric_total_points(1)).to include_text(@rubric2.points_possible.to_i.to_s)
  end

  it "displays the number of criteria associated with each rubric listed" do
    expect(RubricsIndex.rubric_criterion_count(0)).to include_text(@rubric1.data.length.to_s)
    expect(RubricsIndex.rubric_criterion_count(1)).to include_text(@rubric2.data.length.to_s)
  end

  it "displays the locations a rubric is used when clicking on the courses and assignments link" do
    expect(RubricsIndex.rubric_locations(0)).to include_text("-")
    expect(RubricsIndex.rubric_locations(1)).to include_text("courses and assignments")
    RubricsIndex.rubric_locations(1).click

    expect(RubricsIndex.used_location_modal).to include_text(@assignment.name)
    expect(RubricsIndex.used_location_modal).to include_text(@course.name)
  end

  it "allows sorting by rubric name ascending/descending" do
    RubricsIndex.rubric_name_header.click
    expect(RubricsIndex.rubric_title(0)).to include_text(@rubric1.title)
    expect(RubricsIndex.rubric_title(1)).to include_text(@rubric2.title)

    RubricsIndex.rubric_name_header.click
    expect(RubricsIndex.rubric_title(0)).to include_text(@rubric2.title)
    expect(RubricsIndex.rubric_title(1)).to include_text(@rubric1.title)
  end

  it "allows sorting by total points ascending/descending" do
    RubricsIndex.rubric_points_header.click
    expect(RubricsIndex.rubric_total_points(0)).to include_text(@rubric1.points_possible.to_i.to_s)
    expect(RubricsIndex.rubric_total_points(1)).to include_text(@rubric2.points_possible.to_i.to_s)

    RubricsIndex.rubric_points_header.click
    expect(RubricsIndex.rubric_total_points(0)).to include_text(@rubric2.points_possible.to_i.to_s)
    expect(RubricsIndex.rubric_total_points(1)).to include_text(@rubric1.points_possible.to_i.to_s)
  end

  it "allows sorting by criterion count ascending/descending" do
    RubricsIndex.rubric_criterion_header.click
    expect(RubricsIndex.rubric_criterion_count(0)).to include_text(@rubric1.data.length.to_s)
    expect(RubricsIndex.rubric_criterion_count(1)).to include_text(@rubric2.data.length.to_s)

    RubricsIndex.rubric_criterion_header.click
    expect(RubricsIndex.rubric_criterion_count(0)).to include_text(@rubric2.data.length.to_s)
    expect(RubricsIndex.rubric_criterion_count(1)).to include_text(@rubric1.data.length.to_s)
  end

  it "allows sorting by locations used ascending/descending" do
    RubricsIndex.rubric_locations_header.click
    expect(RubricsIndex.rubric_locations(0)).to include_text("courses and assignments")
    expect(RubricsIndex.rubric_locations(1)).to include_text("-")

    RubricsIndex.rubric_locations_header.click
    expect(RubricsIndex.rubric_locations(0)).to include_text("-")
    expect(RubricsIndex.rubric_locations(1)).to include_text("courses and assignments")
  end

  it "allows editing a rubric when clicking edit within the rubric popover" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.edit_rubric_button.click
    RubricsForm.rubric_title_input.send_keys(" Edited")
    RubricsForm.save_rubric_button.click

    expect(RubricsIndex.flash_message).to include_text("Rubric saved successfully")
    expect(RubricsIndex.rubric_title(0)).to include_text("Rubric 1 Edited")
  end

  it "allows searching for rubrics by name" do
    RubricsIndex.rubric_search_input.send_keys("Rubric")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 1")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 2")

    RubricsIndex.rubric_search_input.send_keys(" 1")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 1")
    expect(RubricsIndex.saved_rubrics_panel).not_to include_text("Rubric 2")
  end

  it "allows creating a new rubric with a name and at least one criterion when clicking create new rubric button" do
    RubricsIndex.create_rubric_button.click
    RubricsForm.rubric_title_input.send_keys("New Rubric")
    RubricsForm.add_criterion_button.click
    RubricsForm.criterion_name_input.send_keys("Criterion 1")
    RubricsForm.save_criterion_button.click
    RubricsForm.save_rubric_button.click

    expect(RubricsIndex.flash_message).to include_text("Rubric saved successfully")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("New Rubric")
  end

  it "allows rubrics to be archived when clicking archive within the rubric popover when in the saved tab" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.archive_rubric_button.click
    expect(RubricsIndex.flash_message).to include_text("Rubric archived successfully")
    expect(RubricsIndex.saved_rubrics_panel).not_to include_text("Rubric 1")

    RubricsIndex.archived_rubrics_tab.click

    expect(RubricsIndex.archived_rubrics_panel).to include_text("Rubric 1")
  end

  it "allows rubrics to be unarchived when clicking unarchive within the rubric popover when in the archived tab" do
    RubricsIndex.archived_rubrics_tab.click
    RubricsIndex.rubric_popover(@rubric3.id).click
    RubricsIndex.unarchive_rubric_button.click
    expect(RubricsIndex.flash_message).to include_text("Rubric un-archived successfully")
    expect(RubricsIndex.archived_rubrics_panel).not_to include_text("Rubric 3")

    RubricsIndex.saved_rubrics_tab.click

    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 3")
  end

  it "allows rubrics to be deleted when clicking delete within the rubric popover" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.delete_rubric_button.click
    RubricsIndex.delete_rubric_modal_button.click

    expect(RubricsIndex.flash_message).to include_text("Rubric deleted successfully")
    expect(RubricsIndex.saved_rubrics_panel).not_to include_text("Rubric 1")
  end

  it "disables the rubric delete button when the rubric is associated with an assignment" do
    RubricsIndex.rubric_popover(@rubric2.id).click

    expect(RubricsIndex.delete_rubric_button).to be_disabled
  end

  it "allows a rubric to be duplicated when clicking duplicate within the rubric popover" do
    RubricsIndex.rubric_popover(@rubric1.id).click
    RubricsIndex.duplicate_rubric_button.click
    RubricsIndex.duplicate_rubric_modal_button.click

    expect(RubricsIndex.flash_message).to include_text("Rubric duplicated successfully")
    expect(RubricsIndex.saved_rubrics_panel).to include_text("Rubric 1 Copy")
  end

  it "displays a preview of the rubric when clicking the rubric name" do
    RubricsIndex.rubric_title_preview_link(@rubric2.id).click

    expect(RubricsIndex.rubric_assessment_tray).to be_displayed
  end
end
