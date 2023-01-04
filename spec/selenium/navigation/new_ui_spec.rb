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
require_relative "../rcs/pages/rce_next_page"

describe "new ui" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include RCENextPage

  context "as teacher" do
    before do
      course_with_teacher_logged_in
    end

    it "breadcrumbs show for course navigation menu item", priority: "2" do
      get "/courses/#{@course.id}"
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course announcements navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/announcements"
      expect(f(".home + li + li .ellipsible")).to include_text("Announcements")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course assignments navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/assignments"
      expect(f(".home + li + li .ellipsible")).to include_text("Assignments")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course discussions navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/discussion_topics"
      expect(f(".home + li + li .ellipsible")).to include_text("Discussions")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course grades navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/gradebook"
      expect(f(".home + li + li .ellipsible")).to include_text("Grades")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course people navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/users"
      expect(f(".home + li + li .ellipsible")).to include_text("People")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course pages navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/wiki"
      expect(f(".home + li + li .ellipsible")).to include_text("Pages")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course files navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/files"
      expect(f("#breadcrumbs .ellipsis")).to include_text("Files")
      expect(f(".ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course syllabus navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/assignments/syllabus"
      expect(f(".home + li + li .ellipsible")).to include_text("Syllabus")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course outcomes navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/outcomes"
      expect(f(".home + li + li .ellipsible")).to include_text("Outcomes")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course quizzes navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/quizzes"
      expect(f(".home + li + li .ellipsible")).to include_text("Quizzes")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course modules navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/modules"
      expect(f(".home + li + li .ellipsible")).to include_text("Modules")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "breadcrumbs show for course settings navigation menu item", priority: "2" do
      get "/courses/#{@course.id}/settings"
      expect(f(".home + li + li .ellipsible")).to include_text("Settings")
      expect(f(".home + li .ellipsible")).to include_text(@course.course_code)
    end

    it "shows new files folder icon in course files", priority: "2" do
      get "/courses/#{@course.id}/files"
      add_folder
      # verifying new files folder icon css property still displays with new ui
      expect(f(".media-object.ef-big-icon.FilesystemObjectThumbnail.mimeClass-folder")).to be_displayed
    end

    it "does not override high contrast theme", priority: "2" do
      BrandableCSS.save_default!("css") # make sure variable css file is up to date
      @user.enable_feature!("high_contrast")
      get "/profile/settings"
      menu_link = f(".profile_settings.active")
      expect(menu_link.css_value("border-left")).to eq("2px solid rgb(45, 59, 69)")
      expect(menu_link.css_value("color")).to eq("rgba(45, 59, 69, 1)")
    end

    it "does not break tiny mce css", priority: "2" do
      skip_if_chrome("Chrome does not get these values properly")
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      mce_icons = f(".mce-ico")
      expect(mce_icons.css_value("font-family")).to eq("tinymce,Arial")
      expect(mce_icons.css_value("font-style")).to eq("normal")
      expect(mce_icons.css_value("font-weight")).to eq("400")
      expect(mce_icons.css_value("font-size")).to eq("16px")
      expect(mce_icons.css_value("vertical-align")).to eq("text-top")
      expect(mce_icons.css_value("display")).to eq("inline-block")
      expect(mce_icons.css_value("background-size")).to eq("cover")
      expect(mce_icons.css_value("width")).to eq("16px")
      expect(mce_icons.css_value("height")).to eq("16px")
    end
  end

  context "as student" do
    it "still has courses icon when only course is unpublished", priority: "1" do
      course_with_student_logged_in(active_course: false)
      get "/"
      # make sure that "courses" shows up in the global nav even though we only have an unpublisned course
      global_nav_courses_link = fj("#global_nav_courses_link")
      expect(global_nav_courses_link).to be_displayed
      global_nav_courses_link.click
      wait_for_ajaximations
      fj("[aria-label='Courses tray'] a:contains('All Courses')").click

      # and now actually go to the "/courses" page and make sure it shows up there too as "unpublisned"
      wait_for_ajaximations
      expect(fj("#my_courses_table .course-list-table-row .name")).to include_text(@course.name)
      expect(fj("#my_courses_table .course-list-table-row")).to include_text("This course has not been published.")
    end
  end
end
