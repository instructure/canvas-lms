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
      folder_name = "base folder"
      before(:once) do
        course_with_teacher(active_all: true)
      end

      before do
        user_session @teacher
        get "/courses/#{@course.id}/files"
        create_folder(folder_name)
      end

      it "displays the new folder form" do
        create_folder_button.click
        expect(body).to contain_css(create_folder_form_selector)
      end

      it "creates a new folder" do
        expect(content).to include_text(folder_name)
      end

      it "displays all cog icon options" do
        expect(content).to include_text(folder_name)
        get_item_files_table(1, 7).click
        expect(action_menu_item_by_name("Download")).to be_displayed
        expect(action_menu_item_by_name("Rename")).to be_displayed
        expect(action_menu_item_by_name("Move To...")).to be_displayed
        expect(action_menu_item_by_name("Delete")).to be_displayed
      end

      it "edits folder name" do
        folder_rename_to = "edited folder name"
        edit_name_from_kebab_menu(1, folder_rename_to)
        expect(content).to include_text(folder_rename_to)
        expect(folder_rename_to).to be_present
      end

      it "validates xss on folder text", priority: "1" do
        test_folder_name = '<script>alert("Hi");</script>'
        create_folder_button.click
        create_folder_input.send_keys(test_folder_name)
        create_folder_input.send_keys(:return)
        expect(content).to include_text('<script>alert("Hi");<_script>')
      end

      it "moves a folder", priority: "1" do
        folder_to_move = "moved folder name"
        create_folder(folder_to_move)
        move_file_from(2, :kebab_menu)
        expect(alert).to include_text("#{folder_to_move} successfully moved to #{folder_name}")
        get "/courses/#{@course.id}/files/folder/base%20folder"
        expect(get_item_content_files_table(1, 1)).to eq folder_to_move
      end

      it "deletes a folder from cog icon", priority: "1" do
        delete_file_from(1, :kebab_menu)
        expect(content).not_to contain_link(folder_name)
      end

      it "deletes folder from toolbar", priority: "1" do
        delete_file_from(1, :toolbar_menu)
        expect(content).not_to contain_link(folder_name)
      end

      it "is able to create and view a new folder with uri characters" do
        test_folder_name = "this#could+be bad? maybe"
        create_folder_button.click
        create_folder_input.send_keys(test_folder_name)
        create_folder_input.send_keys(:return)
        folder = @course.folders.where(name: test_folder_name).first
        expect(folder).to_not be_nil
        file_name = "some silly file"
        @course.attachments.create!(display_name: file_name, uploaded_data: default_uploaded_data, folder:)
        folder_link = fln(test_folder_name, content)
        expect(folder_link).to be_present
        folder_link.click
        wait_for_ajaximations
      end

      it "handles duplicate folder names", priority: "1" do
        test_folder_name = "New Folder"
        create_folder_button.click
        create_folder_input.send_keys(test_folder_name)
        create_folder_input.send_keys(:return)
        create_folder_button.click
        create_folder_input.send_keys(test_folder_name)
        create_folder_input.send_keys(:return)
        expect(content).to include_text("New Folder 2")
      end
    end
  end
end
