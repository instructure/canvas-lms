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

require_relative "../common"
require_relative "../helpers/calendar2_common"
require_relative "page_objects/new_course_copy_page"
require_relative "page_objects/new_content_migration_page"
describe "course copy" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  def validate_course_main_page
    expect(NewCourseCopyPage.header).to be_displayed
    expect(NewCourseCopyPage.header.text).to eq @course.course_code
  end

  def wait_for_migration_to_complete
    keep_trying_for_attempt_times(attempts: 10, sleep_interval: 1) do
      disable_implicit_wait { NewContentMigrationPage.progress_status_label.text == "Completed" }
    end
  end

  it "copies the course" do
    course_with_admin_logged_in
    @course.syllabus_body = "<p>haha</p>"
    @course.tab_configuration = [{ "id" => 0 }, { "id" => 14 }, { "id" => 8 }, { "id" => 5 }, { "id" => 6 }, { "id" => 2 }, { "id" => 3, "hidden" => true }]
    @course.default_view = "modules"
    @course.wiki_pages.create!(title: "hi", body: "Whatever")
    @course.save!
    get "/courses/#{@course.id}/copy"
    expect_new_page_load { NewCourseCopyPage.create_course_button.click }
    expect(NewContentMigrationPage.progress_status_label.text.include?("Running")).to be(true)
    run_jobs
    wait_for_ajaximations
    wait_for_migration_to_complete

    @new_course = Course.last
    expect(@new_course.syllabus_body).to eq @course.syllabus_body
    expect(@new_course.tab_configuration).to eq @course.tab_configuration
    expect(@new_course.default_view).to eq @course.default_view
    expect(@new_course.wiki_pages.count).to eq 1
  end

  it "finished calculating course dates for access before redirect" do
    course_with_teacher_logged_in
    @course.root_account.update!(settings: { teachers_can_create_courses: true })
    past_term_id = EnrollmentTerm.create(end_at: 1.day.ago, root_account: @teacher.account).id
    @course.update! enrollment_term_id: past_term_id, conclude_at: 5.days.from_now, restrict_enrollments_to_course_dates: true
    get "/courses/#{@course.id}/copy"
    expect_new_page_load { NewCourseCopyPage.create_course_button.click }
    expect(NewCourseCopyPage.body).not_to contain_css("#unauthorized_message")
  end

  it "sets the course name and code correctly" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    replace_content(NewCourseCopyPage.course_name_input, "course name of testing")
    replace_content(NewCourseCopyPage.course_code_input, "course code of testing")

    expect_new_page_load { NewCourseCopyPage.create_course_button.click }

    new_course = Course.last
    expect(new_course.name).to eq "course name of testing"
    expect(new_course.course_code).to eq "course code of testing"
  end

  it "adjusts the dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    NewCourseCopyPage.date_adjust_checkbox.click

    replace_and_proceed(NewCourseCopyPage.old_start_date_input, "7/1/2012")
    replace_and_proceed(NewCourseCopyPage.old_end_date_input, "Jul 11, 2012")
    replace_and_proceed(NewCourseCopyPage.new_start_date_input, "8-5-2012")
    replace_and_proceed(NewCourseCopyPage.new_end_date_input, "Aug 15, 2012")

    NewCourseCopyPage.add_day_substitution_button.click
    click_option("#day-substition-from-1", "Monday")
    click_option("#day-substition-to-1", "Tuesday")

    expect_new_page_load { NewCourseCopyPage.create_course_button.click }

    opts = ContentMigration.last.migration_settings["date_shift_options"]
    expect(opts["shift_dates"]).to be_truthy
    expect(opts["day_substitutions"]).to eq({ "1" => "2" })
    expected = {
      "old_start_date" => "Jul 1, 2012",
      "old_end_date" => "Jul 11, 2012",
      "new_start_date" => "Aug 5, 2012",
      "new_end_date" => "Aug 15, 2012"
    }
    expected.each do |k, v|
      expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
    end
  end

  it "removes dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    NewCourseCopyPage.date_adjust_checkbox.click
    NewCourseCopyPage.date_remove_option.click
    expect_new_page_load { NewCourseCopyPage.create_course_button.click }

    opts = ContentMigration.last.migration_settings["date_shift_options"]
    expect(opts["remove_dates"]).to be_truthy
  end

  it "creates the new course in the same sub-account" do
    account_model
    subaccount = @account.sub_accounts.create!(name: "subadubdub")
    course_with_admin_logged_in(account: subaccount)
    @course.syllabus_body = "<p>haha</p>"
    @course.save!

    get "/courses/#{@course.id}/settings"
    link = NewCourseCopyPage.course_copy_link
    expect(link).to be_displayed
    expect_new_page_load { link.click }
    expect_new_page_load { NewCourseCopyPage.create_course_button.click }
    run_jobs
    wait_for_ajaximations
    wait_for_migration_to_complete

    @new_course = subaccount.courses.where("id <>?", @course.id).last
    expect(@new_course.syllabus_body).to eq @course.syllabus_body
  end

  it "is not able to submit invalid course dates" do
    course_with_admin_logged_in

    @course.restrict_enrollments_to_course_dates = true
    @course.save!

    get "/courses/#{@course.id}/copy"

    replace_content(NewCourseCopyPage.course_start_at_input, "Aug 15, 2012")
    replace_and_proceed(NewCourseCopyPage.course_conclude_at_input, "Jul 11, 2012")

    NewCourseCopyPage.create_course_button.click
    expect(element_exists?(NewCourseCopyPage.course_start_error_message_selector, true)).to be_truthy
    expect(element_exists?(NewCourseCopyPage.course_end_error_message_selector, true)).to be_truthy

    replace_and_proceed(NewCourseCopyPage.course_conclude_at_input, "Aug 30, 2012")
    expect_new_page_load { NewCourseCopyPage.create_course_button.click }
  end

  context "with calendar events" do
    around do |example|
      Timecop.freeze(Time.zone.local(2016, 5, 1, 10, 5, 0)) do
        Auditors::ActiveRecord::Partitioner.process
        example.call
      end
    end

    before do
      course_with_admin_logged_in
      @date_to_use = 2.weeks.from_now.monday.strftime("%Y-%m-%d")
      @course.start_at = Time.zone.now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
    end

    # this test requires jobs to run in the middle of it and course_copys
    # need to check a lot of things, a longer timeout is reasonable.
    it "shifts the dates a week later", custom_timeout: 30, priority: "2" do
      event = @course.calendar_events.create! title: "Monday Event", start_at: @date_to_use

      get "/courses/#{@course.id}/copy"
      new_course_name = "copied course"
      replace_content(NewCourseCopyPage.course_name_input, new_course_name)
      replace_content(NewCourseCopyPage.course_code_input, "copied")
      NewCourseCopyPage.date_adjust_checkbox.click
      date = 1.week.from_now.strftime("%Y-%m-%d")
      replace_content(NewCourseCopyPage.new_start_date_input, date, tab_out: true)
      expect_new_page_load { NewCourseCopyPage.create_course_button.click }
      run_jobs
      wait_for_ajaximations
      wait_for_migration_to_complete

      new_course = Course.where(name: new_course_name).last
      new_event = new_course.calendar_events.where(title: "Monday Event").last
      expect(new_event.all_day_date).to eq event.all_day_date + 7.days
    end

    it "new dates are updated when course dates are changed" do
      course_with_admin_logged_in

      @course.start_at = Time.zone.parse("2012-07-07")
      @course.conclude_at = Time.zone.parse("2012-07-11")
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      get "/courses/#{@course.id}/copy"

      replace_and_proceed(NewCourseCopyPage.course_start_date_input, "2012-08-05")
      replace_and_proceed(NewCourseCopyPage.course_end_date_input, "2012-11-15")
      NewCourseCopyPage.date_adjust_checkbox.click

      expect_new_page_load { NewCourseCopyPage.create_course_button.click }
      wait_for_ajaximations
      wait_for_migration_to_complete

      opts = ContentMigration.where(source_course_id: @course.id)
                             .order(:created_at).last.migration_settings["date_shift_options"]

      expect(opts).not_to be_nil
      expect(opts["shift_dates"]).to be_truthy
      expected = {
        "old_start_date" => "Jul 7, 2012",
        "old_end_date" => "Jul 11, 2012",
        "new_start_date" => "Aug 5, 2012",
        "new_end_date" => "Nov 15, 2012"
      }
      expected.each do |k, v|
        expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
      end
    end
  end
end
