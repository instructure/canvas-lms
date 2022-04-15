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

describe "course copy" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  def validate_course_main_page
    header = f("#breadcrumbs .home + li a")
    expect(header).to be_displayed
    expect(header.text).to eq @course.course_code
  end

  def wait_for_migration_to_complete
    keep_trying_for_attempt_times(attempts: 10, sleep_interval: 1) do
      disable_implicit_wait { f("div.progressStatus").text == "Completed" }
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
    expect_new_page_load { f('button[type="submit"]').click }
    expect(f("div.progressStatus").text.include?("Queued")).to eq(true)
    run_jobs
    wait_for_ajaximations
    wait_for_migration_to_complete

    @new_course = Course.last
    expect(@new_course.syllabus_body).to eq @course.syllabus_body
    expect(@new_course.tab_configuration).to eq @course.tab_configuration
    expect(@new_course.default_view).to eq @course.default_view
    expect(@new_course.wiki_pages.count).to eq 1
  end

  it "sets the course name and code correctly" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    name = f("#course_name")
    replace_content(name, "course name of testing")
    name = f("#course_course_code")
    replace_content(name, "course code of testing")

    expect_new_page_load { f('button[type="submit"]').click }

    new_course = Course.last
    expect(new_course.name).to eq "course name of testing"
    expect(new_course.course_code).to eq "course code of testing"
  end

  it "adjusts the dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    f("#dateAdjustCheckbox").click

    replace_and_proceed(f("#oldStartDate"), "7/1/2012")
    replace_and_proceed(f("#oldEndDate"), "Jul 11, 2012")
    replace_and_proceed(f("#newStartDate"), "8-5-2012")
    replace_and_proceed(f("#newEndDate"), "Aug 15, 2012")

    f("#addDaySubstitution").click
    click_option("#daySubstitution ul > div:nth-child(1) .currentDay", "1", :value)
    click_option("#daySubstitution ul > div:nth-child(1) .subDay", "2", :value)

    expect_new_page_load { f('button[type="submit"]').click }

    opts = ContentMigration.last.migration_settings["date_shift_options"]
    expect(opts["shift_dates"]).to eq "1"
    expect(opts["day_substitutions"]).to eq({ "1" => "2" })
    expected = {
      "old_start_date" => "Jul 1, 2012", "old_end_date" => "Jul 11, 2012",
      "new_start_date" => "Aug 5, 2012", "new_end_date" => "Aug 15, 2012"
    }
    expected.each do |k, v|
      expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
    end
  end

  it "removes dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    f("#dateAdjustCheckbox").click
    f("#dateRemoveOption").click
    expect_new_page_load { f('button[type="submit"]').click }

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
    link = f(".copy_course_link")
    expect(link).to be_displayed
    expect_new_page_load { link.click }
    expect_new_page_load { f('button[type="submit"]').click }
    run_jobs
    wait_for_ajaximations
    wait_for_migration_to_complete

    @new_course = subaccount.courses.where("id <>?", @course.id).last
    expect(@new_course.syllabus_body).to eq @course.syllabus_body
  end

  it "is not able to submit invalid course dates" do
    course_with_admin_logged_in

    get "/courses/#{@course.id}/copy"

    replace_content(f("#course_start_at"), "Aug 15, 2012")
    replace_and_proceed(f("#course_conclude_at"), "Jul 11, 2012")

    button = f("button.btn-primary")
    expect(button).to be_disabled

    replace_and_proceed(f("#course_conclude_at"), "Aug 30, 2012")

    expect(button).not_to be_disabled
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
    end

    # this test requires jobs to run in the middle of it and course_copys
    # need to check a lot of things, a longer timeout is reasonable.
    it "shifts the dates a week later", priority: "2", custom_timeout: 30 do
      event = @course.calendar_events.create! title: "Monday Event", start_at: @date_to_use

      get "/courses/#{@course.id}/copy"
      new_course_name = "copied course"
      replace_content(f("input[type=text][id=course_name]"), new_course_name)
      replace_content(f("input[type=text][id=course_course_code]"), "copied")
      f("input[type=checkbox][id=dateAdjustCheckbox]").click
      date = 1.week.from_now.strftime("%Y-%m-%d")
      replace_content(f("input[type=text][id=newStartDate]"), date, tab_out: true)
      expect_new_page_load { submit_form("#copy_course_form") }
      run_jobs

      new_course = Course.where(name: new_course_name).last
      new_event = new_course.calendar_events.where(title: "Monday Event").last
      expect(new_event.all_day_date).to eq event.all_day_date + 7.days
    end
  end
end
