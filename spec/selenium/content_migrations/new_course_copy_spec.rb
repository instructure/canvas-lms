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
    expect(CourseCopyPage.header).to be_displayed
    expect(CourseCopyPage.header.text).to eq @course.course_code
  end

  def wait_for_migration_to_complete
    keep_trying_for_attempt_times(attempts: 10, sleep_interval: 1) do
      disable_implicit_wait { ContentMigrationPage.progress_status_label.text == "Completed" }
    end
  end

  before(:once) do
    Account.site_admin.enable_feature! :instui_for_import_page
  end

  it "copies the course" do
    course_with_admin_logged_in
    @course.syllabus_body = "<p>haha</p>"
    @course.tab_configuration = [{ "id" => 0 }, { "id" => 14 }, { "id" => 8 }, { "id" => 5 }, { "id" => 6 }, { "id" => 2 }, { "id" => 3, "hidden" => true }]
    @course.default_view = "modules"
    @course.wiki_pages.create!(title: "hi", body: "Whatever")
    @course.save!
    get "/courses/#{@course.id}/copy"
    expect_new_page_load { CourseCopyPage.create_course_button.click }
    expect(ContentMigrationPage.progress_status_label.text.include?("Running")).to be(true)
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
    expect_new_page_load { CourseCopyPage.create_course_button.click }
    expect(CourseCopyPage.body).not_to contain_css("#unauthorized_message")
  end

  it "sets the course name and code correctly" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    replace_content(CourseCopyPage.course_name_input, "course name of testing")
    replace_content(CourseCopyPage.course_code_input, "course code of testing")

    expect_new_page_load { CourseCopyPage.create_course_button.click }

    new_course = Course.last
    expect(new_course.name).to eq "course name of testing"
    expect(new_course.course_code).to eq "course code of testing"
  end

  it "adjusts the dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    CourseCopyPage.date_adjust_checkbox.click

    replace_and_proceed(CourseCopyPage.old_start_date_input, "7/1/2012")
    replace_and_proceed(CourseCopyPage.old_end_date_input, "Jul 11, 2012")
    replace_and_proceed(CourseCopyPage.new_start_date_input, "8-5-2012")
    replace_and_proceed(CourseCopyPage.new_end_date_input, "Aug 15, 2012")

    CourseCopyPage.add_day_substitution_button.click
    click_option("#daySubstitution ul > div:nth-child(1) .currentDay", "1", :value)
    click_option("#daySubstitution ul > div:nth-child(1) .subDay", "2", :value)

    expect_new_page_load { CourseCopyPage.create_course_button.click }

    opts = ContentMigration.last.migration_settings["date_shift_options"]
    expect(opts["shift_dates"]).to eq "1"
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

    CourseCopyPage.date_adjust_checkbox.click
    CourseCopyPage.date_remove_option.click
    expect_new_page_load { CourseCopyPage.create_course_button.click }

    opts = ContentMigration.last.migration_settings["date_shift_options"]
    expect(opts["remove_dates"]).to eq "1"
  end

  it "creates the new course in the same sub-account" do
    account_model
    subaccount = @account.sub_accounts.create!(name: "subadubdub")
    course_with_admin_logged_in(account: subaccount)
    @course.syllabus_body = "<p>haha</p>"
    @course.save!

    get "/courses/#{@course.id}/settings"
    link = CourseCopyPage.course_copy_link
    expect(link).to be_displayed
    expect_new_page_load { link.click }
    expect_new_page_load { CourseCopyPage.create_course_button.click }
    run_jobs
    wait_for_ajaximations
    wait_for_migration_to_complete

    @new_course = subaccount.courses.where("id <>?", @course.id).last
    expect(@new_course.syllabus_body).to eq @course.syllabus_body
  end

  it "is not able to submit invalid course dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    replace_content(CourseCopyPage.course_start_at_input, "Aug 15, 2012")
    replace_and_proceed(CourseCopyPage.course_conclude_at_input, "Jul 11, 2012")

    expect(CourseCopyPage.create_course_button).to be_disabled

    replace_and_proceed(CourseCopyPage.course_conclude_at_input, "Aug 30, 2012")

    expect(CourseCopyPage.create_course_button).not_to be_disabled
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
      @course.start_at = Time.now
      @course.save!
    end

    # this test requires jobs to run in the middle of it and course_copys
    # need to check a lot of things, a longer timeout is reasonable.
    it "shifts the dates a week later", custom_timeout: 30, priority: "2" do
      event = @course.calendar_events.create! title: "Monday Event", start_at: @date_to_use

      get "/courses/#{@course.id}/copy"
      new_course_name = "copied course"
      replace_content(CourseCopyPage.course_name_input, new_course_name)
      replace_content(CourseCopyPage.course_code_input, "copied")
      CourseCopyPage.date_adjust_checkbox.click
      date = 1.week.from_now.strftime("%Y-%m-%d")
      replace_content(CourseCopyPage.new_start_date_input, date, tab_out: true)
      expect_new_page_load { submit_form("#copy_course_form") }
      run_jobs

      new_course = Course.where(name: new_course_name).last
      new_event = new_course.calendar_events.where(title: "Monday Event").last
      expect(new_event.all_day_date).to eq event.all_day_date + 7.days
    end
  end
end
