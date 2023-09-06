# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/public_courses_context"
require_relative "../helpers/files_common"
require_relative "pages/syllabus_page"

describe "course syllabus" do
  include_context "in-process server selenium tests"
  include CourseSyllabusPage

  context "with syllabus course summary option for a course" do
    before :once do
      # course_with_teacher :active_all => true
      @course1 = Course.create!(name: "First Course1")
      @teacher1 = User.create!(name: "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, enrollment_state: "active")
      @assignment1 = @course1.assignments.create!(title: "Assignment First", points_possible: 10)
    end

    before do
      user_session @teacher1
    end

    context "immersive reader button" do
      it "contains a button for immersive reader when enabled" do
        @teacher1.enable_feature!(:user_immersive_reader_wiki_pages)

        visit_syllabus_page(@course1.id)
        wait_for_dom_ready

        expect(immersive_reader_btn).to be_displayed
      end

      it "does not contain a button for immersive reader when disabled" do
        @teacher1.disable_feature!(:user_immersive_reader_wiki_pages)

        visit_syllabus_page(@course1.id)
        wait_for_dom_ready

        expect(page_main_content).not_to contain_css(immersive_reader_css)
      end
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

    context "in a paced course" do
      before do
        @course1.enable_course_paces = true
        @course1.save!
      end

      after do
        @course1.enable_course_paces = false
        @course1.save!
      end

      it "shows the course pacing notice instead of the course summary table" do
        visit_syllabus_page(@course1.id)
        expect(course_pacing_notice).to be_displayed
      end

      it "does not shows the course pacing notice when feature is off on account" do
        @course1.account.disable_feature!(:course_paces)
        visit_syllabus_page(@course1.id)
        expect(element_exists?(course_pacing_notice_selector)).to be_falsey
      end
    end
  end

  context "in a public course" do
    include_context "public course as a logged out user"

    before :once do
      @course = public_course
    end

    it "does not display course syllabus when show course summary is false" do
      # set the syllabus_course_summary attribute to false
      @course.syllabus_course_summary = false
      @course.save!
      visit_syllabus_page(@course.id)

      expect(page_main_content).not_to contain_css(syllabus_container_css)
    end
  end

  context "mini calendar" do
    before do
      course_with_teacher_logged_in(active_all: true)
    end

    it "starts the week on sunday" do
      skip("USE_OPTIMIZED_JS=true") unless ENV["USE_OPTIMIZED_JS"]
      skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
      @user.locale = "en-US"
      @user.save!

      # travel to April 5, 2021 4:30
      time = Time.zone.local(2021, 4, 5, 4, 30)
      Timecop.travel(time) do
        visit_syllabus_page(@course.id)

        # first day on the calendar should be Sunday March 28
        expect(mini_calendar_first_day_of_month_number.text).to eq "28"
        expect(mini_calendar_first_day_of_month_label.text).to eq "28 March 2021"

        # click to next month (May)
        mini_calendar_next_month_button.click
        wait_for_animations

        # first day on the calendar should be Sunday April 25
        expect(mini_calendar_first_day_of_month_number.text).to eq "25"
        expect(mini_calendar_first_day_of_month_label.text).to eq "25 April 2021"
      end
    end

    it "starts the week on monday" do
      skip("USE_OPTIMIZED_JS=true") unless ENV["USE_OPTIMIZED_JS"]
      skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
      @user.locale = "en-GB"
      @user.save!

      # travel to April 5, 2021 4:30
      time = Time.zone.local(2021, 4, 5, 4, 30)
      Timecop.travel(time) do
        visit_syllabus_page(@course.id)

        # first day on the calendar should be Monday March 29
        expect(mini_calendar_first_day_of_month_number.text).to eq "29"
        expect(mini_calendar_first_day_of_month_label.text).to eq "29 March 2021"

        # click to next month (May)
        mini_calendar_next_month_button.click
        wait_for_animations

        # first day on the calendar should be Monday April 26
        expect(mini_calendar_first_day_of_month_number.text).to eq "26"
        expect(mini_calendar_first_day_of_month_label.text).to eq "26 April 2021"
      end
    end
  end
end
