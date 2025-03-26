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
#
require_relative "../common"
require_relative "pages/files_page"
require_relative "../helpers/files_common"
require_relative "../helpers/public_courses_context"

describe "files page with tools" do
  include_context "in-process server selenium tests"
  include FilesPage
  include FilesCommon

  before(:once) do
    Account.site_admin.enable_feature! :files_a11y_rewrite
  end

  context "file index tools" do
    before do
      course_with_teacher_logged_in

      @tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool.file_menu = { url: "http://www.example.com", text: "Import Stuff" }
      @tool.save!
    end

    it "is able to launch tool through action menu", :ignore_js_errors do
      file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "file1.pdf")
      get "/courses/#{@course.id}/files"
      action_menu_button.click
      action_menu_item_by_name(@tool.file_menu["text"]).click
      wait_for_ajaximations
      expect(driver.current_url).to include("/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=file_menu&files[]=#{file_attachment.id}")
    end
  end
end
