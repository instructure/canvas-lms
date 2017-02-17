#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CalendarEventsController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    course_event
  end

  def course_event
    @event = @course.calendar_events.create(:title => "some assignment")
  end

  describe "GET 'show'" do
    it "should require authorization" do
      get 'show', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      get 'show', :course_id => @course.id, :id => @event.id, :format => :json
      # response.should be_success
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event]).to eql(@event)
    end

    it "should render show page" do
      user_session(@student)
      get 'show', :course_id => @course.id, :id => @event.id
      expect(assigns[:event]).not_to be_nil
      # make sure that the show.html.erb template is rendered
      expect(response).to render_template('calendar_events/show')
    end

    it "should redirect for course section events" do
      section = @course.default_section
      section_event = section.calendar_events.create!(title: "Sub event")
      user_session(@student)
      get 'show', course_section_id: section.id, id: section_event.id
      expect(response).to be_redirect
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should not allow students to create" do
      user_session(@student)
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "doesn't create an event" do
      initial_count = @course.calendar_events.count
      user_session(@teacher)
      get 'new', :course_id => @course.id
      expect(@course.reload.calendar_events.count).to eq initial_count
    end

    it "allows creating recurring calendar events on a user's calendar if the user's account allows them to" do
      user_session(@teacher)
      @teacher.account.enable_feature!(:recurring_calendar_events)
      get 'new', user_id: @teacher.id
      expect(@controller.js_env[:RECURRING_CALENDAR_EVENTS_ENABLED]).to be(true)
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :calendar_event => {:title => "some event"}
      assert_unauthorized
    end

    it "should not allow students to create" do
      user_session(@student)
      post 'create', :course_id => @course.id, :calendar_event => {:title => "some event"}
      assert_unauthorized
    end

    it "should create a new event" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :calendar_event => {:title => "some event"}
      expect(response).to be_redirect
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event].title).to eql("some event")
    end
  end

  describe "GET 'edit'" do
    it "should require authorization" do
      get 'edit', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end

    it "should not allow students to update" do
      user_session(@student)
      get 'edit', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      put 'update', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end

    it "should not allow students to update" do
      user_session(@student)
      put 'update', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end

    it "should update the event" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @event.id, :calendar_event => {:title => "new title"}
      expect(response).to be_redirect
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event]).to eql(@event)
      expect(assigns[:event].title).to eql("new title")
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      delete 'destroy', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end

    it "should not allow students to delete" do
      user_session(@student)
      delete 'destroy', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end

    it "should delete the event" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @event.id
      expect(response).to be_redirect
      expect(assigns[:event]).not_to be_nil
      expect(assigns[:event]).to eql(@event)
      expect(assigns[:event]).not_to be_frozen
      expect(assigns[:event]).to be_deleted
      @course.reload
      expect(@course.calendar_events).to be_include(@event)
      expect(@course.calendar_events.active).not_to be_include(@event)
    end
  end
end
