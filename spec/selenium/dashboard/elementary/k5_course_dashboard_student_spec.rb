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
require_relative '../../helpers/k5_common'

describe "student k5 course dashboard" do
  include_context "in-process server selenium tests"
  include K5PageObject
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
      expect(modules_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
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
  end
end
