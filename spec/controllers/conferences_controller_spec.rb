# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

require_relative "../apis/api_spec_helper"

describe ConferencesController do
  include ExternalToolsSpecHelper

  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: "wimba")
    @plugin.update_attribute(:settings, { domain: "wimba.test" })
    course_with_teacher(active_all: true, user: user_with_pseudonym(active_all: true))
    @inactive_student = course_with_user("StudentEnrollment", course: @course, enrollment_state: "invited").user
    student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
  end

  before do
    allow_any_instance_of(WimbaConference).to receive(:send_request).and_return("")
    allow_any_instance_of(WimbaConference).to receive(:get_auth_token).and_return("abc123")
  end

  describe "GET 'index'" do
    it "requires authorization" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 12, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns variables" do
      user_session(@student)
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "does not redirect from group context" do
      user_session(@student)
      @group = @course.groups.create!(name: "some group")
      @group.add_user(@student)
      get "index", params: { group_id: @group.id }
      expect(response).to be_successful
    end

    it "does not include the student view student" do
      user_session(@teacher)
      @student_view_student = @course.student_view_student
      get "index", params: { course_id: @course.id }
      expect(assigns[:users].include?(@student)).to be_truthy
      expect(assigns[:users].include?(@student_view_student)).to be_falsey
    end

    it "doesn't include inactive users" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(assigns[:users].include?(@student)).to be_truthy
      expect(assigns[:users].include?(@inactive_student)).to be_falsey
    end

    it "does not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(active_user: true)
      expect(@course).not_to be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "does not list conferences that use a disabled plugin" do
      user_session(@teacher)
      plugin = PluginSetting.create!(name: "adobe_connect")
      plugin.update_attribute(:settings, { domain: "adobe_connect.test" })

      @conference = @course.web_conferences.create!(conference_type: "AdobeConnect", duration: 60, user: @teacher)
      plugin.disabled = true
      plugin.save!
      get "index", params: { course_id: @course.id }
      expect(assigns[:new_conferences]).to be_empty
    end

    it "preloads recordings for BBB conferences" do
      PluginSetting.create!(name: "big_blue_button",
                            settings: {
                              domain: "bbb.totallyanexampleplzdontcallthis.com",
                              secret_dec: "secret",
                            })
      allow(BigBlueButtonConference).to receive(:send_request).and_return("")

      user_session(@teacher)
      @bbb = BigBlueButtonConference.create!(title: "my conference", user: @teacher, context: @course)
      @other = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)

      expect(BigBlueButtonConference).to receive(:preload_recordings).with([@bbb])
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "includes group and section data in the js_env" do
      group(context: @course)
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:groups]).to be_truthy
      expect(assigns[:js_env][:sections]).to be_truthy
      expect(assigns[:js_env][:group_user_ids_map]).to be_truthy
      expect(assigns[:js_env][:section_user_ids_map]).to be_truthy
    end

    it "assigns context_name to course name when context is course" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:context_name]).to eq @course.name
    end

    it "assigns context_name to group name when context is group" do
      user_session(@teacher)
      @group = @course.groups.create!(name: "some group")
      @group.add_user(@student)
      get "index", params: { group_id: @group.id }
      expect(assigns[:js_env][:context_name]).to eq @group.name
    end

    it "assigns only active sections in the js_env" do
      @section = @course.course_sections.create!(name: "test section")
      @section_deleted = @course.course_sections.create!(name: "test section deleted")
      @section_deleted.destroy
      @course.reload
      group(context: @course)
      user_session(@teacher)
      get "index", params: { course_id: @course.id }

      expect(@controller.js_env[:sections].include?({ id: @section.id, name: @section.display_name })).to be_truthy
      expect(@controller.js_env[:sections].include?({ id: @section_deleted.id, name: @section_deleted.display_name })).to be_falsey
    end

    context "sets render_alternatives variable" do
      it "sets to false by default" do
        user_session(@teacher)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:render_alternatives]).to be_falsey
      end

      it "sets to true if plugins are set to replace_with_alternatives" do
        user_session(@teacher)
        @plugin.update_attribute(:settings, @plugin.settings.merge(replace_with_alternatives: true))
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:render_alternatives]).to be_truthy
      end

      context "should set to true if course setting show_conference_alternatives is set" do
        before do
          @course.update! settings: @course.settings.merge(show_conference_alternatives: true)
        end

        it "when context is a group" do
          user_session(@student)
          @group = @course.groups.create!(name: "some group")
          @group.add_user(@student)
          get "index", params: { group_id: @group.id }
          expect(assigns[:js_env][:render_alternatives]).to be_truthy
        end

        it "when context is a course" do
          user_session(@teacher)
          get "index", params: { course_id: @course.id }
          expect(assigns[:js_env][:render_alternatives]).to be_truthy
        end
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba" } }
      assert_unauthorized
    end

    it "creates a conference" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba" } }, format: "json"
      expect(response).to be_successful
    end

    it "rejects conference titles over 255 chars" do
      long_str = "OriZgOYyEdGdEmC9jiUkwbw3W6VpNLhOMVHblHpR5nehnsl1m6LFb8dwfHnX1IypOxN1ZTeVnggudhEv37dOUbLyzmEMHCRpohlDP2kcazgzu1D4NLlJ2Bfhd7V1nhlqN6llXH6T0om4BG1TLwwPh1LUIuAETiA8Bp6ni2xpBYLb5dKgypvTqT3fMnolBnK0fxtyEpa97OPBfFsc2yJ4wvH33cdiVsl0EDQW8kzdVADYE1zzbR3gRwHBTVnh1tyN"
      user_session(@teacher)
      post "create", params: { course_id: @course.id, web_conference: { title: long_str, conference_type: "Wimba" } }, format: "json"
      expect(response).to have_http_status :bad_request
      res_body = response.parsed_body
      expect(res_body["errors"]["title"][0]["message"]).to eq "too_long"
    end

    it "creates a conference with observers removed" do
      user_session(@teacher)
      enrollment = observer_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
      post "create", params: { observers: { remove: "1" }, course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba" } }, format: "json"
      expect(response).to be_successful
      conference = WebConference.last
      expect(conference.invitees).not_to include(enrollment.user)
    end

    context "with concluded students in context" do
      context "with a course context" do
        it "does not invite students with a concluded enrollment" do
          user_session(@teacher)
          enrollment = student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
          enrollment.conclude
          post "create", params: { course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba" } }, format: "json"
          conference = WebConference.last
          expect(conference.invitees).not_to include(enrollment.user)
        end
      end

      context "with a group context" do
        it "does not invite students with a concluded enrollment" do
          user_session(@teacher)
          concluded_enrollment = student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
          concluded_enrollment.conclude

          enrollment = student_in_course(active_all: true, user: user_with_pseudonym(active_all: true))
          group_category = @course.group_categories.create(name: "category 1")
          group = @course.groups.create(name: "some group", group_category:)
          group.add_user enrollment.user, "accepted"
          group.add_user concluded_enrollment.user, "accepted"

          post "create", params: { group_id: group.id, web_conference: { title: "My Conference", conference_type: "Wimba" } }, format: "json"
          conference = WebConference.last
          expect(conference.invitees).not_to include(concluded_enrollment.user)
          expect(conference.invitees).to include(enrollment.user)
        end
      end
    end

    context "with calendar event" do
      it "creates a conference and event correctly" do
        user_session(@teacher)

        post "create", params: { course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba", calendar_event: "1" } }, format: "json"
        created_conference = WebConference.last
        created_calendar_event = created_conference.calendar_event

        expect(created_calendar_event).to be_truthy
        expect(created_calendar_event.context).to eq @course
        expect(response).to be_successful
      end

      it "does not create a calendar event when context is not a course" do
        user_session(@teacher)
        group = @course.groups.create!(name: "some group")
        group.add_user(@student)

        post "create", params: { group_id: group.id, web_conference: { title: "My Conference", conference_type: "Wimba", calendar_event: "1" } }, format: "json"
        created_conference = WebConference.last
        created_calendar_event = created_conference.calendar_event

        expect(created_calendar_event).to be_falsey
        expect(response).to be_successful
      end

      it "creates a calendar event when calendar_event is set, with start_at and end_at params" do
        user_session(@teacher)
        start_time = Date.today
        end_time = Date.today + 1.day

        post "create", params: { course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba", calendar_event: "1", start_at: start_time, end_at: end_time } }, format: "json"
        created_conference = WebConference.last
        created_calendar_event = created_conference.calendar_event

        expect(created_calendar_event).to be_truthy
        expect(created_calendar_event.context).to eq @course
        expect(created_calendar_event.start_at).to eq start_time
        expect(created_calendar_event.end_at).to eq end_time
        expect(response).to be_successful
      end

      it "does not create a calendar_event when checkbox unchecked" do
        allow(WebConference).to receive(:plugins).and_return(
          [OpenObject.new(id: "big_blue_button", settings: { domain: "bbb.instructure.com", secret_dec: "secret" }, valid_settings?: true, enabled?: true),]
        )
        user_session(@teacher)
        post "create", params: { course_id: @course.id, web_conference: { title: "My Conference Nwahc", conference_type: "BigBlueButton", calendar_event: "0" } }, format: "json"
        created_conference = WebConference.last

        expect(created_conference.title).to eq("My Conference Nwahc")
        expect(created_conference.calendar_event).to be_falsey
        expect(response).to be_successful
      end
    end
  end

  describe "POST 'update'" do
    it "requires authorization" do
      post "create", params: { course_id: @course.id, web_conference: { title: "My Conference", conference_type: "Wimba" } }
      assert_unauthorized
    end

    it "updates a conference" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", user: @teacher)
      post "update", params: { course_id: @course.id, id: @conference, web_conference: { title: "Something else" } }, format: "json"
      expect(response).to be_successful
    end

    it "returns user ids" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", user: @teacher)
      params = {
        course_id: @course.id,
        id: @conference,
        web_conference: {
          title: "Something else"
        },
      }
      post :update, params:, format: :json
      body = response.parsed_body
      expect(body["user_ids"]).to include(@teacher.id)
      expect(body["user_ids"]).to include(@student.id)
    end

    it "syncs attendees" do
      @conference = @course.web_conferences.create!(conference_type: "Wimba", user: @teacher)
      @student2 = User.create
      @course.enroll_student(@student2, enrollment_state: "active")

      params = {
        course_id: @course.id,
        id: @conference,
        web_conference: {
          title: "Something else",
          sync_attendees: true
        },
      }
      user_session(@teacher)
      post :update, params:, format: :json
      body = response.parsed_body
      expect(body["user_ids"]).to include(@teacher.id)
      expect(body["user_ids"]).to include(@student.id)
      expect(body["user_ids"]).to include(@student2.id)
    end

    it "deletes calendar event when calendar_event is not set" do
      user_session(@teacher)
      allow(WebConference).to receive(:plugins).and_return(
        [OpenObject.new(id: "big_blue_button", settings: { domain: "bbb.instructure.com", secret_dec: "secret" }, valid_settings?: true, enabled?: true),]
      )

      @conference = @course.web_conferences.create!(conference_type: "BigBlueButton", duration: 60, user: @teacher)
      @conference.users << @student
      @conference.calendar_event = calendar_event_model
      @conference.save!

      params = {
        course_id: @course.id,
        id: @conference,
        web_conference: {
          title: "Something else",
          sync_attendees: "0",
          calendar_event: "0"
        },
      }

      post :update, params:, format: "json"

      created_conference = WebConference.find(@conference.id)
      created_calendar_event = created_conference.calendar_event

      expect(created_calendar_event).to be_falsey
      expect(response).to be_successful
    end

    it "does NOT delete calendar event when sync_attendees is passed" do
      user_session(@teacher)
      allow(WebConference).to receive(:plugins).and_return(
        [OpenObject.new(id: "big_blue_button", settings: { domain: "bbb.instructure.com", secret_dec: "secret" }, valid_settings?: true, enabled?: true),]
      )

      @conference = @course.web_conferences.create!(conference_type: "BigBlueButton", duration: 60, user: @teacher)
      @conference.users << @student
      @conference.calendar_event = calendar_event_model
      @conference.save!

      params = {
        course_id: @course.id,
        id: @conference,
        web_conference: {
          title: "Something else",
          sync_attendees: "1",
          calendar_event: "0"
        },
      }

      post :update, params:, format: "json"

      created_conference = WebConference.find(@conference.id)
      created_calendar_event = created_conference.calendar_event

      expect(created_calendar_event).to be_truthy
      expect(response).to be_successful
    end

    it "creates a calendar event when calendar_event is set, with start_at and end_at params" do
      user_session(@teacher)
      allow(WebConference).to receive(:plugins).and_return(
        [OpenObject.new(id: "big_blue_button", settings: { domain: "bbb.instructure.com", secret_dec: "secret" }, valid_settings?: true, enabled?: true),]
      )

      start_time = Date.today
      end_time = Date.today + 1.day
      @conference = @course.web_conferences.create!(conference_type: "BigBlueButton", user: @teacher)

      params = {
        course_id: @course.id,
        id: @conference,
        web_conference: {
          title: "Something else",
          sync_attendees: true,
          calendar_event: "1",
          start_at: start_time,
          end_at: end_time
        },
      }

      post :update, params:, format: "json"
      created_conference = WebConference.find(@conference.id)
      created_calendar_event = created_conference.calendar_event

      expect(created_calendar_event).to be_truthy
      expect(created_calendar_event.context).to eq @course
      expect(created_calendar_event.start_at).to eq start_time
      expect(created_calendar_event.end_at).to eq end_time
      expect(response).to be_successful
    end
  end

  describe "POST 'join'" do
    it "requires authorization" do
      @conference = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)
      post "join", params: { course_id: @course.id, conference_id: @conference.id }
      assert_unauthorized
    end

    it "lets admins join a conference" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)
      post "join", params: { course_id: @course.id, conference_id: @conference.id }
      expect(response).to be_redirect
      expect(response["Location"]).to match(/wimba\.test/)
    end

    it "lets students join an inactive long running conference" do
      user_session(@student)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", user: @teacher)
      @conference.update_attribute :start_at, 1.month.ago
      @conference.users << @student
      allow_any_instance_of(WimbaConference).to receive(:conference_status).and_return(:closed)
      post "join", params: { course_id: @course.id, conference_id: @conference.id }
      expect(response).to be_redirect
      expect(response["Location"]).to match(/wimba\.test/)
    end

    describe "when student is part of the conference" do
      before :once do
        @conference = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)
        @conference.users << @student
      end

      before do
        user_session(@student)
      end

      it "does not let students join an inactive conference" do
        expect_any_instance_of(WimbaConference).to receive(:active?).and_return(false)
        post "join", params: { course_id: @course.id, conference_id: @conference.id }
        expect(response).to be_redirect
        expect(response["Location"]).not_to match(/wimba\.test/)
        expect(flash[:notice]).to match(/That conference is not currently active/)
      end

      describe "when the conference is active" do
        before do
          Setting.set("enable_page_views", "db")
          expect_any_instance_of(WimbaConference).to receive(:active?).and_return(true)
          post "join", params: { course_id: @course.id, conference_id: @conference.id }
        end

        it "lets students join an active conference" do
          expect(response).to be_redirect
          expect(response["Location"]).to match(/wimba\.test/)
        end

        it "logs an asset access record for the discussion topic" do
          accessed_asset = assigns[:accessed_asset]
          expect(accessed_asset[:code]).to eq @conference.asset_string
          expect(accessed_asset[:category]).to eq "conferences"
          expect(accessed_asset[:level]).to eq "participate"
        end

        it "registers a page view" do
          page_view = assigns[:page_view]
          expect(page_view).not_to be_nil
          expect(page_view.http_method).to eq "post"
          expect(page_view.url).to match %r{^http://test\.host/courses/\d+/conferences/\d+/join}
          expect(page_view.participated).to be_truthy
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "removes participants and the calendar event association" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)
      @conference.users << @student
      @conference.calendar_event = calendar_event_model
      @conference.save!
      delete "destroy", params: { course_id: @course.id, id: @conference.id }
      expect(response).to be_redirect
      expect(WebConference.exists?(@conference.id)).to be(false)
      expect(@event.reload.web_conference_id).to be_nil
    end

    it "removes participants and potentially multiple calendar events association" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)
      @conference.users << @student
      @conference.save!
      ce1 = calendar_event_model
      ce2 = calendar_event_model
      ce1.web_conference_id = @conference.id
      ce2.web_conference_id = @conference.id
      ce1.save!
      ce2.save!
      delete "destroy", params: { course_id: @course.id, id: @conference.id }
      expect(response).to be_redirect
      expect(WebConference.exists?(@conference.id)).to be(false)
      expect(@event.reload.web_conference_id).to be_nil
    end

    it "deletes conference correctly if calendar event was deleted first" do
      user_session(@teacher)
      @conference = @course.web_conferences.create!(conference_type: "Wimba", duration: 60, user: @teacher)
      @conference.users << @student
      @conference.calendar_event = calendar_event_model
      @conference.save!

      conference_event_id = @conference.calendar_event.id
      @conference.calendar_event.destroy!
      expect(CalendarEvent.find(conference_event_id).web_conference).to be_nil

      delete "destroy", params: { course_id: @course.id, id: @conference.id }

      expect(response).to be_redirect
      expect(WebConference.exists?(@conference.id)).to be(false)
      expect(@event.reload.web_conference_id).to be_nil
    end
  end

  context "LTI conferences" do
    before(:once) do
      Account.site_admin.enable_feature! :conference_selection_lti_placement
    end

    let_once(:course) { course_model }

    let_once(:tool) do
      new_valid_tool(course).tap do |t|
        t.name = "course tool"
        t.conference_selection = { message_type: "LtiResourceLinkRequest" }
        t.save!
      end
    end

    let_once(:account_tool) do
      new_valid_tool(course.account).tap do |t|
        t.name = "account_tool"
        t.conference_selection = { message_type: "LtiResourceLinkRequest" }
        t.save!
      end
    end

    context "#index" do
      it "lists include LTI conference types" do
        user_session(@teacher)
        get "index", params: { course_id: @course.id }
        conference_types = assigns[:js_env][:conference_type_details]
        expect(conference_types.pluck(:name)).to include(tool.name)
        expect(conference_types.pluck(:name)).to include(account_tool.name)
      end
    end

    context "#create" do
      it "can create LTI conferences" do
        user_session(@teacher)
        post "create",
             params: {
               course_id: @course.id,
               web_conference: {
                 title: "My Conference",
                 conference_type: "LtiConference",
                 lti_settings: { tool_id: tool.id }
               }
             },
             format: "json"
        expect(response).to be_successful
      end
    end
  end
end
