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

describe CalendarsController do
  def course_event(date=nil)
    date = Date.parse(date) if date
    @event = @course.calendar_events.create(:title => "some assignment", :start_at => date, :end_at => date)
  end

  def calendar2_only!
    Account.default.update_attribute :settings, {
      :enable_scheduler => true,
      :calendar2_only => true
    }
  end

  describe "GET 'show'" do
    it "should redirect if no contexts are found" do
      course_with_student(:active_all => true)
      course_event
      get 'show', :course_id => @course.id
      assigns[:contexts].should be_blank
      response.should be_redirect
    end

    it "should redirect if the user should be on the new calendar" do
      Account.default.update_attribute(:settings, {:enable_scheduler => true})
      course_with_student_logged_in(:active_all => true)
      get 'show', :user_id => @user.id
      response.should redirect_to(calendar2_url(anchor: ' '))
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_event
      get 'show', :user_id => @user.id
      response.should be_success
      assigns[:contexts].should_not be_nil
      assigns[:contexts].should_not be_empty
      assigns[:contexts][0].should eql(@user)
      assigns[:contexts][1].should eql(@course)
      assigns[:events].should_not be_nil
      assigns[:undated_events].should_not be_nil
    end

    it "should retrieve multiple contexts for user" do
      course_with_student_logged_in(:active_all => true)
      course_event
      e = @user.calendar_events.create(:title => "my event")
      get 'show', :user_id => @user.id, :include_undated => true
      response.should be_success
      assigns[:contexts].should_not be_nil
      assigns[:contexts].should_not be_empty
      assigns[:contexts].length.should eql(2)
      assigns[:contexts][0].should eql(@user)
      assigns[:contexts][1].should eql(@course)
    end

    it "should retrieve unconcluded course groups for user" do
      course_with_student_logged_in(:active_all => true)
      group_with_user(:group_context => @course, :user => @user, :active_all => true)
      group1 = @group

      course_with_student_logged_in(:active_all => true, :user => @user)
      group_with_user(:group_context => @course, :user => @user, :active_all => true)
      group2 = @group
      @course.update_attribute(:conclude_at, Time.now - 1.week)

      course_with_student_logged_in(:active_all => true, :user => @user)
      group_with_user(:group_context => @course, :user => @user, :active_all => true)
      group3 = @group
      @course.update_attribute('workflow_state', 'completed')

      get 'show', :user_id => @user.id, :include_undated => true
      response.should be_success

      assigns[:contexts].should include(group1)
      assigns[:contexts].should_not include(group2)
      assigns[:contexts].should_not include(group3)
    end

    it "should retrieve events for a given month and year" do
      course_with_student_logged_in(:active_all => true)
      e1 = course_event("Jan 1 2008")
      get 'show', :month => "01", :year => "2008" #, :course_id => @course.id, :month => "01", :year => "2008"
      response.should be_success
    end

    it "should redirect if the user should be on the new calendar" do
      calendar2_only!
      course_with_student_logged_in(:active_all => true)
      Account.default.update_attribute :settings, {
        :enable_scheduler => true,
        :calendar2_only => true
      }
      @user.preferences[:use_calendar1] = true
      @user.save!
      get 'show'

      response.should redirect_to(calendar2_url(anchor: ' '))
    end
  end

  describe "GET 'show2'" do
    it "should redirect if the user should be on the old calendar" do
      course_with_student_logged_in(:active_all => true)
      get 'show2', :user_id => @user.id
      response.should redirect_to(calendar_url(anchor: ' '))
    end

    it "should assign variables" do
      Account.default.update_attribute(:settings, {:enable_scheduler => true})
      course_with_student_logged_in(:active_all => true)
      course_event
      get 'show2', :user_id => @user.id
      response.should be_success
      assigns[:contexts].should_not be_nil
      assigns[:contexts].should_not be_empty
      assigns[:contexts][0].should eql(@user)
      assigns[:contexts][1].should eql(@course)
    end

    specs_require_sharding

    it "should set permissions using contexts from the correct shard" do
      # non-shard-aware code could use a shard2 id on shard1. this could grab the wrong course,
      # or no course at all. this sort of aliasing used to break a permission check in show2
      calendar2_only!
      user(:active_all => true)
      user_session(@user)
      invalid_shard1_course_id = (Course.maximum(:id) || 0) + 1
      @shard2.activate do
        account = Account.create!
        @course = account.courses.build
        @course.id = invalid_shard1_course_id
        @course.save!
        @course.offer!
        student_in_course(:active_all => true, :user => @user)
      end
      get 'show2', :user_id => @user.id
      response.should be_success
    end
  end

  describe "POST 'switch_calendar'" do
    it "should switch to the old calendar" do
      Account.default.update_attribute(:settings, {:enable_scheduler => true})
      course_with_student_logged_in(:active_all => true)
      @user.preferences[:use_calendar1].should be_nil

      post 'switch_calendar', {:preferred_calendar => '1'}
      response.should redirect_to(calendar_url(anchor: ' '))
      @user.reload.preferences[:use_calendar1].should be_true
    end

    it "should not switch to the old calendar if not allowed" do
      calendar2_only!
      course_with_student_logged_in(:active_all => true)
      @user.preferences[:use_calendar1].should be_nil
      post 'switch_calendar', {:preferred_calendar => '1'}
      response.should redirect_to(calendar2_url(anchor: ' '))

      # not messing with their preference in case they prefer cal1 in a
      # different account
      @user.reload.preferences[:use_calendar1].should be_true
    end

    it "should not switch to the new calendar if not allowed" do
      course_with_student_logged_in(:active_all => true)
      @user.preferences[:use_calendar1].should be_nil

      post 'switch_calendar', {:preferred_calendar => '2'}
      response.should redirect_to(calendar_url(anchor: ' '))
      @user.reload.preferences[:use_calendar1].should be_nil
    end

    it "should switch to the new calendar if allowed" do
      Account.default.update_attribute(:settings, {:enable_scheduler => true})
      course_with_student_logged_in(:active_all => true)
      @user.update_attribute(:preferences, {:use_calendar1 => true})

      post 'switch_calendar', {:preferred_calendar => '2'}
      response.should redirect_to(calendar2_url(anchor: ' '))
      @user.reload.preferences[:use_calendar1].should be_nil
    end
  end
end

describe CalendarEventsApiController do
  def course_event(date=Time.now)
    @event = @course.calendar_events.create(:title => "some assignment", :start_at => date, :end_at => date)
  end

  describe "GET 'public_feed'" do
    before(:each) do
      course_with_student(:active_all => true)
      course_event
      @course.is_public = true
      @course.save!
      @course.assignments.create!(:title => "some assignment")
    end

    it "should assign variables" do
      get 'public_feed', :feed_code => "course_#{@course.uuid}", :format => 'ics'
      response.should be_success
      assigns[:events].should be_present
      assigns[:events][0].should eql(@event)
    end

    it "should use the relevant event for that section" do
      s2 = @course.course_sections.create!(:name => 's2')
      c1 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => @course.default_section, :start_at => 2.hours.ago, :end_at => 1.hour.ago)
      c2 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => s2, :start_at => 3.hours.ago, :end_at => 2.hours.ago)
      get 'public_feed', :feed_code => "user_#{@user.uuid}", :format => 'ics'
      response.should be_success
      assigns[:events].should be_present
      assigns[:events].should == [c1]
    end

    it "should use the relevant event for that section, in the course feed" do
      pending "requires changing the format of the course feed url to include user information"
      s2 = @course.course_sections.create!(:name => 's2')
      c1 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => @course.default_section, :start_at => 2.hours.ago, :end_at => 1.hour.ago)
      c2 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => s2, :start_at => 3.hours.ago, :end_at => 2.hours.ago)
      get 'public_feed', :feed_code => "course_#{@course.uuid}", :format => 'ics'
      response.should be_success
      assigns[:events].should be_present
      assigns[:events].should == [c1]
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code + 'x'
      response.should render_template('shared/unauthorized_feed')
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.links.first.rel.should match(/self/)
      feed.links.first.href.should match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should_not be_empty
      feed.entries.all?{|e| e.authors.present?}.should be_true
    end
  end
end
