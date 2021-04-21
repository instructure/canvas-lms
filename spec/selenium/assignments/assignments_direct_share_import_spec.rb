# frozen_string_literal: true

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
require_relative 'page_objects/assignment_page'
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
    # Third course has already concluded, but should still show up in Direct Share
    @term = EnrollmentTerm.new(:name => "Term Over", :start_at => 1.month.ago, :end_at => 1.week.ago)
    @term.root_account_id = Account.default.id
    @term.save!
    @course3 = Course.create!(:name => "Third Course3", :start_at => 1.month.ago, :conclude_at => 1.week.ago, :enrollment_term => @term)
    @course3.enroll_teacher(@teacher1, :enrollment_state => 'active')
    @course3.enroll_teacher(@teacher2, :enrollment_state => 'active')
  }

  let(:copy_assignment_to_course2) {
    course_search_dropdown.click
    wait_for_ajaximations
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

  describe 'direct share feature' do
    before(:once) do
      setup
    end

    before(:each) do
      user_session(@teacher1)
    end

    it 'allows user to send assignment from individual assignment page' do
      AssignmentPage.visit(@course1.id, @assignment1.id)
      AssignmentPage.manage_assignment_button.click
      AssignmentPage.send_to_menuitem.click
      expect(AssignmentPage.assignment_page_body).to contain_css(send_to_dialog_css_selector)
    end

    it 'allows user to copy assignment from individual assignment page' do
      AssignmentPage.visit(@course1.id, @assignment1.id)
      AssignmentPage.manage_assignment_button.click
      AssignmentPage.copy_to_menuitem.click
      expect(AssignmentPage.assignment_page_body).to contain_css(copy_to_dialog_css_selector)
    end

    context 'copy to' do
      before(:each) do
        visit_assignments_index_page(@course1.id)
        manage_assignment_menu(@assignment1.id).click
        copy_assignment_menu_link(@assignment1.id).click
      end

      it 'copy tray lists user managed courses' do
        course_search_dropdown.click
        wait_for_ajaximations

        expect(course_dropdown_list[0].text).to include 'First Course1'
        expect(course_dropdown_list[0].text).to include 'Second Course2'
      end

      it 'copy tray does not list concluded courses' do
        course_search_dropdown.click
        wait_for_ajaximations

        expect(course_dropdown_list[0].text).not_to include 'Third Course3'
      end

      it 'copy tray lists course modules' do
        select_course
        module_search_dropdown.click
        wait_for_ajaximations

        expect(module_dropdown_list.text).to include 'My Module1'
        expect(module_dropdown_list.text).to include 'My Module2'
      end

      it 'copy tray allows placement' do
        select_course_and_module_in_tray
        placement_dropdown.click
        wait_for_ajaximations
        @place_options_text = placement_dropdown_options

        expect(@place_options_text[0].text).to include 'At the Top'
        expect(@place_options_text[1].text).to include 'Before..'
        expect(@place_options_text[2].text).to include 'After..'
        expect(@place_options_text[3].text).to include 'At the Bottom'
      end

      it 'copied assignment is present in destination course' do
        # initiate the copy from Course2 to Course1
        copy_assignment_to_course2
        @migration1 = @course2.content_migrations.last
        # the migration source course id is Course 1
        expect(@migration1.source_course_id).to eq @course1.id
        expect(@migration1.workflow_state).to eq "imported"
      end
    end

    context 'send to' do
      before(:each) do
        visit_assignments_index_page(@course1.id)
        stub_common_cartridge_url
        manage_assignment_menu(@assignment1.id).click
        send_assignment_menu_link(@assignment1.id).click
        send_item
        run_jobs
        user_session(@teacher2)
      end

      it 'can send an item to another instructor', custom_timeout: 30 do
        visit_content_share_page
        expect(received_table_rows[1].text).to include @assignment1.name
      end

      context 'received item' do
        before(:each) do
          visit_content_share_page
          manage_received_item_button(@assignment1.name).click
        end

        it 'can preview received item', custom_timeout: 30 do
          preview_received_item.click
          # can view the mocked preview page
          expect(page_body.text).to include "Preview"
        end

        it 'can be imported into concluded courses', custom_timeout: 30 do
          import_content_share.click
          course_search_dropdown.click
          wait_for_ajaximations

          expect(course_dropdown_list[0].text).to include 'Third Course3'
        end

        it 'can be imported into a course', custom_timeout: 30 do
          import_content_share.click
          select_course_and_module_in_tray
          import_button.click
          run_jobs
          expect(import_dialog_import_success_alert.text).to include "Import started successfully"
        end
      end
    end
  end
end
