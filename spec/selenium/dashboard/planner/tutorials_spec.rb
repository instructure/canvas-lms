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

require_relative '../../common'

describe "Tutorials" do

  include_context "in-process server selenium tests"

  context "In Teacher Settings" do

    before(:once) do
      Account.default.enable_feature!(:new_user_tutorial)
      course_with_teacher(active_all: true, new_user: true)
    end

    before(:each) do
      user_session(@teacher)
      get "/profile/settings"
    end

    it "the course setup tutorial checkbox is uncheckable", priority: "1", test_id: 3165147 do
      element = f('#ff_toggle_new_user_tutorial_on_off')
      element.find_element(:xpath, "../../label").click
      expect(element[:checked]).to eq nil
    end

    it "the course setup tutorial checkbox is checkable", priority: "1", test_id: 3165148 do
      element = f('#ff_toggle_new_user_tutorial_on_off')
      button = element.find_element(:xpath, "../../label")
      button.click # Disable the button to check that it enables properly
      button.click
      expect(element[:checked]).to eq "true"
    end
  end

  context "In Course Pages" do

    before(:once) do
      Account.default.enable_feature!(:new_user_tutorial)
      course_with_teacher(active_all: true, new_user: true)
    end

    before(:each) do
      user_session(@teacher)
    end

    it "the tutorial tray appears on the home page", priority: "1", test_id: 3165149 do
      get "/courses/#{@course.id}"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Home")
      expect(element).to include_text("This is your course landing page")
      expect(element).to include_text("When people visit your course, this is the first page")
      expect(element).to include_text("You can publish your course from the home page")
    end

    it "the tutorial tray appears on the assignments page", priority: "1", test_id: 3165163 do
      get "/courses/#{@course.id}/assignments"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Assignments")
      expect(element).to include_text("Create content for your course")
      expect(element).to include_text("Create assignments on the Assignments page")
      expect(element).to include_text("Organize assignments into groups like Homework, In-class Work")
    end

    it "the tutorial tray appears on the announcements page", priority: "1", test_id: 3165168 do
      get "/courses/#{@course.id}/announcements"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Announcements")
      expect(element).to include_text("Share important updates with users")
      expect(element).to include_text("Share important information with all users in your course")
      expect(element).to include_text("Choose to get a copy of your own announcements")
    end

    it "the tutorial tray appears on the discussions page", priority: "1", test_id: 3165160 do
      get "/courses/#{@course.id}/discussion_topics"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Discussions")
      expect(element).to include_text("Encourage class participation")
      expect(element).to include_text("Create as many discussion topics as needed")
      expect(element).to include_text("assignments for grading or as a forum for shared ideas")
    end

    it "the tutorial tray appears on the grades page", priority: "1", test_id: 3165169 do
      get "/courses/#{@course.id}/gradebook"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Grades")
      expect(element).to include_text("Track individual student and class progress")
      expect(element).to include_text("Input and distribute grades for students.")
      expect(element).to include_text("Group assignments for grade weighting")
    end

    it "the tutorial tray appears on the users page", priority: "1", test_id: 3165167 do
      get "/courses/#{@course.id}/users"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("People")
      expect(element).to include_text("Add Students, TAs, and Observers to your course")
      expect(element).to include_text("Manage enrollment status, create groups, and add users")
    end

    it "the tutorial tray appears on the pages page", priority: "1", test_id: 3165162 do
      get "/courses/#{@course.id}/pages"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Pages")
      expect(element).to include_text("Create educational resources")
      expect(element).to include_text("Build Pages containing content and educational resources that")
      expect(element).to include_text("Include text, multimedia, and links")
    end

    it "the tutorial tray appears on the files page", priority: "1", test_id: 3165166 do
      get "/courses/#{@course.id}/files"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Files")
      expect(element).to include_text("Images, Documents, and more")
      expect(element).to include_text("Upload course files, syllabi, readings, or other documents")
      expect(element).to include_text("Lock folders to keep them hidden from students")
    end

    it "the tutorial tray appears on the syllabus page", priority:"1", test_id: 3165150 do
      get "/courses/#{@course.id}/assignments/syllabus"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Syllabus")
      expect(element).to include_text("An auto-generated chronological summary of your course")
      expect(element).to include_text("Communicate to your students exactly what will be required of")
      expect(element).to include_text("Generate a built-in Syllabus based on Assignments")
    end

    it "the tutorial tray appears on the quizzes page", priority: "1", test_id: 3165164 do
      get "/courses/#{@course.id}/quizzes"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Quizzes")
      expect(element).to include_text("Assess and survey your students")
      expect(element).to include_text("Create and administer online quizzes and surveys")
    end

    it "the tutorial tray appears on the modules page", priority: "1", test_id: 3165260 do
      get "/courses/#{@course.id}/modules"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Modules")
      expect(element).to include_text("Organize your course content")
      expect(element).to include_text("Organize and segment your course by topic, unit, chapter, or")
      expect(element).to include_text("Sequence select modules by defining criteria")
    end

    it "the tutorial tray appears on the settings page", priority: "1", test_id: 3165165 do
      get "/courses/#{@course.id}/settings#!/configurations"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Settings")
      expect(element).to include_text("Manage your course details")
      expect(element).to include_text("Update and view sections, course details")
      expect(element).to include_text("navigation, feature options and external app integrations")
    end

    it "the tutorial tray appears on the course import page", priority: "1", test_id: 3165153 do
      get "/courses/#{@course.id}/content_migrations"
      element = f('.NewUserTutorialTray')
      expect(element).to include_text("Import")
      expect(element).to include_text("Bring your content into your course")
      expect(element).to include_text("Bring existing content from")
      expect(element).to include_text("into your Canvas course")
    end

    it "the 'End Tutorial' button ends the tutorial", priority: "1", test_id: 3189025 do
      get "/courses/#{@course.id}"
      fj("button:contains('End Tutorial')").click
      wait_for_new_page_load do
        fj("button:contains('Okay')").click
      end
      expect(driver).not_to contain_css(".NewUserTutorialTray")
      get "/profile/settings"
      expect(f('#ff_toggle_new_user_tutorial_on_off')).not_to contain_css('[checked]')
    end

    it "the end tutorial 'x' button closes the modal", priority: "1", test_id: 3165170 do
      get "/courses/#{@course.id}"
      fj("button:contains('End Tutorial')").click
      fj("button:contains('Close')").click
      expect(f('.NewUserTutorialTray')).to be_displayed
      expect(driver).not_to contain_css("End Course Set-up Tutorial")
    end

    it "the end tutorial 'Cancel' button closes the modal", priority: "1", test_id: 3189026 do
      get "/courses/#{@course.id}"
      fj("button:contains('End Tutorial')").click
      fj("span button:contains('Cancel')").click
      expect(f('.NewUserTutorialTray')).to be_displayed
      expect(driver).not_to contain_css("End Course Set-up Tutorial")
    end

    it "the New User Tutorial description toggle button toggles the description", priority: "1", test_id: 3189023 do
      get "/profile/settings"
      feature_container = f("div[class*=new_user_tutorial]")
      description_container = f("div[id*=new_user_tutorial]")
      expect(description_container).not_to be_displayed
      description_toggle_button = f("span[class=element_toggler]", feature_container)
      description_toggle_button.click

      expect(description_container).to be_displayed
      expect(description_container).to include_text("Course set-up tutorial provides tips on how to")
      expect(description_container).to include_text("setting up a new course for the first time in a long time")

      description_toggle_button.click
      expect(description_container).not_to be_displayed
    end
  end

  context "as an admin" do
    before :once do
      course_with_teacher
      account_admin_user
    end

    before :each do
      user_session(@admin)
    end

    it "the tutorial feature flag can be enabled", priority: "1", test_id: 3165145 do
      get "/accounts/#{@course.account_id}/settings"
      f("li[aria-labelledby='tab-features-link']").click
      flag_container = f("div[class*=new_user_tutorial]")
      f('label', flag_container).click
      expect((f'input', flag_container)[:checked]).to eq "true"
    end
  end
end
