# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative "../helpers/conferences_common"
require_relative "../helpers/public_courses_context"

describe "BigBlueButton conferences" do
  include_context "in-process server selenium tests"
  include ConferencesCommon
  include WebMock::API

  bbb_endpoint = "bbb.blah.com"
  bbb_secret = "mock-secret"
  bbb_fixtures = {
    get_recordings: {
      "meetingID" => "instructure_web_conference_3Fn2k10wu0jK7diwJHs2FkDU0oXyX1ErUZCavikc",
      "checksum" => "9f41063382ab155ccf75fe2f212846e3bb103579"
    },
    delete_recordings: {
      "recordID" => "0225ccf234655ae60658ccac1e272d48781b491c-1511812307014",
      "checksum" => "4aefca80ba80ba3d540295ea3e88215df77cf5cf"
    }
  }

  before(:once) do
    initialize_big_blue_button_conference_plugin bbb_endpoint, bbb_secret
    course_with_teacher(name: "Teacher Bob", active_all: true)
    course_with_ta(name: "TA Alice", course: @course, active_all: true)
    course_with_student(name: "Student John", course: @course, active_all: true)
  end

  before do
    user_session(@teacher)
    # ensure requests that aren't stubbed don't actually attempt to hit blah.com
    # (the "real" stubs take precedence)
    WebMock.stub_request(:any, /bbb.blah.com/)
           .to_return(body: big_blue_button_mock_response("failed", "notstubbed"))
  end

  after do
    accept_alert if alert_present?
  end

  after { close_extra_windows }

  context "when bbb_modal_update is ON", :ignore_js_errors do
    before(:once) do
      Account.site_admin.enable_feature! :bbb_modal_update
    end

    context "when a conference exists" do
      before do
        @conf = create_big_blue_button_conference
        @conf.add_invitee(@ta)
        @conf.add_invitee(@student)
        @conf.save!
      end

      it "opens edit form when conference id is in url for teachers" do
        get "/courses/#{@course.id}/conferences/#{@conf.id}"
        expect(fj("span:contains('Edit')")).to be_present
      end

      it "does not open edit form when conference id is in url for students" do
        user_session @student
        get "/courses/#{@course.id}/conferences/#{@conf.id}"
        expect(f("button[title='New Conference']")).to be_present
        expect(f("body")).not_to contain_jqcss("span:contains('Edit')")
      end
    end

    context "attendee selection" do
      before do
        @section = @course.course_sections.create!(name: "test section")
        student_in_section(@section, user: @student)

        @group_category = @course.group_categories.create!(name: "Group Category")
        @group = @course.groups.create!(group_category: @group_category, name: "Group 1")
        @group.add_user(@student, "accepted")
        @empty_group = @course.groups.create!(group_category: @group_category, name: "Empty Group")
      end

      context "on create" do
        it "successfully invites a section to the conference" do
          get "/courses/#{@course.id}/conferences"
          new_conference_button.click
          wait_for_ajaximations
          f("div#tab-attendees").click
          fj("label:contains('Invite all course members')").click

          # side test: make sure no empty groups are pre-selected
          expect(f("body")).not_to contain_jqcss("button[title='Remove Empty Group: Unnamed']")

          f("[data-testid='address-input']").click
          f("[data-testid='section-#{@section.id}']").click
          expect(@section.participants.count).to eq ff("[data-testid='address-tag']").count

          wait_for_new_page_load { f("button[data-testid='submit-button']").click }
          new_conference = WebConference.last
          expect(@section.participants.count).to eq new_conference.users.count
        end

        it "successfully invites a group to the conference" do
          get "/courses/#{@course.id}/conferences"
          # Since the teacher isn't a participating user, we have to add 1 to this count
          group_participant_and_group_tag_count = @group.participating_users_in_context.count + 1

          new_conference_button.click
          wait_for_ajaximations
          f("div#tab-attendees").click
          fj("label:contains('Invite all course members')").click
          f("[data-testid='address-input']").click
          f("[data-testid='group-#{@group.id}']").click
          expect(group_participant_and_group_tag_count).to eq ff("[data-testid='address-tag']").count

          wait_for_new_page_load { f("button[data-testid='submit-button']").click }
          new_conference = WebConference.last
          expect(group_participant_and_group_tag_count).to eq new_conference.users.count
        end

        it "succesfully creates a group BBB conference" do
          get "/groups/#{@group.id}/conferences"
          group_participant_and_group_tag_count = @group.participating_users_in_context.count + 1

          new_conference_button.click
          wait_for_ajaximations

          wait_for_new_page_load { f("button[data-testid='submit-button']").click }

          new_conference = WebConference.last
          expect(new_conference.users.count).to eq group_participant_and_group_tag_count
          expect(new_conference.context_code).to eq "group_#{@group.id}"
        end
      end
    end

    it "validates name length" do
      initial_conference_count = WebConference.count
      get conferences_index_page
      name_255_chars = "Y3298V7EQwLC8chKnXTz5IFARakIP0k2Yk0nLQ7owgidY6zDQnh9nCmH8z033TnJ1ssFwYtCkKwyhB7HkUN9ZF3u2s1shsj4vYqUlsEQmPljTGFBtO43pCh1QquQUnM2yCsiS5nnCRefjTK7jMwAiOXTZeyFvPk3tLzPAmOwf1Od6vtOB5nfXFSPVYyxSNcl85ySG8SlBoOULqF1IZV0BwE4TLthJV8Ab1h7xW0CbjHaJLMTQtnWK6ntTLxSNi4"
      f("button[title='New Conference']").click
      f("input[placeholder='Conference Name']").clear
      f("input[placeholder='Conference Name']").send_keys name_255_chars
      f("input[placeholder='Conference Name']").send_keys "a" # 256th char
      expect(fj("span:contains('Name must be less than 255 characters')")).to be_present
      expect(f("button[data-testid='submit-button']")).not_to be_enabled

      # bring it back down to 255 chars
      f("input[placeholder='Conference Name']").send_keys :backspace
      expect(f("body")).not_to contain_jqcss("span:contains('Name must be less than 255 characters')")
      expect(f("button[data-testid='submit-button']")).to be_enabled

      f("button[data-testid='submit-button']").click
      wait_for_ajaximations
      expect(WebConference.count).to be > initial_conference_count
    end

    it "validates duration length" do
      initial_conference_count = WebConference.count
      get conferences_index_page
      number_larger_than_8_digits = 999_999_990
      f("button[title='New Conference']").click
      f("span[data-testid='duration-input'] input").clear
      f("span[data-testid='duration-input'] input").send_keys number_larger_than_8_digits
      # f("input[placeholder='Conference Name']").send_keys "a" # 256th char
      expect(fj("span:contains('Duration must be less than 99,999,999 minutes')")).to be_present
      expect(f("button[data-testid='submit-button']")).not_to be_enabled

      # bring it back down to 255 chars
      f("span[data-testid='duration-input'] input").send_keys :backspace
      expect(f("body")).not_to contain_jqcss("span:contains('Duration must be less than 99,999,999 minutes')")
      expect(f("button[data-testid='submit-button']")).to be_enabled

      f("button[data-testid='submit-button']").click
      wait_for_ajaximations
      expect(WebConference.count).to be > initial_conference_count
    end

    it "persists selected settings" do
      get conferences_index_page
      f("button[title='New Conference']").click

      f("input[placeholder='Conference Name']").send_keys "banana"
      # check it
      fj("label:contains('No time limit')").click

      f("div#tab-attendees").click

      # unchecks the following
      fj("label:contains('Share webcam')").click
      fj("label:contains('See other viewers webcams')").click
      fj("label:contains('Share microphone')").click
      fj("label:contains('Send public chat messages')").click
      fj("label:contains('Send private chat messages')").click
      fj("button:contains('Create')").click
      wait_for_ajaximations

      fj("li.conference a:contains('Settings')").click
      fj("a:contains('Edit')").click

      expect(f("input[value='no_time_limit']").attribute("checked")).to be_truthy

      f("div#tab-attendees").click
      expect(f("input[value='share_webcam']").attribute("checked")).to be_falsey
      expect(f("input[value='share_other_webcams']").attribute("checked")).to be_falsey
      expect(f("input[value='share_microphone']").attribute("checked")).to be_falsey
      expect(f("input[value='send_public_chat']").attribute("checked")).to be_falsey
      expect(f("input[value='send_private_chat']").attribute("checked")).to be_falsey
    end

    it "syncs in unadded context users on option select and able to delete successfully" do
      conf = create_big_blue_button_conference
      conf.add_invitee(@ta)
      expect(conf.invitees.pluck(:id)).to match_array [@ta.id]

      get conferences_index_page
      fj("li.conference a:contains('Settings')").click
      f(".sync_conference_link").click
      wait_for_ajaximations
      expect(conf.invitees.pluck(:id)).to include(@ta.id, @student.id)

      fj("li.conference a:contains('Settings')").click
      f("a[title='Delete']").click
      accept_alert
      wait_for_ajaximations
      expect { conf.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not show add to calendar option to users without :manage_calendar permissions" do
      user_session(@student)
      get conferences_index_page
      f("button[title='New Conference']").click
      expect(f("input[placeholder='Conference Name']")).to be_present
      expect(f("body")).not_to contain_jqcss("input[value='add_to_calendar']")
    end

    it "has a working add to calendar option on create" do
      get conferences_index_page
      f("button[title='New Conference']").click

      f("input[value='add_to_calendar'] + label").click
      driver.switch_to.alert.accept
      wait_for_ajaximations

      start_date_picker = fj("label:contains('Start Date')")
      end_date_picker = fj("label:contains('End Date')")
      # for both dates, we will base the selection off of the row of the 15th.
      # no matter the current date when the test is being done, this row will
      # always be enabled
      start_date_picker.click
      fj("button:contains('15')").find_element(:xpath, "../..").find_elements(:css, "button").first.click
      end_date_picker.click
      fj("button:contains('15')").find_element(:xpath, "../..").find_elements(:css, "button").last.click
      fj("button:contains('Create')").click
      wait_for_ajaximations

      ce = CalendarEvent.last
      wc = WebConference.last
      expect(ce.web_conference_id).to eq wc.id
      expect(ce.start_at).to eq wc.start_at
    end

    it "does not invite all if add to calendar cancels" do
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
      get conferences_index_page
      new_conference_button.click

      # unclick invite all course members
      f("div#tab-attendees").click
      expect(f("input[value='invite_all']").attribute("checked")).to be_truthy
      fj("label:contains('Invite all course members')").click
      expect(f("input[value='invite_all']").attribute("checked")).to be_falsey

      # invite course members
      f("[data-testid='address-input']").click
      f("[data-testid='section-#{@section.id}']").click
      expect(@section.participants.count).to eq ff("[data-testid='address-tag']").count

      # click, then cancel add to calendar
      f("div#tab-settings").click
      f("input[value='add_to_calendar'] + label").click
      driver.switch_to.alert.dismiss
      wait_for_ajaximations

      # ensure add to calendar remains unclicked
      expect(f("input[type='checkbox'][value='add_to_calendar']").attribute("checked")).to be_falsey

      # ensure invite all course members remains unclicked
      # ensure course members still remain
      f("div#tab-attendees").click
      expect(f("input[value='invite_all']").attribute("checked")).to be_falsey
      expect(@section.participants.count).to eq ff("[data-testid='address-tag']").count
    end

    it "unchecks remove observers if invite_all is unchecked." do
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
      get conferences_index_page
      new_conference_button.click

      # unclick invite all course members
      f("div#tab-attendees").click
      expect(f("input[value='invite_all']").attribute("checked")).to be_truthy
      expect(f("input[value='remove_observers']").attribute("checked")).to be_falsey

      # check remove observers
      fj("label:contains('Remove all course observer members')").click
      expect(f("input[value='remove_observers']").attribute("checked")).to be_truthy

      # uncheck invite all
      fj("label:contains('Invite all course members')").click
      expect(f("input[value='invite_all']").attribute("checked")).to be_falsey
      expect(f("input[value='remove_observers']").attribute("checked")).to be_falsey
      expect(f("input[value='remove_observers']").attribute("disabled")).to be_truthy
    end

    it "disables unchangeable properties when conference has begun" do
      conf = create_big_blue_button_conference
      conf.start_at = 2.hours.ago
      conf.started_at = 1.hour.ago
      conf.end_at = 1.day.from_now
      conf.save!

      get conferences_index_page
      fj("li.conference a:contains('Settings')").click
      fj("a:contains('Edit')").click
      expect(f("span[data-testid='duration-input'] input")).to be_disabled
      expect(f("input[value='no_time_limit']")).to be_disabled
      expect(f("input[value='enable_waiting_room']")).to be_disabled
      expect(f("input[value='add_to_calendar']")).to be_disabled
      expect(fj("span[data-testid='plain-text-dates']:contains('Start at:')")).to be_present
      expect(fj("span[data-testid='plain-text-dates']:contains('End at:')")).to be_present
      expect(f("body")).not_to contain_jqcss("input[label='Start Date']")
      expect(f("body")).not_to contain_jqcss("input[label='End Date']")
      f("div#tab-attendees").click
      lock_options = ff("input[name='attendees_options']")
      expect(lock_options).to all(be_disabled)
    end

    it "sets start and end date on WebConference when created and edited from the calendar" do
      skip "FOO-3804 (10/6/2023)"
      get "/calendar"

      # Create calendar event with conference
      f("a#create_new_event_link").click
      f("input[placeholder='Input Event Title...']").send_keys "BBB Conference from Calendar"

      f("input[data-testid='event-form-start-time']").click
      f("input[data-testid='event-form-start-time']").send_keys(:arrow_down)
      f("input[data-testid='event-form-start-time']").send_keys(:enter)

      f("input[data-testid='event-form-end-time']").click
      5.times { f("input[data-testid='event-form-end-time']").send_keys(:arrow_down) }
      f("input[data-testid='event-form-end-time']").send_keys(:enter)

      f("input[data-testid='edit-calendar-event-form-context']").click
      f("input[data-testid='edit-calendar-event-form-context']").send_keys(:arrow_down)
      f("input[data-testid='edit-calendar-event-form-context']").send_keys(:enter)

      fj('button:contains("Add BigBlueButton")').click
      wait_for_ajaximations

      f("button[type=submit]").click

      ce = CalendarEvent.last
      wc = WebConference.last

      wc_before_start_at = wc.start_at
      wc_before_end_at = wc.end_at

      # Make sure values are correctly and as expected
      expect(ce.web_conference_id).to eq wc.id
      expect(wc.title).to eq "BBB Conference from Calendar"
      expect(ce.start_at).to eq wc.start_at
      expect(ce.end_at).to eq wc.end_at

      # Edit calendar event
      fj("a:contains('BBB Conference from Calendar')").click
      fj('button:contains("Edit")').click

      f("input[data-testid='event-form-start-time']").click
      5.times { f("input[data-testid='event-form-start-time']").send_keys(:arrow_down) }
      f("input[data-testid='event-form-start-time']").send_keys(:enter)

      f("input[data-testid='event-form-end-time']").click
      10.times { f("input[data-testid='event-form-end-time']").send_keys(:arrow_down) }
      f("input[data-testid='event-form-end-time']").send_keys(:enter)

      f("button[type=submit]").click
      wait_for_ajaximations

      ce.reload
      wc.reload

      wc_after_start_at = wc.start_at
      wc_after_end_at = wc.end_at

      # Make sure edited values are correctly and as expected
      expect(ce.start_at).to eq wc.start_at
      expect(ce.end_at).to eq wc.end_at

      expect(wc_before_start_at).to be < wc_after_start_at
      expect(wc_before_end_at).to be < wc_after_end_at
    end

    it "do not check Add to Calendar when the conference without calendar starts" do
      get "/courses/#{@course.id}/conferences"
      new_conference_button.click
      wait_for_ajaximations

      wait_for_new_page_load { f("button[data-testid='submit-button']").click }

      f("a.start-button").click
      wait_for_ajaximations

      fj("li.conference a:contains('Settings')").click
      fj("a:contains('Edit')").click

      expect(f("input[value='add_to_calendar']").attribute("checked")).to be_falsey
      new_conference = WebConference.last
      expect(new_conference.has_calendar_event).to eq 0
    end
  end

  context "when bbb_modal_update is OFF" do
    before(:once) do
      Account.site_admin.disable_feature! :bbb_modal_update
    end

    context "on a conference that exists" do
      before do
        @conf = create_big_blue_button_conference
        @conf.add_invitee(@ta)
        @conf.add_invitee(@student)
        @conf.save!
      end

      it "opens edit form when conference id is in url for teachers" do
        get "/courses/#{@course.id}/conferences/#{@conf.id}"
        expect(fj("span:contains('Edit')")).to be_present
      end

      it "does not open edit form when conference id is in url for students" do
        user_session @student
        get "/courses/#{@course.id}/conferences/#{@conf.id}"
        expect(f("button[title='New Conference']")).to be_present
        expect(f("body")).not_to contain_jqcss("span:contains('Edit')")
      end

      it "does not show sync attendees option" do
        get "/courses/#{@course.id}/conferences/#{@conf.id}"
        expect(f("body")).not_to contain_jqcss ".sync_conference_link"
      end
    end

    context "when a conference is open", :ignore_js_errors do
      it "displays start and end dates by description" do
        conf = create_big_blue_button_conference

        # far in the future, will need to be changed after these dates
        conf.start_at = Date.parse("2999-07-01")
        conf.end_at = Date.parse("2999-07-02")
        conf.description = "this is the description"
        conf.save!

        get conferences_index_page
        expect(fj("div:contains('Jul 1, 2999')")).to be_present
        expect(fj("div:contains('to')")).to be_present
        expect(fj("div:contains('Jul 2, 2999')")).to be_present
        expect(fj("div:contains('#{conf.description}')")).to be_present
      end

      context "and the conference has no recordings" do
        before do
          stub_request(:get, /getRecordings/)
            .with(query: bbb_fixtures[:get_recordings])
            .to_return(body: big_blue_button_mock_response("get_recordings", "none"))
          @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]["meetingID"])
        end

        it "does not include list with recordings", priority: "2" do
          get conferences_index_page
          verify_conference_does_not_include_recordings
        end
      end

      context "and the conference has recordings" do
        before do
          stub_request(:get, /getRecordings/)
            .with(query: bbb_fixtures[:get_recordings])
            .to_return(body: big_blue_button_mock_response("get_recordings", "two"))
          @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]["meetingID"])
        end

        it "includes list with recordings", priority: "2" do
          @conference.ended_at = 2.days.ago
          @conference.save!
          get conferences_index_page
          fj("a:contains('#{@conference.title}')").click

          # if the first letter is capitalized, this means
          # the helper method for translating was called
          expect(fj("div.ig-details a:contains('Statistics')")).to be_truthy
          expect(fj("div.ig-details a:contains('Presentation')")).to be_truthy
          expect(fj("div.ig-details a:contains('Video')")).to be_truthy
        end
      end

      context "and the conference has one recording and it is deleted" do
        before do
          stub_request(:get, /deleteRecordings/)
            .with(query: bbb_fixtures[:delete_recordings])
            .to_return(body: big_blue_button_mock_response("delete_recordings"))
          stub_request(:get, /getRecordings/)
            .with(query: bbb_fixtures[:get_recordings])
            .to_return(body: big_blue_button_mock_response("get_recordings", "one"))
          @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]["meetingID"])
        end

        it "removes recording from the list", priority: "2" do
          get conferences_index_page
          show_recordings_in_first_conference_in_list
          delete_first_recording_in_first_conference_in_list
          verify_conference_does_not_include_recordings
        end
      end

      context "and the conference has one recording with statistics" do
        before do
          stub_request(:get, /getRecordings/)
            .with(query: bbb_fixtures[:get_recordings])
            .to_return(body: big_blue_button_mock_response("get_recordings", "one"))
          @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]["meetingID"])
          @conference.add_user(@student, "attendee")
        end

        it "student should not see link for statistics", priority: "2" do
          user_session(@student)
          get conferences_index_page
          show_recordings_in_first_conference_in_list
          verify_conference_does_not_include_recordings_with_statistics
        end
      end
    end
  end
end
