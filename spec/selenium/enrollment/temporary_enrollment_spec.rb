# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe "temporary enrollment" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:temporary_enrollments)
    @teacher = user_factory(name: "teacher")
    @teacher.register!
    @course = course_with_teacher({ user: @teacher, active_course: true, active_enrollment: true }).course

    user_with_pseudonym(name: "temp_teacher", active_user: true, username: "tempTeacher", account: Account.default)
    @temp_teacher = User.find_by(name: "temp_teacher")

    user_with_pseudonym(name: "temp_teacher_2", active_user: true, username: "tempTeacher2", account: Account.default)
    @temp_teacher_2 = User.find_by(name: "temp_teacher_2")
  end

  before do
    admin_logged_in
  end

  def can_provide
    f("button[data-analytics='TempEnrollIconCalendarClockLine']")
  end

  def is_provider
    f("button[data-analytics='TempEnrollIconCalendarClockSolid']")
  end

  def is_recipient
    f("button[data-analytics='TempEnrollIconCalendarReservedSolid']")
  end

  def load_people_page
    get "/accounts/#{Account.default.id}/users"
  end

  def flash_alert
    f(".flashalert-message")
  end

  it "creates pairings" do
    # open modal
    load_people_page
    wait_for_ajax_requests
    can_provide.click

    # search for user
    f("[for='peoplesearch_radio_unique_id']").click
    f("textarea").send_keys("tempTeacher,tempTeacher2")
    f("button[data-analytics='TempEnrollNext']").click

    # successfully got users
    expect(f("body")).not_to contain_css("svg[role='img'] circle")
    expect(f("svg[name='IconCheckMark']")).to be_displayed
    expect(f("span[alt='Avatar for #{@temp_teacher.name}']")).to be_displayed
    expect(f("span[alt='Avatar for #{@temp_teacher_2.name}']")).to be_displayed
    f("button[data-analytics='TempEnrollNext']").click

    # create user
    f("button[data-analytics='TempEnrollSubmit']").click
    expect(flash_alert.text).to include("successfully created")

    # expect icons to reflect temp enrollment
    load_people_page
    wait_for_ajax_requests
    expect(ff("button[data-analytics='TempEnrollIconCalendarReservedSolid']").length).to eq(2)
    # displayed in the recipient's row since temp enrolls can chain
    expect(can_provide).to be_displayed
  end

  # since TempEnrollSearch checks internal state before making API call
  # can only be tested via selenium
  it "fails search" do
    # open modal
    load_people_page
    wait_for_ajax_requests
    can_provide.click

    # search for user
    f("[for='peoplesearch_radio_unique_id']").click
    f("textarea").send_keys("no_one")
    f("button[data-analytics='TempEnrollNext']").click

    # page stays same and error message
    expect(f("body")).not_to contain_css("svg[role='img'] circle")
    expect(f("svg[name='IconNo']")).to be_displayed
    expect(f("textarea")).to be_displayed
  end

  context "modify" do
    before do
      @temp_enrollment = create_enrollment(@course, @temp_teacher, temporary_enrollment_source_user_id: @teacher.id)
    end

    it "deletes existing pairing from provider view" do
      load_people_page

      # open modal
      wait_for_ajax_requests
      is_provider.click

      # delete enrollment
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      f("button[data-analytics='TempEnrollDelete']").click
      accept_alert
      expect(flash_alert.text).to include("deleted successfully")

      # expect no recipient/provider icons
      load_people_page
      wait_for_ajax_requests
      expect(can_provide).to be_displayed
      expect(f("body")).not_to contain_css("button[data-analytics='TempEnrollIconCalendarClockSolid']")
      expect(f("body")).not_to contain_css("button[data-analytics='TempEnrollIconCalendarReservedSolid']")
    end

    it "edits existing pairing from recipient view" do
      load_people_page

      # open modal
      wait_for_ajax_requests
      is_recipient.click

      # edit enrollment
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      f("button[data-analytics='TempEnrollEdit']").click

      # change role to Designer and save
      f("input[data-analytics='TempEnrollRole']").click
      f("span[label='Designer']").click
      f("button[data-analytics='TempEnrollSubmit']").click
      expect(flash_alert.text).to include("successfully updated")

      # reopen modal to confirm change
      wait_for_ajax_requests
      is_recipient.click
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      expect(fj("span[role='dialog']:contains('DesignerEnrollment')")).to be_displayed
    end

    it "views pairing from user page" do
      # add additional enrollment with same pairing id to test if rows are rendered correctly
      course2 = course_with_teacher({ user: @teacher, active_course: true, active_enrollment: true }).course
      temp_enrollment2 = create_enrollment(course2, @temp_teacher, temporary_enrollment_source_user_id: @teacher.id)
      temp_enrollment2.update(temporary_enrollment_pairing_id: @temp_enrollment.temporary_enrollment_pairing_id)

      # load page
      get "/users/#{@teacher.id}"

      wait_for_ajax_requests
      f("#manage-temp-enrollments-mount-point > button").click

      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      expect(ff("span[name='temp_teacher']").length).to eq(1)
    end
  end
end
