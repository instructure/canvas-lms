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

describe "files index page" do
  include_context "in-process server selenium tests"
  include FilesPage

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
    end
  end
end
