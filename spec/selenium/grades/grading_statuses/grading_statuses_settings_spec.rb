# frozen_string_literal: true

#
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
require_relative "../../common"
require_relative "../pages/grading_statuses_page"

describe "grading statuses settings" do
  include_context "in-process server selenium tests"
  before do
    Account.site_admin.enable_feature!(:custom_gradebook_statuses)
    admin_logged_in
    GradingStatusesPage.visit(Account.default.id)
  end

  it "displays a tab for grading status settings" do
    expect(GradingStatusesPage.grading_statuses_tab).to be_displayed
  end

  describe "standard grading statuses" do
    before do
      GradingStatusesPage.grading_statuses_tab.click
    end

    it "displays the standard grading statuses" do
      expect(GradingStatusesPage.standard_statuses[0]).to include_text("Late")
      expect(GradingStatusesPage.standard_statuses[1]).to include_text("Missing")
      expect(GradingStatusesPage.standard_statuses[2]).to include_text("Resubmitted")
      expect(GradingStatusesPage.standard_statuses[3]).to include_text("Dropped")
      expect(GradingStatusesPage.standard_statuses[4]).to include_text("Excused")
      expect(GradingStatusesPage.standard_statuses[5]).to include_text("Extended")
    end

    it "color can be edited with the color picker" do
      GradingStatusesPage.standard_status_edit_buttons[0].click
      expect { GradingStatusesPage.color_picker_option("#FFE8E5").click }.to change { GradingStatusesPage.color_input.attribute("value") }.from("#E5F3FC").to("#FFE8E5")
    end

    it "color can be edited with the color input" do
      GradingStatusesPage.standard_status_edit_buttons[0].click
      GradingStatusesPage.color_input.send_keys([:control, "a"], :backspace)
      GradingStatusesPage.color_input.send_keys("FFE8E5")
      expect(GradingStatusesPage.color_input.attribute("value")).to eq("#FFE8E5")
      expect(GradingStatusesPage.color_picker_option("#FFE8E5")).to include_text("Currently Selected Color")
    end
  end

  describe "custom grading statuses" do
    before do
      GradingStatusesPage.grading_statuses_tab.click
    end

    it "displays three buttons to add custom grading statuses" do
      expect(GradingStatusesPage.new_custom_status_buttons[0]).to include_text("Add Status")
      expect(GradingStatusesPage.new_custom_status_buttons[1]).to include_text("Add Status")
      expect(GradingStatusesPage.new_custom_status_buttons[2]).to include_text("Add Status")
      expect(GradingStatusesPage.new_custom_status_buttons).to have_size(3)
    end

    it "can be created with a custom name and color" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 1")
      expect { GradingStatusesPage.color_picker_option("#F8EAF6").click }.to change { GradingStatusesPage.color_input.attribute("value") }.from("#FFE8E5").to("#F8EAF6")
      GradingStatusesPage.save_status_button.click
      expect(GradingStatusesPage.existing_custom_statuses[0]).to include_text("Custom 1")
    end

    it "can be deleted" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 1")
      GradingStatusesPage.save_status_button.click
      expect(GradingStatusesPage.new_custom_status_buttons).to have_size(2)
      GradingStatusesPage.delete_custom_status_buttons.first.click
      GradingStatusesPage.confirm_delete_button.click
      expect(GradingStatusesPage.new_custom_status_buttons).to have_size(3)
    end

    it "name can be edited" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 1")
      GradingStatusesPage.save_status_button.click
      GradingStatusesPage.standard_status_edit_buttons[6].click
      GradingStatusesPage.custom_status_name_input.send_keys([:control, "a"], :backspace)
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 2")
      GradingStatusesPage.save_status_button.click
      expect(GradingStatusesPage.existing_custom_statuses[0]).to include_text("Custom 2")
    end

    it "color can be edited" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 1")
      GradingStatusesPage.save_status_button.click
      GradingStatusesPage.standard_status_edit_buttons[6].click
      expect { GradingStatusesPage.color_picker_option("#F8EAF6").click }.to change { GradingStatusesPage.color_input.attribute("value") }.from("#FFE8E5").to("#F8EAF6")
      GradingStatusesPage.save_status_button.click
    end

    it "can create up to 3 custom statuses" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 1")
      GradingStatusesPage.save_status_button.click
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 2")
      GradingStatusesPage.save_status_button.click
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.custom_status_name_input.send_keys("Custom 3")
      GradingStatusesPage.save_status_button.click
      expect(GradingStatusesPage.existing_custom_statuses).to have_size(3)
    end

    it "cannot be saved without a name" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      expect(GradingStatusesPage.save_status_button).to be_disabled
    end

    it "cannot be saved without a color" do
      GradingStatusesPage.new_custom_status_buttons.first.click
      GradingStatusesPage.color_input.send_keys([:control, "a"], :backspace)
      expect(GradingStatusesPage.save_status_button).to be_disabled
    end
  end
end
