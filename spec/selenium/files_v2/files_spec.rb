# frozen_string_literal: true

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

require_relative "../common"
require_relative "pages/files_page"
require_relative "../helpers/files_common"
require_relative "../helpers/public_courses_context"

describe "files index page" do
  include_context "in-process server selenium tests"
  include FilesPage
  include FilesCommon

  before(:once) do
    Account.site_admin.enable_feature! :files_a11y_rewrite
  end

  context("for a course") do
    context("as a teacher") do
      base_file_name = "example.pdf"
      before(:once) do
        course_with_teacher(active_all: true)
      end

      before do
        user_session @teacher
      end

      it "All My Files button links to user files" do
        get "/courses/#{@course.id}/files"
        all_my_files_button.click
        expect(heading).to include_text("All My Files")
      end

      it "Displays the file usage bar if user has permission" do
        allow(Attachment).to receive(:get_quota).with(@course).and_return({ quota: 50_000_000, quota_used: 25_000_000 })
        get "/courses/#{@course.id}/files"
        expect(files_usage_text.text).to include("25 MB of 50 MB used")
      end

      context("with a large number of files") do
        before do
          26.times do |i|
            attachment_model(content_type: "application/pdf", context: @course, size: 100 - i, display_name: "file#{i.to_s.rjust(2, "0")}.pdf")
          end
        end

        it "Can paginate through files" do
          get "/courses/#{@course.id}/files"
          pagination_button_by_index(1).click
          # that's just how sorting works
          expect(content).to include_text("file25.pdf")
        end

        it "Checks just one file" do
          get "/courses/#{@course.id}/files"
          # instui table checkboxes have weird DOM structure
          force_click_native(row_checkboxes_selector)
          expect(checked_boxes.count).to eq 1
        end

        describe "sorting" do
          it "Can sort by size" do
            get "/courses/#{@course.id}/files"
            column_heading_by_name("size").click
            expect(column_heading_by_name("size")).to have_attribute("aria-sort", "ascending")
          end

          it "Can paginate sorted files" do
            get "/courses/#{@course.id}/files"
            column_heading_by_name("size").click
            expect(column_heading_by_name("size")).to have_attribute("aria-sort", "ascending")
            pagination_button_by_index(1).click
            expect(content).to include_text("file00.pdf")
            pagination_button_by_index(0).click
            expect(content).to include_text("file25.pdf")
            expect(content).to include_text("file01.pdf")
          end

          it "resets to the first page when sorting changes" do
            get "/courses/#{@course.id}/files"
            column_heading_by_name("size").click
            expect(column_heading_by_name("size")).to have_attribute("aria-sort", "ascending")
            pagination_button_by_index(1).click
            expect(content).to include_text("file00.pdf")
            column_heading_by_name("name").click
            expect(content).to include_text("file00.pdf")
          end
        end
      end

      it "loads correct column values on uploaded file", priority: "1" do
        add_file(fixture_file_upload("example.pdf", "application/pdf"),
                 @course,
                 "example.pdf")
        get "/courses/#{@course.id}/files"
        time_current = format_time_only(@course.attachments.first.updated_at).strip
        expect(table_item_by_name("example.pdf")).to be_displayed
        expect(get_item_content_files_table(1, 1)).to eq "PDF File\nexample.pdf"
        expect(get_item_content_files_table(1, 2)).to eq time_current
        expect(get_item_content_files_table(1, 3)).to eq time_current
        expect(get_item_content_files_table(1, 5)).to eq "194 KB"
      end

      context "from cog icon" do
        a_txt_file_name = "a_file.txt"
        b_txt_file_name = "b_file.txt"
        before do
          add_file(fixture_file_upload(a_txt_file_name, "text/plain"),
                   @course,
                   a_txt_file_name)
          add_file(fixture_file_upload(b_txt_file_name, "text/plain"),
                   @course,
                   b_txt_file_name)
          get "/courses/#{@course.id}/files"
        end

        it "edits file name", priority: "1" do
          expect(a_txt_file_name).to be_present
          file_rename_to = "Example_edited.pdf"
          edit_name_from_kebab_menu(1, file_rename_to)
          expect(file_rename_to).to be_present
          expect(content).not_to contain_link(a_txt_file_name)
          action_button = get_item_files_table(1, 7).find_element(:css, "button")
          check_element_has_focus(action_button)
        end

        it "deletes file", priority: "1" do
          delete_file_from(1, :kebab_menu)
          expect(content).not_to contain_link(a_txt_file_name)
          action_button = get_item_files_table(1, 7).find_element(:css, "button")
          check_element_has_focus(action_button)
        end
      end

      context "from cloud icon" do
        before do
          add_file(fixture_file_upload(base_file_name, "application/pdf"),
                   @course,
                   base_file_name)
          get "/courses/#{@course.id}/files"
        end

        it "unpublishes and publish a file", priority: "1" do
          published_status_button.click
          edit_item_permissions(:unpublished)
          expect(unpublished_status_button).to be_present
          unpublished_status_button.click
          edit_item_permissions(:published)
          expect(published_status_button).to be_present
        end

        it "makes file available to student with link", priority: "1" do
          published_status_button.click
          edit_item_permissions(:available_with_link)
          expect(link_only_status_button).to be_present
        end
      end

      context "from toolbar menu" do
        a_txt_file_name = "a_file.txt"
        b_txt_file_name = "b_file.txt"
        before do
          add_file(fixture_file_upload(a_txt_file_name, "text/plain"),
                   @course,
                   a_txt_file_name)
          add_file(fixture_file_upload(b_txt_file_name, "text/plain"),
                   @course,
                   b_txt_file_name)
          get "/courses/#{@course.id}/files"
        end

        it "unpublishes and publish multiple files", priority: "1" do
          select_item_to_edit_from_kebab_menu(1)
          select_item_to_edit_from_kebab_menu(2)
          toolbox_menu_button("edit-permissions-button").click
          edit_item_permissions(:unpublished)
          all_item_unpublished?
          toolbox_menu_button("more-button").click
          toolbox_menu_button("edit-permissions-button").click
          edit_item_permissions(:published)
          all_item_published?
        end

        it "makes file available to student with link from toolbar", priority: "1" do
          select_item_to_edit_from_kebab_menu(1)
          toolbox_menu_button("edit-permissions-button").click
          edit_item_permissions(:available_with_link)
          expect(link_only_status_button).to be_present
        end

        it "deletes file from toolbar", priority: "1" do
          delete_file_from(1, :toolbar_menu)
          expect(content).not_to contain_link(a_txt_file_name)
          check_element_has_focus(select_all_checkbox)
        end

        it "deletes multiple files from toolbar", priority: "1" do
          get_row_header_files_table(1).click
          delete_file_from(2, :toolbar_menu)
          expect(content).not_to contain_link(a_txt_file_name)
          expect(content).not_to contain_link(b_txt_file_name)
        end
      end

      context "accessibility tests for preview" do
        before do
          add_file(fixture_file_upload(base_file_name, "application/pdf"),
                   @course,
                   base_file_name)
          get "/courses/#{@course.id}/files"
          get_item_files_table(1, 1).click
        end

        it "tabs through all buttons in the header button bar", priority: "1" do
          buttons = [preview_file_info_button, preview_download_icon_button]
          buttons[0].send_keys "" # focuses on the first button
          buttons.each do |button|
            check_element_has_focus(button)
            button.send_keys("\t")
          end
        end

        it "returns focus to the link that was clicked when closing with the esc key", priority: "1" do
          driver.switch_to.active_element.send_keys :escape
          check_element_has_focus(flnpt(base_file_name))
        end

        it "returns focus to the link when the close button is clicked", priority: "1" do
          preview_close_button.click
          check_element_has_focus(flnpt(base_file_name))
        end
      end

      context "File Preview" do
        a_txt_file_name = "a_file.txt"
        b_txt_file_name = "b_file.txt"
        mp3_file_name = "292.mp3"
        before do
          add_file(fixture_file_upload(a_txt_file_name, "text/plain"),
                   @course,
                   a_txt_file_name)
          add_file(fixture_file_upload(b_txt_file_name, "text/plain"),
                   @course,
                   b_txt_file_name)
          add_file(fixture_file_upload(mp3_file_name, "audio/mpeg"),
                   @course,
                   mp3_file_name)
          get "/courses/#{@course.id}/files"
        end

        it "switches files in preview when clicking the arrows" do
          get_item_files_table(2, 1).click
          preview_next_button.click
          expect(preview_file_header).to include_text(b_txt_file_name)
          preview_previous_button.click
          expect(preview_file_header).to include_text(a_txt_file_name)
        end

        context "with media file" do
          before do
            stub_kaltura
          end

          context "when consolidated_media_player feature is enabled" do
            before do
              Account.site_admin.enable_feature! :consolidated_media_player
            end

            it "works in the user's files page" do
              get "/files/folder/courses_#{@course.id}/"
              get_item_files_table(1, 1).click
              wait_for_ajaximations
              expect(preview_file_preview_modal_alert).to include_text("Your media has been uploaded and will appear here after processing.")
            end

            it "works in the course's files page" do
              get_item_files_table(1, 1).click
              wait_for_ajaximations
              expect(preview_file_preview_modal_alert).to include_text("Your media has been uploaded and will appear here after processing.")
            end
          end
        end
      end

      context "Usage Rights Dialog" do
        before :once do
          course_with_teacher(active_all: true)
          @course.usage_rights_required = true
          @course.save!
          add_file(fixture_file_upload("a_file.txt", "text/plan"),
                   @course,
                   "a_file.txt")
          add_file(fixture_file_upload("amazing_file.txt", "text/plan"),
                   @user,
                   "amazing_file.txt")
          add_file(fixture_file_upload("a_file.txt", "text/plan"),
                   @user,
                   "a_file.txt")
        end

        before do
          user_session @teacher
        end

        context "course files" do
          it "sets usage rights on a file via the modal by clicking the indicator", priority: "1" do
            get "/courses/#{@course.id}/files"
            file_usage_rights_cloud_icon.click
            set_usage_rights_in_modal(:creative_commons)
            # a11y: focus should go back to the element that was clicked.
            check_element_has_focus(file_usage_rights_cloud_icon)
            verify_usage_rights_ui_updates(:creative_commons)
          end

          it "sets usage rights on a file via the cog menu", priority: "1" do
            get "/courses/#{@course.id}/files"
            action_menu_button.click
            action_menu_item_by_name("Manage Usage Rights").click
            set_usage_rights_in_modal(:used_by_permission)
            # a11y: focus should go back to the element that was clicked.
            check_element_has_focus(action_menu_button)
            verify_usage_rights_ui_updates(:used_by_permission)
          end

          it "sets usage rights on a file via the toolbar", priority: "1" do
            get "/courses/#{@course.id}/files"
            select_item_to_edit_from_kebab_menu(1)
            toolbox_menu_button("manage-usage-rights-button").click
            set_usage_rights_in_modal(:public_domain)
            # a11y: focus should go back to the element that was clicked.
            check_element_has_focus(toolbox_menu_button("more-button"))
            verify_usage_rights_ui_updates(:public_domain)
          end

          it "sets usage rights on multiple files via the toolbar", priority: "1" do
            add_file(fixture_file_upload("b_file.txt", "text/plan"),
                     @course,
                     "b_file.txt")
            get "/courses/#{@course.id}/files"
            get_row_header_files_table(1).click
            select_item_to_edit_from_kebab_menu(2)
            toolbox_menu_button("manage-usage-rights-button").click
            set_usage_rights_in_modal(:fair_use)
            # a11y: focus should go back to the element that was clicked.
            check_element_has_focus(toolbox_menu_button("more-button"))
            verify_usage_rights_ui_updates(:fair_use)
          end

          it "sets usage rights on a file inside a folder via the toolbar", priority: "1" do
            folder_model name: "new folder"
            get "/courses/#{@course.id}/files"
            move_file_from(2, :toolbar_menu)
            wait_for_ajaximations
            action_menu_button.click
            action_menu_item_by_name("Manage Usage Rights").click
            expect(usage_rights_manage_modal).to include_text "new folder"
            set_usage_rights_in_modal(:creative_commons)
            # a11y: focus should go back to the element that was clicked.
            check_element_has_focus(action_menu_button)
            get_item_files_table(1, 1).click
            verify_usage_rights_ui_updates(:creative_commons)
          end

          it "does not show the creative commons selection if creative commons isn't selected", priority: "1" do
            get "/courses/#{@course.id}/files"
            file_usage_rights_cloud_icon.click
            file_usage_rights_justification.click
            usage_rights_selector_fair_use.click
            expect(usage_rights_manage_modal).not_to contain_css(usage_rights_license_selector)
          end

          it "sets focus to the close button when opening the file usage rights dialog", priority: "1" do
            get "/courses/#{@course.id}/files"
            file_usage_rights_cloud_icon.click
            wait_for_ajaximations
            element = driver.switch_to.active_element
            should_focus = permissions_dialog_close_button
            expect(element).to eq(should_focus)
          end
        end

        context "user files" do
          it "updates course files from user files page", priority: "1" do
            get "/files/folder/courses_#{@course.id}/"
            get_item_files_table(1, 6).click
            set_usage_rights_in_modal(:own_copyright)
            verify_usage_rights_ui_updates(:own_copyright)
          end
        end
      end

      context "When Require Usage Rights is turned-off" do
        a_txt_file_name = "a_file.txt"
        before do
          course_with_teacher_logged_in
          @course.usage_rights_required = false
          @course.save!
          add_file(fixture_file_upload(a_txt_file_name, "text/plain"),
                   @course,
                   a_txt_file_name)
        end

        it "sets files to published by default", priority: "1" do
          get "/courses/#{@course.id}/files"
          expect(item_has_permissions_icon?(1, 6, "published-button")).to be true
        end
      end

      context "when a public course is accessed" do
        include_context "public course as a logged out user"

        it "displays course files", priority: "1" do
          public_course.attachments.create!(filename: "somefile.doc", uploaded_data: StringIO.new("test"))
          get "/courses/#{public_course.id}/files"
          expect(all_files_table_rows.count).to eq 1
        end
      end

      context "Move dialog" do
        folder_name = "base folder"
        file_to_move = "a_file.txt"
        txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
        before do
          @base_folder = Folder.create!(name: folder_name, context: @course)
          txt_files.map do |text_file|
            add_file(fixture_file_upload(text_file.to_s, "text/plain"), @course, text_file)
          end
          get "/courses/#{@course.id}/files"
        end

        it "moves a file using cog icon", priority: "1" do
          move_file_from(2, :kebab_menu)
          expect(alert).to include_text("#{file_to_move} successfully moved to #{folder_name}")
          action_button = get_item_files_table(2, 7).find_element(:css, "button")
          check_element_has_focus(action_button)
          get "/courses/#{@course.id}/files/folder/base%20folder"
          expect(get_item_content_files_table(1, 1)).to eq "Text File\n#{file_to_move}"
        end

        it "moves multiple files", priority: "1" do
          files_to_move = ["a_file.txt", "b_file.txt", "c_file.txt"]
          move_files([2, 3, 4])
          files_to_move.map { |file| expect(alert).to include_text("#{file} successfully moved to #{folder_name}") }
          check_element_has_focus(select_all_checkbox)
          get "/courses/#{@course.id}/files/folder/base%20folder"
          files_to_move.each_with_index do |file, index|
            expect(get_item_content_files_table(index + 1, 1)).to eq "Text File\n#{file}"
          end
        end

        it "catches a collision error", priority: "1" do
          add_file(fixture_file_upload("a_file.txt", "text/plain"),
                   @course,
                   "a_file.txt",
                   @base_folder)
          move_file_from(2, :kebab_menu)
          expect(rename_change_button).to be_displayed
        end

        it "catches a collision error for multiple files", priority: "1" do
          add_file(fixture_file_upload("a_file.txt", "text/plain"),
                   @course,
                   "a_file.txt",
                   @base_folder)
          add_file(fixture_file_upload("b_file.txt", "text/plain"),
                   @course,
                   "b_file.txt",
                   @base_folder)
          move_files([2, 3, 4])
          expect(rename_change_button).to be_displayed
        end

        context "Search Results" do
          it "search and move a file" do
            search_input.send_keys(txt_files[0])
            search_button.click
            expect(table_item_by_name(txt_files[0])).to be_displayed
            move_file_from(1, :kebab_menu)
            expect(alert).to include_text("#{file_to_move} successfully moved to #{folder_name}")
            get "/courses/#{@course.id}/files/folder/base%20folder"
            expect(get_item_content_files_table(1, 1)).to eq "Text File\n#{file_to_move}"
          end
        end
      end

      context "Publish Cloud Dialog" do
        before(:once) do
          course_with_teacher(active_all: true)
          add_file(fixture_file_upload("a_file.txt", "text/plain"),
                   @course,
                   "a_file.txt")
        end

        before do
          user_session(@teacher)
          get "/courses/#{@course.id}/files"
        end

        it "sets focus to the close button when opening the permission edit dialog", priority: "1" do
          published_status_button.click
          wait_for_ajaximations
          element = driver.switch_to.active_element
          should_focus = permissions_dialog_close_button
          expect(element).to eq(should_focus)
        end
      end

      context "Directory Header" do
        it "sorts the files properly", priority: 2 do
          course_with_teacher_logged_in

          add_file(fixture_file_upload("example.pdf", "application/pdf"), @course, "a_example.pdf")
          add_file(fixture_file_upload("b_file.txt", "text/plain"), @course, "b_file.txt")

          get "/courses/#{@course.id}/files"

          header_name_files_table.click
          expect(get_item_content_files_table(1, 1)).to eq "PDF File\nexample.pdf"
          expect(get_item_content_files_table(2, 1)).to eq "Text File\nb_file.txt"

          header_name_files_table.click
          expect(get_item_content_files_table(1, 1)).to eq "Text File\nb_file.txt"
          expect(get_item_content_files_table(2, 1)).to eq "PDF File\nexample.pdf"

          header_name_files_table.click
          expect(get_item_content_files_table(1, 1)).to eq "PDF File\nexample.pdf"
          expect(get_item_content_files_table(2, 1)).to eq "Text File\nb_file.txt"
        end

        it "url-encodes sort header links" do
          course_with_teacher_logged_in
          Folder.root_folders(@course).first.sub_folders.create!(name: "eh?", context: @course)
          get "/courses/#{@course.id}/files/folder/eh%3F"
          expect(breadcrumb).to contain_css("li", text: "eh?")
        end
      end

      it "Can search for files" do
        folder = Folder.create!(name: "parent", context: @course)
        file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "file1.pdf", folder:)
        get "/courses/#{@course.id}/files"
        search_input.send_keys(file_attachment.display_name)
        search_button.click
        expect(table_item_by_name(file_attachment.display_name)).to be_displayed
      end
    end

    context("as a student") do
      before(:once) do
        course_with_student(active_all: true)
      end

      before do
        user_session @student
      end

      it "Does not display the file usage bar if user does not have permission" do
        file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "file1.pdf")
        file_attachment.publish!
        get "/courses/#{@course.id}/files"
        expect(content).not_to contain_css(files_usage_text_selector)
      end
    end
  end

  context("All My Files") do
    context("as a teacher") do
      before(:once) do
        course_with_teacher(active_all: true)
      end

      before do
        user_session @teacher
      end

      it "Displays related contexts" do
        get "/files"

        expect(table_rows[0]).to include_text("My Files")
        expect(table_rows[1]).to include_text(@course.name)
      end

      it "Can navigate through My Files" do
        folder = Folder.create!(name: "parent", context: @teacher)
        file_attachment = attachment_model(content_type: "application/pdf", context: @teacher, display_name: "file1.pdf", folder:)
        get "/files"

        table_item_by_name("My Files").click
        table_item_by_name(folder.name).click
        expect(table_item_by_name(file_attachment.display_name)).to be_displayed
      end

      it "Can navigate through course files" do
        folder = Folder.create!(name: "parent", context: @course)
        file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "file1.pdf", folder:)
        get "/files"

        table_item_by_name(@course.name).click
        table_item_by_name(folder.name).click
        expect(table_item_by_name(file_attachment.display_name)).to be_displayed
      end

      context "Search textbox" do
        it "Can search for files" do
          folder = Folder.create!(name: "parent", context: @teacher)
          file_attachment = attachment_model(content_type: "application/pdf", context: @teacher, display_name: "file1.pdf", folder:)
          get "/files"

          table_item_by_name("My Files").click
          search_input.send_keys(file_attachment.display_name)
          search_button.click
          expect(table_item_by_name(file_attachment.display_name)).to be_displayed
        end
      end
    end
  end
end
