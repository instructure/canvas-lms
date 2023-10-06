# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../pages/gradebook_page"
require_relative "../setup/gradebook_setup"

describe "Gradebook Controls" do
  include_context "in-process server selenium tests"
  include GradebookSetup

  before(:once) do
    course_with_teacher(active_all: true)
  end

  before do
    user_session(@teacher)
  end

  context "using Gradebook dropdown" do
    # EVAL-3711 Remove ICE Evaluate feature flag
    it "navigates to Individual View when ICE feature flag is OFF", priority: "1" do
      @course.root_account.disable_feature!(:instui_nav)
      Gradebook.visit(@course)
      expect_new_page_load { Gradebook.gradebook_dropdown_item_click("Individual View") }
      expect(f("h1")).to include_text("Gradebook: Individual View")
    end

    # EVAL-3711 Remove ICE Evaluate feature flag
    it "navigates to Individual View when ICE feature flag is ON", priority: "1" do
      @course.root_account.enable_feature!(:instui_nav)
      Gradebook.visit(@course)
      expect_new_page_load { Gradebook.gradebook_dropdown_item_click("Individual View") }
      expect(Gradebook.gradebook_title).to include_text("Individual Gradebook")
    end

    it "navigates to Gradebook History", priority: "2" do
      Gradebook.visit(@course)
      expect_new_page_load { Gradebook.gradebook_dropdown_item_click("Gradebook History") }
      expect(driver.current_url).to include("/courses/#{@course.id}/gradebook/history")
    end

    it "navigates to Learning Mastery", priority: "1" do
      Account.default.set_feature_flag!("outcome_gradebook", "on")
      Gradebook.visit(@course)
      Gradebook.gradebook_dropdown_item_click("Learning Mastery")
      expect(fj('button:contains("Learning Mastery")')).to be_displayed
    end
  end

  context "using View dropdown" do
    it "shows Grading Period dropdown", priority: "1" do
      create_grading_periods("Fall Term")
      associate_course_to_term("Fall Term")

      Gradebook.visit(@course)
      Gradebook.select_view_dropdown
      Gradebook.select_filters
      Gradebook.select_view_filter("Grading Periods")
      expect(f(Gradebook.grading_period_dropdown_selector)).to be_displayed
    end

    it "shows Module dropdown", priority: "1" do
      @mods = Array.new(2) { |i| @course.context_modules.create! name: "Mod#{i}" }

      Gradebook.visit(@course)
      Gradebook.select_view_dropdown
      Gradebook.select_filters
      Gradebook.select_view_filter("Modules")

      expect(Gradebook.module_dropdown).to be_displayed
    end

    it "shows Section dropdown", priority: "1" do
      @section1 = @course.course_sections.create!(name: "Section One")

      Gradebook.visit(@course)
      Gradebook.select_view_dropdown
      Gradebook.select_filters
      Gradebook.select_view_filter("Sections")

      expect(Gradebook.section_dropdown).to be_displayed
    end

    it "hides unpublished assignments", priority: "1" do
      assign = @course.assignments.create! title: "I am unpublished"
      assign.unpublish

      Gradebook.visit(@course)
      Gradebook.select_view_dropdown
      Gradebook.select_show_unpublished_assignments

      expect(Gradebook.content_selector).not_to contain_css(".assignment-name")
    end
  end

  context "using Actions dropdown" do
    it "navigates to upload page", priority: "1" do
      @course.disable_feature!(:enhanced_gradebook_filters)
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector("import").click

      expect(driver.current_url).to include "courses/#{@course.id}/gradebook_upload/new"
    end
  end

  context "using enhanced filter actions" do
    it "navigates to upload page", priority: "1" do
      @course.enable_feature!(:enhanced_gradebook_filters)
      Gradebook.visit(@course)
      Gradebook.select_import(@course)

      expect(driver.current_url).to include "courses/#{@course.id}/gradebook_upload/new"
    end
  end
end
