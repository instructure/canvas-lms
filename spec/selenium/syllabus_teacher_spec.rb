# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')
require File.expand_path(File.dirname(__FILE__) + '/rcs/pages/rce_next_page')


describe "course syllabus" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include WikiAndTinyCommon
  include RCENextPage

  def add_assignment(title, points)
    # assignment data
    assignment = assignment_model({
                                      :course => @course,
                                      :title => title,
                                      :due_at => nil,
                                      :points_possible => points,
                                      :submission_types => 'online_text_entry',
                                      :assignment_group => @group
                                  })
    rubric_model
    @association = @rubric.associate_with(assignment, @course, :purpose => 'grading')
    assignment.reload
  end

  context "as a teacher" do

    before(:each) do
      Account.default.enable_feature!(:rce_enhancements)
      stub_rcs_config
      course_with_teacher_logged_in
      @group = @course.assignment_groups.create!(:name => 'first assignment group')
      @assignment_1 = add_assignment('first assignment title', 50)
      @assignment_2 = add_assignment('second assignment title', 100)

      get "/courses/#{@course.id}/assignments/syllabus"
      wait_for_ajaximations
    end

    it "should confirm existing assignments and dates are correct", priority:"1", test_id: 237016 do
      assignment_details = ff('.name')
      expect(assignment_details[0].text.strip).to eq "Assignment\n" + @assignment_1.title
      expect(assignment_details[1].text.strip).to eq "Assignment\n" + @assignment_2.title
    end

    it "should edit the description", priority:"1", test_id: 237017 do
      skip('weird issue where text does not show up on submit')
      # skip_if_firefox('known issue with firefox https://bugzilla.mozilla.org/show_bug.cgi?id=1335085')

      new_description = "new syllabus description"
      wait_for_new_page_load { f('.edit_syllabus_link').click }
      edit_form = f('#edit_course_syllabus_form')
      wait_for_tiny(f('#edit_course_syllabus_form'))
      type_in_tiny('#course_syllabus_body', new_description)
      submit_form(edit_form)
      wait_for_ajaximations

      expect(f('#course_syllabus').text).to eq new_description
    end

    it "should insert a file using RCE in the syllabus", priority: "1", test_id: 126672, custom_timeout: 30 do
      file = @course.attachments.create!(display_name: 'text_file.txt', uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/assignments/syllabus"
      f('.edit_syllabus_link').click
      add_file_to_rce_next
      submit_form('.form-actions')
      wait_for_ajax_requests
      expect(fln("text_file.txt")).to be_displayed
    end

    it "should validate Jump to Today works on the mini calendar", priority:"1", test_id: 237017 do
      2.times { f('.next_month_link').click }
      f('.jump_to_today_link').click
      expect(f('.mini_month .today')).to have_attribute('id', "mini_day_#{Time.zone.now.strftime('%Y_%m_%d')}")
    end

    describe "Accessibility" do
      it "should set focus to the Jump to Today link after clicking Edit the Description", priority:"2", test_id: 237019 do
        skip('see CNVS-39931')
        f('.edit_syllabus_link').click
        check_element_has_focus(f('.jump_to_today_link'))
      end
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "should display course syllabus", priority: "1", test_id: 270034 do
      get "/courses/#{public_course.id}/assignments/syllabus"
      expect(f('#course_syllabus')).to be_displayed
    end
  end
end
