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

require_relative '../common'
require_relative 'pages/paceplans_common_page'
require_relative 'pages/paceplans_page'
require_relative '../courses/pages/courses_home_page'

describe 'pace plan page' do
  include_context 'in-process server selenium tests'
  include PacePlansCommonPageObject
  include PacePlansPageObject
  include CoursesHomePage

  before :once do
    teacher_setup
    enable_pace_plans_in_course
  end

  before :each do
    user_session @teacher
  end

  context 'pace plan not enabled' do
    it 'does not include Pace Plans navigation element when disabled' do
      disable_pace_plans_in_course
      visit_course(@course)

      expect(pace_plans_nav_exists?).to be_falsey
    end
  end

  context 'pace plans in course navigation' do
    let(:module_title) { 'First Module' }
    let(:module_assignment_title) { 'Module Assignment' }

    before :once do
      @course_module = create_course_module(module_title, 'active')
      @assignment = create_assignment(@course, module_assignment_title, "Module Assignment Description", 10, 'published')
      @course_module.add_item(:id => @assignment.id, :type => 'assignment')
    end

    it 'navigates to the pace plans page when Pace Plans is clicked' do
      visit_course(@course)

      click_pace_plans

      expect(driver.current_url).to include("/courses/#{@course.id}/pace_plans")
    end

    it 'shows the module and module items in the pace plan' do
      discussion_title = "Module Discussion"
      discussion_assignment = create_graded_discussion(@course, discussion_title, 'published')
      @course_module.add_item(:id => discussion_assignment.id, :type => 'discussion_topic')
      quiz_title = "Quiz Title"
      quiz = create_quiz(@course, quiz_title)
      @course_module.add_item(:id => quiz.id, :type => 'quiz')

      visit_pace_plans_page

      expect(module_title_text(0)).to include(module_title)
      expect(module_item_title_text(0)).to eq(module_assignment_title)
      expect(module_item_title_text(1)).to eq(discussion_title)
      expect(module_item_title_text(2)).to eq(quiz_title)
    end

    it 'does not show a module item that is not an assignment' do
      page = @course.wiki_pages.create!(title: "New Page Title")
      @course_module.add_item(id: page.id, type: 'wiki_page')
      @course_module.add_item(:type => 'external_url',
                              :url => 'http://example.com/lolcats',
                              :title => 'pls view')
      @course_module.add_item(:type => "sub_header", :title => "silly tag")

      visit_pace_plans_page

      expect(module_items.count).to eq(1)
      expect(module_item_title_text(0)).to eq(module_assignment_title)
    end

    it 'does not show any publish status when no pace plan created yet' do
      visit_pace_plans_page

      expect(publish_status_exists?).to be_falsey
    end

    it 'has Publish and Cancel buttons initially disabled' do
      visit_pace_plans_page

      expect(publish_button).to be_disabled
      expect(cancel_button).to be_disabled
    end

    it 'updates duration to make Publish and Cancel buttons enabled' do
      visit_pace_plans_page

      update_module_item_duration(2)

      expect(publish_button).to be_enabled
      expect(cancel_button).to be_enabled
    end

    it 'does not allow duration to be set to negative number' do
      visit_pace_plans_page

      update_module_item_duration('-1')

      expect(duration_field.text).not_to eq('-1')
    end
  end
end
