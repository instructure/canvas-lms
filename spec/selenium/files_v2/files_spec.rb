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

      it "Displays files in table" do
        file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "file1.pdf")
        get "/courses/#{@course.id}/files"
        expect(f("#content")).to include_text(file_attachment.display_name)
      end

      it "Can navigate to subfolders" do
        folder = Folder.create!(name: "folder", context: @course)
        file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "subfile.pdf", folder:)
        get "/courses/#{@course.id}/files"
        table_item_by_name(folder.name).click
        expect(f("#content")).to include_text(file_attachment.display_name)
      end

      it "Displays the file usage bar if user has permission" do
        allow(Attachment).to receive(:get_quota).with(@course).and_return({ quota: 50_000_000, quota_used: 25_000_000 })
        get "/courses/#{@course.id}/files"
        expect(files_usage_text.text).to include("50% of 50 MB used")
      end

      it "Can create a new folder" do
        get "/courses/#{@course.id}/files"
        create_folder_button.click
        create_folder_input.send_keys("new folder")
        create_folder_input.send_keys(:return)
        expect(content).to include_text("new folder")
      end

      context("with a large number of files") do
        before do
          51.times do |i|
            attachment_model(content_type: "application/pdf", context: @course, size: 100 - i, display_name: "file#{i.to_s.rjust(2, "0")}.pdf")
          end
        end

        it "Can paginate through files" do
          get "/courses/#{@course.id}/files"
          pagination_button_by_index(1).click
          # that's just how sorting works
          expect(content).to include_text("file50.pdf")
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
            expect(content).to include_text("file50.pdf")
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

      it "displays new files UI", priority: "1" do
        get "/courses/#{@course.id}/files"
        create_folder_button.click
        create_folder_input.send_keys("new folder")
        create_folder_input.send_keys(:return)
        expect(upload_button).to be_displayed
        expect(all_files_table_rows.count).to eq 1
      end

      it "loads correct column values on uploaded file", priority: "1" do
        add_file(fixture_file_upload("example.pdf", "application/pdf"),
                 @course,
                 "example.pdf")
        get "/courses/#{@course.id}/files"
        time_current = format_time_only(@course.attachments.first.updated_at).strip
        expect(table_item_by_name("example.pdf")).to be_displayed
        expect(get_item_content_files_table(1, 1)).to eq "PDF File\nexample.pdf"
        expect(get_item_content_files_table(1, 2)).to eq time_current + "\n" + time_current
        expect(get_item_content_files_table(1, 3)).to eq time_current + "\n" + time_current
        expect(get_item_content_files_table(1, 5)).to eq "194 KB"
      end

      context "when a public course is accessed" do
        include_context "public course as a logged out user"

        it "displays course files", priority: "1" do
          public_course.attachments.create!(filename: "somefile.doc", uploaded_data: StringIO.new("test"))
          get "/courses/#{public_course.id}/files"
          expect(all_files_table_rows.count).to eq 1
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

        it "validates that file is published by default", priority: "1" do
          expect(get_item_content_files_table(1, 6)).to eq "a_file.txt is Published - Click to modify"
        end
      end

      context "Directory Header" do
        it "sorts the files properly", priority: 2 do
          # this test performs 2 sample sort combinations
          course_with_teacher_logged_in

          add_file(fixture_file_upload("example.pdf", "application/pdf"), @course, "a_example.pdf")
          add_file(fixture_file_upload("b_file.txt", "text/plain"), @course, "b_file.txt")

          get "/courses/#{@course.id}/files"

          # click name once to make it sort descending
          header_name_files_table.click
          expect(get_item_content_files_table(1, 1)).to eq "PDF File\nexample.pdf"
          expect(get_item_content_files_table(2, 1)).to eq "Text File\nb_file.txt"

          # click size twice to make it sort ascending
          header_name_files_table.click
          expect(get_item_content_files_table(1, 1)).to eq "Text File\nb_file.txt"
          expect(get_item_content_files_table(2, 1)).to eq "PDF File\nexample.pdf"
        end
      end

      it "Can search for files" do
        folder = Folder.create!(name: "parent", context: @course)
        file_attachment = attachment_model(content_type: "application/pdf", context: @course, display_name: "file1.pdf", folder:)
        get "/courses/#{@course.id}/files"
        search_input.send_keys(file_attachment.display_name)
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

      it "Can search for files" do
        folder = Folder.create!(name: "parent", context: @teacher)
        file_attachment = attachment_model(content_type: "application/pdf", context: @teacher, display_name: "file1.pdf", folder:)
        get "/files"

        table_item_by_name("My Files").click
        search_input.send_keys(file_attachment.display_name)
        expect(table_item_by_name(file_attachment.display_name)).to be_displayed
      end
    end
  end
end
