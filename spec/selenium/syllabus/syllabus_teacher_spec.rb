#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../common.rb'
require_relative '../helpers/public_courses_context.rb'
require_relative '../helpers/files_common.rb'
require_relative 'pages/syllabus_page.rb'

describe "course syllabus" do
  include_context "in-process server selenium tests"
  include CourseSyllabusPage

  context "with syllabus course summary option for a course" do
    before :once do
      # course_with_teacher :active_all => true
      @course1 = Course.create!(:name => "First Course1")
      @teacher1 = User.create!(:name => "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, :enrollment_state => 'active')
      @assignment1 = @course1.assignments.create!(:title => 'Assignment First', :points_possible => 10)
    end

    context "with feature off" do
      before :each do
        user_session @teacher1
      end

      it "does not show the option" do
        visit_syllabus_page(@course1.id)
        edit_syllabus_button.click
        wait_for_dom_ready

        expect(page_main_content).not_to contain_css(show_summary_chkbox_css)
      end
    end

    context "with feature on" do
      before :once do
        Account.site_admin.enable_feature! :syllabus_course_summary_option
      end

      before :each do
        user_session @teacher1
      end

      it "shows course-summary-option checkbox that is pre-checked" do
        visit_syllabus_page(@course1.id)

        edit_syllabus_button.click
        wait_for_dom_ready
        # ensure the checkbox is checked
        expect(is_checked(show_course_summary_checkbox)).to be true
        update_syllabus_button.click
        
        expect(page_main_content).to contain_css(syllabus_container_css)
        expect(page_main_content).to contain_css(mini_calendar_css)
      end

      it "hides course summary when course-summary-option checkbox is toggled off" do
        visit_syllabus_page(@course1.id)
        expect(page_main_content).to contain_css(syllabus_container_css)

        edit_syllabus_button.click
        wait_for_dom_ready
        expect(is_checked(show_course_summary_checkbox)).to be true
        # uncheck the show-course-summary checkbox
        show_course_summary_input.click
        update_syllabus_button.click

        expect(page_main_content).not_to contain_css(syllabus_container_css)
        expect(page_main_content).not_to contain_css(mini_calendar_css)
      end

      it "unhides course summary when course-summary-option checkbox is toggled on", custom_timeout: 20 do
        @course1.syllabus_course_summary = false
        @course1.save!
        visit_syllabus_page(@course1.id)
        expect(page_main_content).not_to contain_css(syllabus_container_css)

        edit_syllabus_button.click
        wait_for_dom_ready
        expect(is_checked(show_course_summary_checkbox)).to be false
        # enable the show-course-summary checkbox
        show_course_summary_input.click
        update_syllabus_button.click

        expect(page_main_content).to contain_css(syllabus_container_css)
        expect(page_main_content).to contain_css(mini_calendar_css)
      end
    end
  end

  context "with syllabus course summary for public course" do
    include_context "public course as a logged out user"
    
    before :once do
      Account.site_admin.enable_feature! :syllabus_course_summary_option
      @course = public_course
    end

    it "should not display course syllabus when show course summary is false" do
      # set the syllabus_course_summary attribute to false
      @course.syllabus_course_summary = false
      @course.save!
      visit_syllabus_page(@course.id)
      
      expect(page_main_content).not_to contain_css(syllabus_container_css)
    end
  end
end