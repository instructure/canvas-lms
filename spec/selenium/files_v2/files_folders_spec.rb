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
    Account.site_admin.enable_feature! :files_a11y_rewrite_toggle
  end

  context "Folders" do
    context("as a teacher") do
      folder_name = "base folder"
      before(:once) do
        course_with_teacher(active_all: true)
      end

      before do
        user_session @teacher
        @teacher.set_preference(:files_ui_version, "v2")
        @base_folder = Folder.create!(name: folder_name, context: @course)
        get "/courses/#{@course.id}/files"
      end

      it "creates a new folder" do
        new_folder_name = "new-folder"
        create_folder(new_folder_name)
        expect(content).to include_text(new_folder_name)
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

      it "moves a folder using cog menu", priority: "1" do
        # Place the new folder into the base folder
        folder_to_move = "moved folder name"
        Folder.create!(name: folder_to_move, context: @course)
        get "/courses/#{@course.id}/files"
        move_file_from(2, :kebab_menu)
        expect(alert).to include_text("#{folder_to_move} successfully moved to #{folder_name}")
        table_item_by_name(@base_folder.name).click
        expect(get_item_content_files_table(1, 1)).to include(folder_to_move)
      end

      it "moves multiple folder using toolbar menu", priority: "1" do
        # Move the folders out of the base folder
        folder_to_move1 = "move-this-folder1"
        folder_to_move2 = "move-this-folder2"
        @folder_to_move1 = Folder.create!(name: folder_to_move1, parent_folder: @base_folder, context: @course)
        @folder_to_move2 = Folder.create!(name: folder_to_move2, parent_folder: @base_folder, context: @course)
        get "/courses/#{@course.id}/files/folder/base%20folder"
        get_row_header_files_table(1).click # select first folder
        get_row_header_files_table(2).click # select second folder
        toolbox_menu_button("more-button").click
        toolbox_menu_button("move-button").click
        move_folder_form_selector_root(@course.name).click # move all selected to root
        move_folder_move_button.click
        get "/courses/#{@course.id}/files"
        expect(get_item_content_files_table(2, 1)).to include(folder_to_move1)
        expect(get_item_content_files_table(3, 1)).to include(folder_to_move2)
      end

      it "moves a folder and a file using toolbar menu", priority: "1" do
        # Place the new items into the base folder
        folder_to_move = "move-this-folder"
        file_name = "move-this-file.pdf"
        Folder.create!(name: folder_to_move, context: @course)
        attachment_model(content_type: "application/pdf", context: @course, display_name: file_name)
        get "/courses/#{@course.id}/files"
        get_row_header_files_table(3).click # select the file
        move_file_from(2, :toolbar_menu)
        expect(alert).to include_text("#{folder_to_move} successfully moved to #{folder_name}")
        get "/courses/#{@course.id}/files/folder/base%20folder"
        expect(get_item_content_files_table(1, 1)).to include(folder_to_move)
        expect(get_item_content_files_table(2, 1)).to include(file_name)
      end

      it "deletes a folder using cog menu", priority: "1" do
        delete_file_from(1, :kebab_menu)
        expect(content).not_to contain_link(folder_name)
      end

      it "deletes a folder and contained file using toolbar", priority: "1" do
        file_name = "delete-this-file.pdf"
        attachment_model(content_type: "application/pdf", context: @course, display_name: file_name, folder: @base_folder)
        get "/courses/#{@course.id}/files"
        delete_file_from(1, :toolbar_menu)
        expect(content).not_to contain_link(folder_name)
        search_input.send_keys(file_name)
        search_button.click
        expect(content).to include_text("No results found")
      end

      it "deletes a folder and a file using toolbar", priority: "1" do
        file_name = "delete-this-file.pdf"
        attachment_model(content_type: "application/pdf", context: @course, display_name: file_name)
        get "/courses/#{@course.id}/files"
        get_row_header_files_table(1).click # select a folder
        delete_file_from(2, :toolbar_menu) # select a file and delete all selected
        expect(content).not_to contain_link(folder_name)
        expect(content).not_to contain_link(file_name)
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
        folder_link = flnpt(test_folder_name, content)
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

      it "unpublishes and publish a folder using cloud icon", priority: "1" do
        published_status_button.click
        edit_item_permissions(:unpublished)
        expect(unpublished_status_button).to be_present
        unpublished_status_button.click
        edit_item_permissions(:published)
        expect(published_status_button).to be_present
      end

      it "unpublishes and publish a folder using action menu", priority: "1" do
        action_menu_button.click
        action_menu_item_by_name("Edit Permissions").click
        edit_item_permissions(:available_with_link)
        expect(link_only_status_button).to be_present
      end

      it "unpublishes and publish a folder and a file using toolbar menu", priority: "1" do
        file_name = "edit-permission-file.pdf"
        attachment_model(content_type: "application/pdf", context: @course, display_name: file_name)
        get "/courses/#{@course.id}/files"
        get_row_header_files_table(2).click # select the file
        select_item_to_edit_from_kebab_menu(1)
        toolbox_menu_button("edit-permissions-button").click
        edit_item_permissions(:unpublished)
        all_item_unpublished?
        toolbox_menu_button("more-button").click
        toolbox_menu_button("edit-permissions-button").click
        edit_item_permissions(:published)
        all_item_published?
      end

      context "Usage Rights" do
        before :once do
          @course.usage_rights_required = true
          @course.save!
        end

        before do
          file_name = "edit-usage-rights-file.pdf"
          attachment_model(content_type: "application/pdf", context: @course, display_name: file_name, folder: @base_folder)
          get "/courses/#{@course.id}/files"
        end

        it "sets usage rights on a folder and contained file using cog menu", priority: "1" do
          action_menu_button.click
          action_menu_item_by_name("Manage Usage Rights").click
          set_usage_rights_in_modal(:creative_commons)
          # a11y: focus should go back to the element that was clicked.
          check_element_has_focus(action_menu_button)
          get "/courses/#{@course.id}/files/folder/base%20folder"
          verify_usage_rights_ui_updates(:creative_commons)
        end

        it "sets usage rights on a folder and contained file using toolbar menu", priority: "1" do
          select_item_to_edit_from_kebab_menu(1)
          toolbox_menu_button("manage-usage-rights-button").click
          set_usage_rights_in_modal(:public_domain)
          # a11y: focus should go back to the element that was clicked.
          check_element_has_focus(toolbox_menu_button("more-button"))
          get "/courses/#{@course.id}/files/folder/base%20folder"
          verify_usage_rights_ui_updates(:public_domain)
        end
      end
    end
  end
end
