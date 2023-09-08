# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "Web conferences" do
  include_context "in-process server selenium tests"
  include ConferencesCommon
  include WebMock::API

  before(:once) do
    initialize_wimba_conference_plugin
    course_with_teacher(name: "Teacher Bob", active_all: true)
    course_with_ta(name: "TA Alice", course: @course, active_all: true)
    4.times do |i|
      course_with_student(name: "Student_#{i + 1}", course: @course, active_all: true)
    end
  end

  before do
    user_session(@teacher)
  end

  after do
    accept_alert if alert_present?
    close_extra_windows
  end

  context "when bbb_modal_update is ON", :ignore_js_errors do
    before :once do
      Account.site_admin.enable_feature! :bbb_modal_update
    end

    it "disables unchangeable properties when conference has begun" do
      conf = create_wimba_conference
      conf.started_at = 1.hour.ago
      conf.end_at = 1.day.from_now
      conf.save!

      get conferences_index_page
      fj("li.conference a:contains('Settings')").click
      fj("a:contains('Edit')").click
      expect(f("span[data-testid='duration-input'] input")).to be_disabled
      expect(f("input[value='no_time_limit']")).to be_disabled
    end

    it "validates name length" do
      initial_conference_count = WebConference.count
      get conferences_index_page
      stub_request(:get, /wimba\.instructure\.com/)
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
      stub_request(:get, /wimba\.instructure\.com/)
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

    it "invites specific course members" do
      get conferences_index_page
      stub_request(:get, /wimba\.instructure\.com/)
      f("button[title='New Conference']").click
      fj("label:contains('Invite all course members')").click
      f("[data-testid='address-input']").click
      wait_for_ajaximations
      f("[data-testid='user-#{@student.id}']").click
      fj("button:contains('Create')").click
      wait_for_ajaximations
      expect(WebConference.last.invitees.pluck(:id)).to eq [@student.id]
    end

    it "invites course members async" do
      Setting.set("max_invitees_sync_size", 5)

      get conferences_index_page
      stub_request(:get, /wimba\.instructure\.com/)
      f("button[title='New Conference']").click
      fj("button:contains('Create')").click
      wait_for_ajaximations
      run_jobs
      expect(WebConference.last.invitees.count).to eq 7
    end

    it "can exclude observers on creation" do
      my_observer = user_factory(name: "Cogsworth", active_all: true)
      @course.enroll_user(my_observer, "ObserverEnrollment", { associated_user_id: @student.id })
      get conferences_index_page
      stub_request(:get, /wimba\.instructure\.com/)
      f("button[title='New Conference']").click
      fj("label:contains('Remove all course observer members')").click
      fj("button:contains('Create')").click
      wait_for_ajaximations
      my_conf = WimbaConference.last
      expect(my_conf.invitees.pluck(:id)).to include(@ta.id)
      expect(my_conf.invitees.pluck(:id)).not_to include(my_observer.id)
    end
  end

  context "when bbb_modal_update is OFF", :ignore_js_errors do
    before :once do
      Account.site_admin.disable_feature! :bbb_modal_update
    end

    context "when creating a conference" do
      it "invites a subset of users", priority: "1" do
        skip_if_safari(:alert)
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        conference_title = "Private Conference by Invitation Only"
        create_conference(title: conference_title, invite_all_users: false)
        verify_conference_list_includes(conference_title)
      end

      it "invites all the course users", priority: "1" do
        skip_if_safari(:alert)
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        conference_title = "Course Conference"
        create_conference(title: conference_title, invite_all_users: true)
        verify_conference_list_includes(conference_title)
      end

      it "includes observers in manual invite", priority: "1" do
        skip_if_safari(:alert)
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        course_with_observer(name: "Observer Kim", course: @course, active_all: true)
        get conferences_index_page
        new_conference_button.click
        f(".all_users_checkbox").click
        expect(f("#members_list")).to include_text("Kim, Observer")
      end
    end

    context "when concluding a conference" do
      let(:conference_title) { "Newer Conference" }

      before(:once) do
        conference = create_wimba_conference(conference_title)
        conference.add_attendee(@user)
      end

      context "as a teacher" do
        it "concludes the conference", priority: "1" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          end_first_conference_in_list
          verify_conference_list_is_empty
          verify_concluded_conference_list_includes(conference_title)
        end

        it "does not treat the concluded conference as active", priority: "2" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          end_first_conference_in_list
          refresh_page
          expect(f("#new-conference-list .emptyMessage").text).to include("There are no new conferences")
        end
      end

      context "as a TA invited to the conference" do
        before do
          user_session(@ta)
          get conferences_index_page
        end

        it "concludes the conference", priority: "1" do
          end_first_conference_in_list
          verify_conference_list_is_empty
          verify_concluded_conference_list_includes(conference_title)
        end
      end
    end

    context "when no conferences exist" do
      it "displays initial elements of the conference page", priority: "1" do
        skip_if_safari(:alert)
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        expect(new_conference_button).to be_present

        headers = ff(".element_toggler")
        expect(headers[0]).to include_text("New Conferences")
        verify_conference_list_is_empty

        expect(headers[1]).to include_text("Concluded Conferences")
        verify_concluded_conference_list_is_empty
      end

      it "creates a web conference", priority: "1" do
        skip_if_safari(:alert)
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        conference_title = "A New Web Conference"
        create_conference(title: conference_title, invite_all_users: true)
        verify_conference_list_includes(conference_title)
      end

      it "cancels creating a web conference", priority: "2" do
        skip_if_safari(:alert)
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        create_conference(cancel: true)
        expect(f("#add_conference_form")).not_to be_displayed
        verify_conference_list_is_empty
      end
    end

    context "when one conference exists" do
      before(:once) { @conference = create_wimba_conference("A Conference", 1234) }

      context "when the conference is open" do
        it "deletes active conferences", priority: "1" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          delete_conference
          verify_conference_list_is_empty
        end

        it "sets focus to the Add Conference button if there are no preceeding conferences", priority: "2" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          delete_conference
          check_element_has_focus(new_conference_button)
        end

        it "sets focus to the cog menu if the delete was cancelled", priority: "2" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          cog_menu_item = f(".al-trigger")
          delete_conference(cog_menu_item:, cancel: true)
          check_element_has_focus(cog_menu_item)
        end

        it "opens editor if edit selected from cog menu", priority: "2" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          cog_menu_item = f(".al-trigger")
          edit_conference(cog_menu_item:, cancel: false)

          duration_edit_field = f("#web_conference_duration")

          expect(duration_edit_field).to be_displayed # input field w/in editor
          # value is localized
          expect(duration_edit_field.attribute("value")).to eq("1,234")
        end
      end

      context "when the conference is concluded" do
        before(:once) { conclude_conference(@conference) }

        it "deletes concluded conferences", priority: "2" do
          get conferences_index_page
          stub_request(:get, /wimba\.instructure\.com/)
          delete_conference
          verify_concluded_conference_list_is_empty
        end
      end
    end

    context "when two conferences exist" do
      before(:once) do
        create_wimba_conference("First Wimba Conference")
        create_wimba_conference("Second Wimba Conference")
      end

      it "sets focus to the preceding conference's cog after deleting", priority: "2" do
        get conferences_index_page
        stub_request(:get, /wimba\.instructure\.com/)
        settings_triggers = ff(".al-trigger")
        delete_conference(cog_menu_item: settings_triggers.last)
        check_element_has_focus(settings_triggers.first)
      end
    end
  end
end
