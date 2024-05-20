# frozen_string_literal: true

# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../common"

describe "Tutorials" do
  include_context "in-process server selenium tests"

  context "In Course Pages" do
    before(:once) do
      Account.default.enable_feature!(:new_user_tutorial)
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
    end

    it "the tutorial tray appears on the home page", priority: "1" do
      get "/courses/#{@course.id}"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Home")
      expect(element).to include_text("Welcome your students")
      expect(element).to include_text("The Course Home Page is the first page students see")
      expect(element).to include_text("The Home Page can display the course participation activity stream")
    end

    it "the tutorial tray appears on the assignments page", priority: "1" do
      get "/courses/#{@course.id}/assignments"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Assignments")
      expect(element).to include_text("Reinforce student understanding")
      expect(element).to include_text("Assignments include quizzes, graded discussions")
      expect(element).to include_text("Create assignment groups to organize your assignments")
    end

    it "the tutorial tray appears on the announcements page", priority: "1" do
      get "/courses/#{@course.id}/announcements"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Announcements")
      expect(element).to include_text("Keep students informed")
      expect(element).to include_text("Share important information about your course with all users")
      expect(element).to include_text("Announcements can include text, multimedia, and files")
    end

    it "the tutorial tray appears on the discussions page", priority: "1" do
      get "/courses/#{@course.id}/discussion_topics"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Discussions")
      expect(element).to include_text("Encourage student discourse")
      expect(element).to include_text("Discussions allow students and instructors to communicate")
      expect(element).to include_text("Focused discussions are best suited")
    end

    it "the tutorial tray appears on the grades page", priority: "1" do
      get "/courses/#{@course.id}/gradebook"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Grades")
      expect(element).to include_text("Enter and distribute grades")
      expect(element).to include_text("Display grades as points, percentages")
      expect(element).to include_text("For simplified grading, use SpeedGrader")
    end

    it "the tutorial tray appears on the users page", priority: "1" do
      get "/courses/#{@course.id}/users"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("People")
      expect(element).to include_text("Know your users")
      expect(element).to include_text("You can also create student groups to house group assignments")
    end

    it "the tutorial tray appears on the pages page", priority: "1" do
      get "/courses/#{@course.id}/pages"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Pages")
      expect(element).to include_text("Create interactive course content")
      expect(element).to include_text("Pages let you create interactive content directly in Canvas")
      expect(element).to include_text("You can also allow students to contribute to specific pages")
    end

    it "the tutorial tray appears on the files page", priority: "1" do
      get "/courses/#{@course.id}/files"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Files")
      expect(element).to include_text("Store and share course assets")
      expect(element).to include_text("When you save assets in Files")
      expect(element).to include_text("Distribute files to students from your course folder")
    end

    it "the tutorial tray appears on the syllabus page", priority: "1" do
      get "/courses/#{@course.id}/assignments/syllabus"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Syllabus")
      expect(element).to include_text("Communicate course objectives")
      expect(element).to include_text("The Syllabus lets you welcome your course users")
      expect(element).to include_text("The Syllabus page can also display all assignments")
    end

    it "the tutorial tray appears on the quizzes page", priority: "1" do
      get "/courses/#{@course.id}/quizzes"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Quizzes")
      expect(element).to include_text("Assess student understanding")
      expect(element).to include_text("Use quizzes to challenge student understanding")
    end

    it "the tutorial tray appears on the modules page", priority: "1" do
      get "/courses/#{@course.id}/modules"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Modules")
      expect(element).to include_text("Organize course content")
      expect(element).to include_text("Use modules to organize your content and create a linear flow")
      expect(element).to include_text("Require prerequisites to be completed before moving")
    end

    it "the tutorial tray appears on the settings page", priority: "1" do
      get "/courses/#{@course.id}/settings#!/configurations"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Settings")
      expect(element).to include_text("Customize course details")
      expect(element).to include_text("Make your course your own!")
      expect(element).to include_text("You may also be able to adjust the course name")
    end

    it "the tutorial tray appears on the course import page", priority: "1" do
      get "/courses/#{@course.id}/content_migrations"
      element = f(".NewUserTutorialTray")
      expect(element).to include_text("Import")
      expect(element).to include_text("Bring existing content into your course")
      expect(element).to include_text("Easily import or copy content from another")
      expect(element).to include_text("such as Moodle or QTI")
    end

    it "the 'Don't Show Again' button ends the tutorial", priority: "1" do
      get "/courses/#{@course.id}"
      fj("button:contains('Don\\'t Show Again')").click
      wait_for_new_page_load do
        fj("button:contains('Okay')").click
      end
      expect(driver).not_to contain_css(".NewUserTutorialTray")
    end

    it "the 'x' button closes the End Course Set-up Tutorial modal", priority: "1" do
      get "/courses/#{@course.id}"
      fj("button:contains('Don\\'t Show Again')").click
      fj("span[data-testid='instui-modal-close'] button:contains('Close')").click
      expect(f(".NewUserTutorialTray")).to be_displayed
      expect(driver).not_to contain_css("End Course Set-up Tutorial")
    end

    it "the 'Cancel' button closes the End Course Set-up Tutorial modal", priority: "1" do
      get "/courses/#{@course.id}"
      fj("button:contains('Don\\'t Show Again')").click
      fj("span button:contains('Cancel')").click
      expect(f(".NewUserTutorialTray")).to be_displayed
      expect(driver).not_to contain_css("End Course Set-up Tutorial")
    end
  end
end
