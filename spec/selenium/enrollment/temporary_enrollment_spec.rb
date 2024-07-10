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

  before do
    Account.default.enable_feature!(:temporary_enrollments)
    @teacher = user_factory(name: "teacher")
    @teacher.register!
    @course = course_with_teacher({ user: @teacher, active_course: true, active_enrollment: true }).course

    user_with_pseudonym(name: "temp_teacher", active_user: true, username: "tempTeacher", account: Account.default)
    @temp_teacher = User.find_by(name: "temp_teacher")

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

  # nearly every page of the modal requires an api call, so we wait before interacting with each
  it "creates pairing" do
    # open modal
    load_people_page
    wait_for_ajax_requests
    can_provide.click

    # search for user
    f("[for='peoplesearch_radio_unique_id']").click
    f("input[data-analytics='TempEnrollTextInput']").send_keys("tempTeacher")
    f("button[data-analytics='TempEnrollNext']").click

    # successfully got user
    expect(f("body")).not_to contain_css("svg[role='img'] circle")
    expect(f("svg[name='IconCheckMark']")).to be_displayed
    expect(f("span[alt='Avatar for #{@temp_teacher.name}']")).to be_displayed
    f("button[data-analytics='TempEnrollNext']").click

    # create user
    f("button[data-analytics='TempEnrollSubmit']").click

    # expect icons to reflect temp enrollment
    load_people_page
    wait_for_ajax_requests
    expect(is_recipient).to be_displayed
    # displayed in the recipient's row since temp enrolls can chain
    expect(can_provide).to be_displayed
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

      # reopen modal to confirm change
      load_people_page
      wait_for_ajax_requests
      is_recipient.click
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      expect(fj("span[role='dialog']:contains('DesignerEnrollment')")).to be_displayed
    end
  end
end
