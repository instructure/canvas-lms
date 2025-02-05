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

  context "Folders" do
    context("as a teacher") do
      before(:once) do
        course_with_teacher(active_all: true)
      end

      before do
        user_session @teacher
        get "/courses/#{@course.id}/files"
        create_folder_button.click
      end

      it "validates xss on folder text", priority: "1" do
        folder_name = '<script>alert("Hi");</script>'
        create_folder_input.send_keys(folder_name)
        create_folder_input.send_keys(:return)
        expect(content).to include_text('<script>alert("Hi");<_script>')
      end

      it "is able to create and view a new folder with uri characters" do
        skip("RCX-2975")
        folder_name = "this#could+be bad? maybe"
        create_folder_input.send_keys(folder_name)
        create_folder_input.send_keys(:return)
        folder = @course.folders.where(name: folder_name).first
        expect(folder).to_not be_nil
        file_name = "some silly file"
        @course.attachments.create!(display_name: file_name, uploaded_data: default_uploaded_data, folder:)
        folder_link = fln(folder_name, content)
        expect(folder_link).to be_present
        folder_link.click
        wait_for_ajaximations
      end

      it "handles duplicate folder names", priority: "1" do
        folder_name = "New Folder"
        create_folder_input.send_keys(folder_name)
        create_folder_input.send_keys(:return)
        create_folder_button.click
        create_folder_input.send_keys(folder_name)
        create_folder_input.send_keys(:return)
        expect(content).to include_text("New Folder 2")
      end
    end
  end
end
