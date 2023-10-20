# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/assignment_overrides"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook/settings"
require_relative "../pages/gradebook_cells_page"

describe "Gradebook view options menu" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include GradebookCommon

  before(:once) do
    gradebook_data_setup
    @first_assignment.update(due_at: 1.day.ago)
    @first_assignment.unpublish!
    module1 = @course.context_modules.create!(name: "module1")
    module2 = @course.context_modules.create!(name: "module2")
    module1.add_item(type: "assignment", id: @first_assignment.id)
    module2.add_item(type: "assignment", id: @second_assignment.id)
    module2.add_item(type: "assignment", id: @third_assignment.id)
    Account.site_admin.enable_feature!(:enhanced_gradebook_filters)
    Account.site_admin.enable_feature!(:view_ungraded_as_zero)
    Account.site_admin.enable_feature!(:gradebook_show_first_last_names)
    @course.account.settings[:allow_gradebook_show_first_last_names] = true
    @course.account.save!
  end

  before do
    user_session(@teacher)
    Gradebook.visit(@course)
  end

  it "arranges the gradebook by assignment name from A-Z" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.assignment_name_ascend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@first_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@third_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@second_assignment.title)
  end

  it "arranges the gradebook by assignment name from Z-A" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.assignment_name_descend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@second_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@third_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@first_assignment.title)
  end

  it "arranges the gradebook by due date oldest to newest" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.due_date_ascend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@first_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@third_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@second_assignment.title)
  end

  it "arranges the gradebook by due date newest to oldest" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.due_date_descend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@second_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@third_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@first_assignment.title)
  end

  it "arranges the gradebook by assignment points possible from lowest to highest" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.points_ascend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@second_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@first_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@third_assignment.title)
  end

  it "arranges the gradebook by assignment points possible from highest to lowest" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.points_descend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@third_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@first_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@second_assignment.title)
  end

  it "arranges the gradebook by modules first to last" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.modules_ascend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@first_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@second_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@third_assignment.title)
  end

  it "arranges the gradebook by modules last to first" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.arrange_by_dropdown.click
    Gradebook::Settings.modules_descend.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).to include_text(@third_assignment.title)
    expect(Gradebook::Cells.assignments_header(2)).to include_text(@second_assignment.title)
    expect(Gradebook::Cells.assignments_header(3)).to include_text(@first_assignment.title)
  end

  it "toggles display of the notes custom column" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.notes_checkbox.click
    Gradebook::Settings.update_button.click

    expect(Gradebook.header_selector_by_col_index(2)).to include_text("Notes")
  end

  it "toggles display of unpublished assignments" do
    expect(Gradebook::Cells.assignments_header(1)).to include_text("UNPUBLISHED")
    expect(Gradebook::Cells.assignments_header(1)).to include_text(@first_assignment.title)

    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.unpublished_checkbox.click
    Gradebook::Settings.update_button.click

    expect(Gradebook::Cells.assignments_header(1)).not_to include_text("UNPUBLISHED")
    expect(Gradebook::Cells.assignments_header(1)).not_to include_text(@first_assignment.title)
  end

  it "toggles display of split student first and last names" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.split_names_checkbox.click
    Gradebook::Settings.update_button.click

    expect(Gradebook.header_selector_by_col_index(1)).to include_text("Last Name")
    expect(Gradebook.header_selector_by_col_index(2)).to include_text("First Name")
  end

  it "toggles display of viewing the totals column as if all ungraded assignments were given a 0" do
    Gradebook.gradebook_settings_cog.click
    Gradebook::Settings.click_view_options_tab
    Gradebook::Settings.ungraded_as_zero_checkbox.click
    Gradebook::Settings.ungraded_as_zero_confirm_button.click
    Gradebook::Settings.update_button.click

    expect(Gradebook.assignment_header_cell_element("Total").text).to include("UNGRADED AS 0")
    expect(Gradebook.assignment_header_cell_element("first assignment group").text).to include("UNGRADED AS 0")
  end
end
