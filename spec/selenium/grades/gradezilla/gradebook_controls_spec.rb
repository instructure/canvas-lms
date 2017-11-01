#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../pages/gradezilla_page'
require_relative '../setup/gradebook_setup'

describe 'Gradebook Controls' do
  include_context "in-process server selenium tests"
  include GradebookSetup

  before(:once) do
    course_with_teacher(active_all: true)
  end

  before(:each) do
    user_session(@teacher)
  end

  context 'using Gradebook dropdown' do
    it 'navigates to Individual View', test_id: 3253264, priority: '1' do
      Gradezilla.visit(@course)
      expect_new_page_load { Gradezilla.gradebook_dropdown_item_click("Individual View") }
      expect(f('h1')).to include_text("Gradebook: Individual View")
    end

    it "navigates to Gradebook History", priority: "2", test_id: 3253265 do
      Gradezilla.visit(@course)
      expect_new_page_load { Gradezilla.gradebook_dropdown_item_click("Gradebook History") }
      expect(driver.current_url).to include("/courses/#{@course.id}/gradebook/history")
    end

    it "navigates to Learning Mastery", priority: "1", test_id: 3253266 do
      Account.default.set_feature_flag!('outcome_gradebook', 'on')
      Gradezilla.visit(@course)
      Gradezilla.gradebook_dropdown_item_click("Learning Mastery")
      expect(fj('button:contains("Learning Mastery")')).to be_displayed
    end
  end

  context 'using View dropdown' do
    it 'shows Grading Period dropdown', test_id: 3253277, priority: '1' do
      create_grading_periods('Fall Term')
      associate_course_to_term("Fall Term")

      Gradezilla.visit(@course)
      Gradezilla.select_view_dropdown
      Gradezilla.select_filters
      Gradezilla.select_view_filter("Grading Periods")
      expect(f(Gradezilla.grading_period_dropdown_selector)).to be_displayed
    end

    it 'shows Module dropdown', test_id: 3253275, priority: '1' do
      @mods = Array.new(2) { |i| @course.context_modules.create! name: "Mod#{i}" }

      Gradezilla.visit(@course)
      Gradezilla.select_view_dropdown
      Gradezilla.select_filters
      Gradezilla.select_view_filter("Modules")

      expect(Gradezilla.module_dropdown).to be_displayed
    end

    it 'shows Section dropdown', test_id: 3253276, priority: '1' do
      @section1 = @course.course_sections.create!(name: 'Section One')

      Gradezilla.visit(@course)
      Gradezilla.select_view_dropdown
      Gradezilla.select_filters
      Gradezilla.select_view_filter("Sections")

      expect(Gradezilla.section_dropdown).to be_displayed
    end

    it 'hides unpublished assignments', test_id: 3253282, priority: '1' do
      assign = @course.assignments.create! title: "I am unpublished"
      assign.unpublish

      Gradezilla.visit(@course)
      Gradezilla.select_view_dropdown
      Gradezilla.select_show_unpublished_assignments

      expect(Gradezilla.content_selector).not_to contain_css('.assignment-name')
    end
  end

  context 'using Actions dropdown' do

    it 'navigates to upload page', test_id: 3265129, priority: '1' do
      Gradezilla.visit(@course)
      Gradezilla.open_action_menu
      Gradezilla.action_menu_item_selector("import").click

      expect(driver.current_url).to include "courses/#{@course.id}/gradebook_upload/new"
    end
  end
end



