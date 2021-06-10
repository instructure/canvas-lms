# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../pages/k5_dashboard_common_page'
require_relative '../pages/k5_grades_tab_page'
require_relative '../pages/k5_modules_tab_page'
require_relative '../pages/k5_resource_tab_page'
require_relative '../../../helpers/k5_common'

describe "student k5 course dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5GradesTabPageObject
  include K5ModulesTabPageObject
  include K5ResourceTabPageObject
  include K5Common

  before :once do
    student_setup
  end

  before :each do
    user_session @student
  end

  context 'course dashboard standard' do
    it 'lands on course dashboard when course card is clicked' do
      get "/"

      click_dashboard_card
      wait_for_ajaximations

      expect(retrieve_title_text).to match(/#{@subject_course_title}/)
      expect(home_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
    end

    it 'saves tab information for refresh' do
      get "/courses/#{@subject_course.id}#home"

      select_schedule_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#schedule/)
    end

    it 'has front page displayed if there is one' do
      wiki_page_data = "Here's where we have content"
      @subject_course.wiki_pages.create!(:title => "K5 Course Front Page", :body => wiki_page_data).set_as_front_page!

      get "/courses/#{@subject_course.id}#home"

      expect(front_page_info.text).to eq(wiki_page_data)
    end

    it 'displays modules empty state if no published module exists' do
      get "/courses/#{@subject_course.id}#modules"
      expect(modules_tab).to be_displayed
      expect(empty_modules_image).to be_displayed

      create_course_module('unpublished')
      get "/courses/#{@subject_course.id}#modules"
      expect(modules_tab).to be_displayed
      expect(empty_modules_image).to be_displayed
    end

    it 'displays the latest announcement on the Home tab' do
      new_announcement(@subject_course, "Let's do science", "it's fun!")

      announcement_heading = "Happy Monday!"
      announcement_content = "Let's get to work"
      new_announcement(@subject_course, announcement_heading, announcement_content)

      get "/courses/#{@subject_course.id}"

      expect(course_dashboard_title).to include_text("Science")
      expect(announcement_title(announcement_heading)).to be_displayed
      expect(announcement_content_text(announcement_content)).to be_displayed
    end

    it 'does not display old announcements on the Home tab' do
      announcement_heading = "Do science"
      announcement = new_announcement(@subject_course, announcement_heading, "it's fun!")

      announcement.posted_at = 15.days.ago
      announcement.save!

      get "/courses/#{@subject_course.id}"

      expect(announcement_title_exists?(announcement_heading)).to be_falsey
    end
  end

  context 'course modules tab' do
    before :once do
      create_course_module
    end

    it 'has module present when provisioned' do
      get "/courses/#{@subject_course.id}#modules"

      expect(module_item(@module_title)).to be_displayed
    end

    it 'allows for expand and collapse of module' do
      get "/courses/#{@subject_course.id}#modules"

      expect(module_assignment(@module_assignment_title)).to be_displayed
      expect(expand_collapse_module).to be_displayed

      click_expand_collapse
      expect(module_assignment(@module_assignment_title)).not_to be_displayed
    end

    it 'navigates to module tasks when clicked' do
      get "/courses/#{@subject_course.id}#modules"

      click_module_assignment(@module_assignment_title)
      wait_for_ajaximations

      expect(assignment_page_title.text).to eq(@module_assignment_title)
    end
  end

  context 'course resources tab' do
    it 'shows the Important Info for subject resources tab' do
      important_info_text = "Show me what you can do"
      create_important_info_content(@subject_course, important_info_text)
      create_lti_resource("fake LTI")
      get "/courses/#{@subject_course.id}#resources"

      expect(important_info_content).to include_text(important_info_text)
    end
  end
end
