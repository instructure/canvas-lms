# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative 'page_objects/assignments_index_page'
require_relative '../shared_components/copy_to_tray_page'
require_relative '../shared_components/send_to_dialog_page'
require_relative '../admin/pages/account_content_share_page'
require_relative '../../spec_helper'

describe 'assignments' do

  include_context 'in-process server selenium tests'
  include AssignmentsIndexPage
  include CopyToTrayPage
  include SendToDialogPage
  include AccountContentSharePage

  let(:setup) {
    # Two Courses
    @course1 = Course.create!(:name => "First Course1")
    @course2 = Course.create!(:name => "Second Course2")
    # Two teachers
    @teacher1 = User.create!(:name => "First Teacher")
    @teacher2 = User.create!(:name => "Second Teacher")
    @teacher2.accept_terms
    @teacher2.register!
    # Teacher1 is enrolled in both courses, Teacher2 is in Course2 only
    @course1.enroll_teacher(@teacher1, :enrollment_state => 'active')
    @course2.enroll_teacher(@teacher1, :enrollment_state => 'active')
    @course2.enroll_teacher(@teacher2, :enrollment_state => 'active')
    # Assignment1 in Course1
    @assignment1 = @course1.assignments.create!(:title => 'Assignment First', :points_possible => 10)
    # add a module to course2
    @module1 = @course2.context_modules.create!(:name => "My Module1")
    @item_before = @module1.add_item :type => 'assignment', :id => @course1.assignments.create!(:title => 'assignment BEFORE this one').id
    @item_after = @module1.add_item :type => 'assignment', :id => @course1.assignments.create!(:title => 'assignment AFTER this one').id
    @module2 = @course2.context_modules.create!(:name => "My Module2")
  }

  let(:copy_assignment_to_course2) {
    course_search_dropdown.click
    course_dropdown_item(@course2.name).click
    copy_button.click
    run_jobs
  }

  let(:select_course) {
    course_search_dropdown.click
    course_dropdown_item(@course2.name).click
  }

  let(:send_item) {
    user_search.click
    user_search.send_keys("teac")
    wait_for_animations
    user_dropdown(@teacher2.name).click
    send_button.click
    run_jobs
  }

  let(:select_course_and_module_in_tray) {
    course_search_dropdown.click
    course_dropdown_item(@course2.name).click
    module_search_dropdown.click
    module_dropdown_item(@module1.name).click
  }

  context 'with direct share FF ON' do
    before(:once) do
      setup
      Account.default.enable_feature!(:direct_share)
    end

    before(:each) do
      user_session(@teacher1)
      visit_assignments_index_page(@course1.id)
    end

    context 'copy to' do
      before(:each) do
        manage_assignment_menu(@assignment1.id).click
        copy_assignment_menu_link(@assignment1.id).click
      end

      it 'copy tray lists user managed courses' do
        skip('LA-374')
        course_search_dropdown.click
        wait_for_animations
        expect(course_dropdown_list.text).to include 'First Course1'
        expect(course_dropdown_list.text).to include 'Second Course2'
      end

      it 'copy tray lists course modules' do
        skip('LA-374')
        select_course
        module_search_dropdown.click
        wait_for_animations
        expect(module_dropdown_list.text).to include 'My Module1'
        expect(module_dropdown_list.text).to include 'My Module2'
      end

      it 'copy tray allows placement' do
        skip('LA-374')
        select_course_and_module_in_tray
        placement_dropdown.click

        @place_options_text = placement_dropdown_options
        expect(@place_options_text[0].text).to include 'At the Top'
        expect(@place_options_text[1].text).to include 'Before..'
        expect(@place_options_text[2].text).to include 'After..'
        expect(@place_options_text[3].text).to include 'At the Bottom'
      end

      it 'copied assignment is present in destination course' do
        copy_assignment_to_course2
        visit_assignments_index_page(@course2.id)

        expect(assignments_rows.text).to include 'Assignment First'
      end
    end

    context 'send to' do
      before(:each) do
        manage_assignment_menu(@assignment1.id).click
        send_assignment_menu_link(@assignment1.id).click
        send_item
        run_jobs
        user_session(@teacher2)
        visit_content_share_page
      end

      it 'can send an item to another instructor' do
        skip('LA-374')
        expect(received_table_rows[1].text).to include @assignment1.name
      end
    end
  end

  context 'with direct share FF OFF' do
    before(:each) do
      course_with_teacher_logged_in
      @course.save!
      @course.require_assignment_group
      @assignment1 = @course.assignments.create!(:title => 'Assignment First', :points_possible => 10)
      Account.default.disable_feature!(:direct_share)
      user_session(@teacher)
      visit_assignments_index_page(@course.id)
    end

    it 'hides direct share options' do
      manage_assignment_menu(@assignment1.id).click
      expect(assignment_settings_menu(@assignment1.id).text).not_to include('Send to...')
      expect(assignment_settings_menu(@assignment1.id).text).not_to include('Copy to...')
    end
  end
end
