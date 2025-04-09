# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "better_file_browsing" do
  include_context "in-process server selenium tests"
  include FilesPage
  include FilesCommon

  context "as a student" do
    txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
    before :once do
      Account.site_admin.enable_feature! :files_a11y_rewrite
      @student = course_with_student(active_all: true).user
    end

    before do
      user_session(@student)
    end

    context "in course with files" do
      before :once do
        @files = txt_files.map do |text_file|
          add_file(fixture_file_upload(text_file.to_s, "text/plain"), @course, text_file)
        end
      end

      it "searches for a file", priority: "1" do
        get "/courses/#{@course.id}/files"
        search_input.send_keys(txt_files[0])
        search_button.click
        expect(table_item_by_name(txt_files[0])).to be_displayed
      end

      it "does not return unpublished files in search results", priority: "1" do
        @files[0].update_attribute(:locked, true)
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student(txt_files[0])
      end

      it "does not return hidden files in search results", priority: "1" do
        @files[0].update_attribute(:hidden, true)
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student(txt_files[0])
      end

      it "does not see upload file, add folder buttons and cloud icon", priority: "1" do
        get "/courses/#{@course.id}/files"
        expect(content).not_to contain_css(upload_button_selector)
        expect(content).not_to contain_css(create_folder_button_selector)
        expect(get_item_content_files_table(1, 6)).to eq ""
      end

      it "only sees Download option on cog icon", priority: "1" do
        get "/courses/#{@course.id}/files"
        get_item_files_table(1, 7).click
        expect(action_menu_item_by_name("Download")).to be_displayed
        expect(content).not_to contain_css(action_menu_item_by_name_selector("Rename"))
        expect(content).not_to contain_css(action_menu_item_by_name_selector("Move To..."))
        expect(content).not_to contain_css(action_menu_item_by_name_selector("Delete"))
      end

      it "only sees Download options on toolbar menu", priority: "1" do
        get "/courses/#{@course.id}/files"
        get_row_header_files_table(1).click
        expect(bulk_actions_by_name("download")).to be_displayed
        expect(content).not_to contain_css(bulk_actions_by_name_selector("more"))
      end

      it "sees calendar icon on restricted files within a given timeframe", priority: "1" do
        @files[0].update unlock_at: 1.week.ago,
                         lock_at: 1.week.from_now
        get "/courses/#{@course.id}/files"
        expect(item_has_permissions_icon?(1, 6, "restricted")).to be true
      end
    end

    context "in course with folders" do
      before :once do
        @folder = folder_model(name: "restricted_folder", context: @course)
        @file = add_file(fixture_file_upload("example.pdf", "application/pdf"),
                         @course,
                         "example.pdf",
                         @folder)
      end

      it "does not return files from hidden folders in search results", priority: "1" do
        @folder.update_attribute :hidden, true
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("example")
      end

      it "does not return files from unpublished folders in search results", priority: "1" do
        @folder.update_attribute :locked, true
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("example")
      end
    end
  end
end
