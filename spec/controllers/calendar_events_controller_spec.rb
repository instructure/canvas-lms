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

describe CalendarEventsController do
  def stub_conference_plugins
    allow(WebConference).to receive(:plugins).and_return(
      [
        web_conference_plugin_mock(
          "big_blue_button",
          { domain: "bbb.instructure.com", secret_dec: "secret" }
        )
      ]
    )
  end

  let_once(:teacher_enrollment) { course_with_teacher(active_all: true) }
  let_once(:course) { teacher_enrollment.course }
  let_once(:student_enrollment) { student_in_course(course:) }
  let_once(:course_event) { course.calendar_events.create(title: "some assignment") }
  let_once(:other_teacher_enrollment) { course_with_teacher(active_all: true) }

  before do
    @course = course
    @teacher = teacher_enrollment.user
    @student = student_enrollment.user
    @event = course_event
    stub_conference_plugins
  end

  let(:conference_params) do
    { conference_type: "BigBlueButton", title: "a conference", user: teacher_enrollment.user }
  end
  let(:other_teacher_conference) do
    other_teacher_enrollment.course.web_conferences.create!(
      **conference_params,
      user: other_teacher_enrollment.user
    )
  end

  shared_examples "accepts web_conference" do
    it "accepts a new conference" do
      user_session(@teacher)
      make_request.call(conference_params)
      expect(response.status).to be < 400
      expect(get_event.call.web_conference).not_to be_nil
    end

    it "does not error on bad conference params" do
      user_session(@teacher)
      make_request.call(" s")
      expect(response.status).to be < 400
    end

    it "accepts an existing conference" do
      user_session(@teacher)
      conference = @course.web_conferences.create!(conference_params)
      make_request.call(id: conference.id, **conference_params)
      expect(response.status).to be < 400
      expect(get_event.call.web_conference_id).to eq conference.id
    end

    it "does not accept an existing conference the user doesn't have permission for" do
      user_session(@teacher)
      make_request.call(id: other_teacher_conference.id)
      assert_unauthorized
    end
  end

  describe "GET 'show'" do
    it "requires authorization" do
      get "show", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@student)
      get "show", params: { course_id: @course.id, id: @event.id }, format: :json

      # response.should be_successful
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event]).to eql(@event)
    end

    it "renders show page" do
      user_session(@student)
      get "show", params: { course_id: @course.id, id: @event.id }
      expect(assigns[:event]).not_to be_nil

      # make sure that the show.html.erb template is rendered
      expect(response).to render_template("calendar_events/show")
    end

    it "redirects for course section events" do
      section = @course.default_section
      section_event = section.calendar_events.create!(title: "Sub event")
      user_session(@student)
      get "show", params: { course_section_id: section.id, id: section_event.id }
      expect(response).to be_redirect
    end
  end

  describe "GET 'new'" do
    it "requires authorization" do
      get "new", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "does not allow students to create" do
      user_session(@student)
      get "new", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "doesn't create an event" do
      initial_count = @course.calendar_events.count
      user_session(@teacher)
      get "new", params: { course_id: @course.id }
      expect(@course.reload.calendar_events.count).to eq initial_count
    end

    context "with web conferences" do
      it "includes conference environment" do
        user_session(@teacher)
        get "new", params: { course_id: @course.id }
        expect(@controller.js_env.dig(:conferences, :conference_types).length).to eq 1
      end

      include_examples "accepts web_conference" do
        let(:make_request) do
          ->(params) { get "new", params: { course_id: @course.id, web_conference: params } }
        end
        let(:get_event) { -> { @controller.instance_variable_get(:@event) } }
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { course_id: @course.id, calendar_event: { title: "some event" } }
      assert_unauthorized
    end

    it "does not allow students to create" do
      user_session(@student)
      post "create", params: { course_id: @course.id, calendar_event: { title: "some event" } }
      assert_unauthorized
    end

    it "creates a new event" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, calendar_event: { title: "some event" } }
      expect(response).to be_redirect
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event].title).to eql("some event")
    end

    include_examples "accepts web_conference" do
      let(:make_request) do
        lambda do |params|
          post "create",
               params: {
                 course_id: @course.id,
                 calendar_event: {
                   title: "some event",
                   web_conference: params
                 }
               }
        end
      end
      let(:get_event) { -> { assigns[:event] } }
    end
  end

  describe "GET 'edit'" do
    it "requires authorization" do
      get "edit", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "does not allow students to update" do
      user_session(@student)
      get "edit", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "allows editing of event assigned to section" do
      course_with_teacher(active_all: true)
      section = add_section("Section 01", course: @course)
      section_event = section.calendar_events.create(title: "some assignment")
      user_session(@teacher)
      get "edit", params: { course_id: @course.id, id: section_event.id }
      assert_status(200)
    end
  end

  describe "PUT 'update'" do
    it "requires authorization" do
      put "update", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "does not allow students to update" do
      user_session(@student)
      put "update", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "updates the event" do
      user_session(@teacher)
      put "update",
          params: {
            course_id: @course.id,
            id: @event.id,
            calendar_event: {
              title: "new title"
            }
          }
      expect(response).to be_redirect
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event]).to eql(@event)
      expect(assigns[:event].title).to eql("new title")
    end

    it "allows updating of event assigned to section" do
      course_with_teacher(active_all: true)
      section = add_section("Section 01", course: @course)
      section_event = section.calendar_events.create(title: "some assignment")
      user_session(@teacher)
      put "update",
          params: {
            course_id: @course.id,
            id: section_event.id,
            calendar_event: {
              title: "new title"
            }
          }
      assert_status(302)
    end

    include_examples "accepts web_conference" do
      let(:make_request) do
        lambda do |params|
          put "update",
              params: {
                course_id: @course.id,
                id: @event.id,
                calendar_event: {
                  web_conference: params
                }
              }
        end
      end
      let(:get_event) { -> { assigns[:event] } }
    end
  end

  describe "DELETE 'destroy'" do
    it "requires authorization" do
      delete "destroy", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "does not allow students to delete" do
      user_session(@student)
      delete "destroy", params: { course_id: @course.id, id: @event.id }
      assert_unauthorized
    end

    it "deletes the event" do
      user_session(@teacher)
      delete "destroy", params: { course_id: @course.id, id: @event.id }
      expect(response).to be_redirect
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event]).to eql(@event)
      expect(assigns[:event]).not_to be_frozen
      expect(assigns[:event]).to be_deleted
      @course.reload
      expect(@course.calendar_events).to include(@event)
      expect(@course.calendar_events.active).not_to include(@event)
    end
  end
end
