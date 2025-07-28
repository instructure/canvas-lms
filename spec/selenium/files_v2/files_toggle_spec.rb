# frozen_string_literal: true

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

require_relative "../common"
require_relative "pages/files_page"

describe "files index page" do
  include_context "in-process server selenium tests"
  include FilesPage

  before(:once) do
    Account.site_admin.enable_feature! :files_a11y_rewrite
  end

  context "With toggle flag" do
    before(:once) do
      course_with_teacher(active_all: true)
      Account.site_admin.enable_feature! :files_a11y_rewrite_toggle
    end

    before do
      user_session @teacher
      get "/courses/#{@course.id}/files"
      create_folder("base folder")
    end

    it "displays new UI when toggle is enabled and preference is v2" do
      @teacher.set_preference(:files_ui_version, "v2")
      get "/courses/#{@course.id}/files"
      expect(create_folder_button).to be_displayed
      expect(upload_button).to be_displayed
    end

    it "displays old UI when toggle is enabled and preference is v1" do
      @teacher.set_preference(:files_ui_version, "v1")
      get "/courses/#{@course.id}/files"
      expect(content).not_to contain_css(create_folder_button_selector)
      expect(content).not_to contain_css(upload_button_selector)
    end

    it "displays new UI when toggle is disabled" do
      @teacher.set_preference(:files_ui_version, "v1")
      Account.site_admin.disable_feature! :files_a11y_rewrite_toggle
      get "/courses/#{@course.id}/files"
      expect(create_folder_button).to be_displayed
      expect(upload_button).to be_displayed
    end

    it "displays old UI when toggle is enabled and preference is v2 but flag is off" do
      Account.site_admin.disable_feature! :files_a11y_rewrite
      Account.site_admin.enable_feature! :files_a11y_rewrite_toggle
      @teacher.set_preference(:files_ui_version, "v2")
      get "/courses/#{@course.id}/files"
      expect(content).not_to contain_css(create_folder_button_selector)
      expect(content).not_to contain_css(upload_button_selector)
    end

    it "persists user preference for files across canvas" do
      @teacher.set_preference(:files_ui_version, "v2")
      get "/courses/#{@course.id}/files"
      expect(switch_to_old_files_page_toggle).to be_displayed
      all_my_files_button.click
      expect(switch_to_old_files_page_toggle).to be_displayed
      switch_to_old_files_page_toggle.click
      expect(switch_to_new_files_page_toggle).to be_displayed
      get "/courses/#{@course.id}/files"
      expect(switch_to_new_files_page_toggle).to be_displayed
    end

    it "persists user preference after logout" do
      @teacher.set_preference(:files_ui_version, "v1")
      get "/courses/#{@course.id}/files"
      expect(switch_to_new_files_page_toggle).to be_displayed
      switch_to_new_files_page_toggle.click
      expect(switch_to_old_files_page_toggle).to be_displayed
      get "/logout"
      f("#Button--logout-confirm").click
      get "/login"
      get "/courses/#{@course.id}/files"
      expect(switch_to_old_files_page_toggle).to be_displayed
    end
  end
end
