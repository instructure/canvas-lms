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
  def course_event
    @event = @course.calendar_events.create(:title => "some assignment")
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_event
      get 'show', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_event
      get 'show', :course_id => @course.id, :id => @event.id, :format => :json
      # response.should be_success
      assigns[:event].should_not be_nil
      assigns[:event].should eql(@event)
    end

    it "should redirect if calendar2 is enabled and the user can't edit" do
      Account.default.update_attribute(:settings, {:enable_scheduler => true})
      course_with_student_logged_in(:active_all => true)
      course_event
      get 'show', :course_id => @course.id, :id => @event.id
      response.should be_redirect
      response.redirected_to.should include "include_contexts=#{@course.asset_string}"
    end

    it "should redirect to the effective calendar if calendar2 is enabled and the user can't edit" do
      Account.default.update_attribute(:settings, {:enable_scheduler => true})
      course_with_student_logged_in(:active_all => true)
      parent_event = @course.calendar_events.build(:title => "something", :child_event_data => {"0" => {:start_at => Time.now, :end_at => 1.hour.from_now, :context_code => @course.default_section.asset_string}})
      parent_event.updating_user = @teacher
      parent_event.save!
      event = parent_event.child_events.first
      get 'show', :course_section_id => @course.default_section.id, :id => event.id
      response.should be_redirect
      response.redirected_to.should include "include_contexts=#{@course.asset_string}" # goes to course calendar
    end
  end
  
  describe "GET 'new'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      get 'new', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should not allow students to create" do
      course_with_student_logged_in(:active_all => true)
      course_event
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    # it "should assign variables" do
      # course_with_teacher_logged_in(:active_all => true)
      # course_event
      # get 'new', :course_id => @course.id
# #      response.should be_success
      # assigns[:event].should_not be_nil
      # assigns[:event].should be_new_record
    # end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_event
      post 'create', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should not allow students to create" do
      course_with_student_logged_in(:active_all => true)
      course_event
      post 'create', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should create a new event" do
      course_with_teacher_logged_in(:active_all => true)
      course_event
      post 'create', :course_id => @course.id, :calendar_event => {:title => "some event"}
      response.should be_redirect
      assigns[:event].should_not be_nil
      assigns[:event].title.should eql("some event")
    end
  end
  
  describe "GET 'edit'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_event
      get 'edit', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
   
    it "should not allow students to update" do
      course_with_student_logged_in(:active_all => true)
      course_event
      get 'edit', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_event
      put 'update', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
    
    it "should not allow students to update" do
      course_with_student_logged_in(:active_all => true)
      course_event
      put 'update', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
    
    it "should update the event" do
      course_with_teacher_logged_in(:active_all => true)
      course_event
      put 'update', :course_id => @course.id, :id => @event.id, :calendar_event => {:title => "new title"}
      response.should be_redirect
      assigns[:event].should_not be_nil
      assigns[:event].should eql(@event)
      assigns[:event].title.should eql("new title")
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_event
      delete 'destroy', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
    
    it "should not allow students to delete" do
      course_with_student_logged_in(:active_all => true)
      course_event
      delete 'destroy', :course_id => @course.id, :id => @event.id
      assert_unauthorized
    end
    
    it "should delete the event" do
      course_with_teacher_logged_in(:active_all => true)
      course_event
      delete 'destroy', :course_id => @course.id, :id => @event.id
      response.should be_redirect
      assigns[:event].should_not be_nil
      assigns[:event].should eql(@event)
      assigns[:event].should_not be_frozen
      assigns[:event].should be_deleted
      @course.reload
      @course.calendar_events.should be_include(@event)
      @course.calendar_events.active.should_not be_include(@event)
    end
  end
end
