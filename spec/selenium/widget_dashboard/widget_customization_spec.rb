# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "page_objects/widget_dashboard_page"
require_relative "../helpers/student_dashboard_common"

describe "student dashboard widget customization tests", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student)
  end

  before do
    user_session(@student)
  end

  it "enters and exits edit mode with save and cancel buttons" do
    go_to_dashboard

    click_widget_customize_button
    expect(save_customize_button).to be_displayed
    expect(cancel_customize_button).to be_displayed
    expect(widget_drag_handle("course-work-combined")).to be_displayed

    cancel_customize_button.click
    expect(customize_dashboard_button).to be_displayed
  end

  context "Rearrange widget via context menu" do
    it "moves widgets up and down using context menu options" do
      go_to_dashboard
      click_widget_customize_button

      expect(widget_drag_handle("people")).to be_displayed
      widget_drag_handle("people").click
      expect(widget_reorder_menu_option("Move up")).to be_displayed
      widget_reorder_menu_option("Move up").click
      wait_for_ajaximations

      column_2_widgets = all_widget_on_column(2)
      expect(column_2_widgets.length).to eq(2)
      expect(column_2_widgets[0].attribute("data-testid")).to eq("widget-container-people-widget")
      expect(column_2_widgets[1].attribute("data-testid")).to eq("widget-container-announcements-widget")

      widget_drag_handle("people").click
      expect(widget_reorder_menu_option("Move down")).to be_displayed
      widget_reorder_menu_option("Move down").click
      verify_reordered_widget_up_down

      click_save_customize_button
      verify_reordered_widget_up_down

      refresh_page
      verify_reordered_widget_up_down
    end

    it "moves widget to top and bottom using context menu option" do
      go_to_dashboard
      click_widget_customize_button

      expect(widget_drag_handle("course-work-combined")).to be_displayed
      widget_drag_handle("course-work-combined").click
      expect(widget_reorder_menu_option("Move to bottom")).to be_displayed
      widget_reorder_menu_option("Move to bottom").click
      wait_for_ajaximations

      column_1_widgets = all_widget_on_column(1)
      expect(column_1_widgets.length).to eq(2)
      expect(column_1_widgets[0].attribute("data-testid")).to eq("widget-container-course-grades-widget")
      expect(column_1_widgets[1].attribute("data-testid")).to eq("widget-container-course-work-combined-widget")

      widget_drag_handle("course-work-combined").click
      expect(widget_reorder_menu_option("Move to top")).to be_displayed
      widget_reorder_menu_option("Move to top").click
      verify_reordered_widget_top_bottom

      click_save_customize_button
      verify_reordered_widget_top_bottom

      refresh_page
      verify_reordered_widget_top_bottom
    end

    it "moves widgets between columns using context menu options" do
      go_to_dashboard
      click_widget_customize_button

      expect(widget_drag_handle("announcements")).to be_displayed
      widget_drag_handle("announcements").click
      expect(widget_reorder_menu_option("Move left bottom")).to be_displayed
      widget_reorder_menu_option("Move left bottom").click
      wait_for_ajaximations

      column_1_widgets = all_widget_on_column(1)
      column_2_widgets = all_widget_on_column(2)
      expect(column_1_widgets.length).to eq(3)
      expect(column_2_widgets.length).to eq(1)
      expect(column_1_widgets[2].attribute("data-testid")).to eq("widget-container-announcements-widget")

      widget_drag_handle("course-grades").click
      expect(widget_reorder_menu_option("Move right top")).to be_displayed
      widget_reorder_menu_option("Move right top").click
      verify_reordered_widget_btw_columns

      click_save_customize_button
      verify_reordered_widget_btw_columns

      refresh_page
      verify_reordered_widget_btw_columns
    end

    it "disables context menu options when they are not applicable" do
      go_to_dashboard
      click_widget_customize_button
      wait_for_ajaximations

      widget_drag_handle("course-work-combined").click
      expect(widget_reorder_menu_option("Move up").attribute("aria-disabled")).to eq("true")
      expect(widget_reorder_menu_option("Move to top").attribute("aria-disabled")).to eq("true")
      expect(widget_reorder_menu_option("Move left top").attribute("aria-disabled")).to eq("true")
      expect(widget_reorder_menu_option("Move left bottom").attribute("aria-disabled")).to eq("true")

      widget_drag_handle("people").click
      expect(widget_reorder_menu_option("Move down").attribute("aria-disabled")).to eq("true")
      expect(widget_reorder_menu_option("Move to bottom").attribute("aria-disabled")).to eq("true")
      expect(widget_reorder_menu_option("Move right top").attribute("aria-disabled")).to eq("true")
      expect(widget_reorder_menu_option("Move right bottom").attribute("aria-disabled")).to eq("true")
    end
  end

  context "Remove widget" do
    it "removes a widget" do
      go_to_dashboard
      click_widget_customize_button

      click_widget_remove_button("announcements")
      verify_widget_is_removed("announcements", 2)

      click_save_customize_button
      verify_widget_is_removed("announcements", 2)
      refresh_page
      verify_widget_is_removed("announcements", 2)
    end

    it "restores removed widget when canceling edit mode" do
      go_to_dashboard
      click_widget_customize_button
      click_widget_remove_button("announcements")
      verify_widget_is_removed("announcements", 2)

      cancel_customize_button.click
      expect(widget_container("announcements")).to be_displayed
    end
  end

  context "Add widget" do
    it "adds a widget via the add widget modal" do
      go_to_dashboard
      click_widget_customize_button

      expect(element_exists?(widget_container_selector("todo_list"))).to be_falsey
      click_add_widget_button
      expect(add_widget_modal_add_button("todo_list")).to be_displayed
      add_widget_modal_add_button("todo_list").click
      expect(widget_container("todo_list")).to be_displayed
      click_save_customize_button

      refresh_page
      wait_for_ajaximations
      expect(widget_container("todo_list")).to be_displayed
    end

    it "shows added status for widget that is already on dashboard" do
      go_to_dashboard
      click_widget_customize_button

      click_add_widget_button
      expect(add_widget_modal_added_button("course_grades")).to be_displayed
      expect(add_widget_modal_added_button("course_grades")).to have_attribute("disabled")
    end

    it "closes add widget modal without adding when close button is clicked" do
      go_to_dashboard
      verify_default_widget_count

      click_widget_customize_button
      click_add_widget_button
      expect(add_widget_modal_close_button).to be_displayed
      add_widget_modal_close_button.click

      expect(element_exists?(add_widget_modal_selector)).to be_falsey
      verify_default_widget_count
    end

    it "does not add widgets when canceling edit mode" do
      go_to_dashboard
      click_widget_customize_button
      click_add_widget_button

      expect(add_widget_modal_add_button("todo_list")).to be_displayed
      add_widget_modal_add_button("todo_list").click
      expect(widget_container("todo_list")).to be_displayed
      cancel_customize_button.click
      verify_default_widget_count
    end
  end
end
