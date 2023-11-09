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
require_relative "../helpers/files_common"

describe "better_file_browsing" do
  include_context "in-process server selenium tests"
  include FilesCommon

  context "as a student" do
    before :once do
      @student = course_with_student(active_all: true).user
    end

    before do
      user_session(@student)
    end

    def verify_hidden_item_not_searchable_as_student(search_text)
      f("input[type='search']").send_keys search_text.to_s, :return
      expect(f("body")).not_to contain_css(".ef-item-row")
    end

    context "in course with files" do
      before :once do
        txt_files = ["a_file.txt", "b_file.txt", "c_file.txt"]
        @files = txt_files.map do |text_file|
          add_file(fixture_file_upload(text_file.to_s, "text/plain"), @course, text_file)
        end
      end

      it "searches for a file", priority: "1" do
        get "/courses/#{@course.id}/files"
        f("input[type='search']").send_keys "b_fi", :return
        expect(all_files_folders).to have_size 1
      end

      it "does not return unpublished files in search results", priority: "1" do
        @files[0].update_attribute(:locked, true)
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("a_fi")
      end

      it "does not return hidden files in search results", priority: "1" do
        @files[0].update_attribute(:hidden, true)
        get "/courses/#{@course.id}/files"
        verify_hidden_item_not_searchable_as_student("a_fi")
      end

      it "does not see upload file, add folder buttons and cloud icon", priority: "1" do
        get "/courses/#{@course.id}/files"
        content = f("#content")
        expect(content).not_to contain_css(".btn-upload")
        expect(content).not_to contain_css(".btn-add-folder")
        expect(content).not_to contain_css(".btn-link.published-status")
      end

      it "only sees Download option on cog icon", priority: "1" do
        skip_if_safari(:alert)
        get "/courses/#{@course.id}/files"
        content = f("#content")
        f(".al-trigger-gray").click
        expect(fln("Download")).to be_displayed
        expect(content).not_to contain_link("Rename")
        expect(content).not_to contain_link("Move To...")
        expect(content).not_to contain_link("Delete")
      end

      it "only sees View and Download options on toolbar menu", priority: "1" do
        get "/courses/#{@course.id}/files"
        content = f("#content")
        f(".ef-item-row").click
        expect(f(".btn-download")).to be_displayed
        expect(f(".btn-view")).to be_displayed
        expect(content).not_to contain_css(".btn-move")
        expect(content).not_to contain_css(".btn-restrict")
        expect(content).not_to contain_css(".btn-delete")
      end

      it "sees calendar icon on restricted files within a given timeframe", priority: "1" do
        @files[0].update unlock_at: 1.week.ago,
                         lock_at: 1.week.from_now
        get "/courses/#{@course.id}/files"
        expect(f(".icon-calendar-day")).to be_displayed
        f(".icon-calendar-day").click
        wait_for_ajaximations
        expect(f("body")).not_to contain_css("[name=permissions]")
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

      it "lets student access files in restricted folder hidden by link", priority: "1" do
        skip "LF-999"
        @folder.update_attribute :hidden, true

        get "/courses/#{@course.id}/files/folder/restricted_folder?preview=#{@file.id}"
        refresh_page # the header seriously doesn't show up until you refres ¯\_(ツ)_/¯
        expect(f(".ef-file-preview-header")).to be_present
      end
    end
  end
end
