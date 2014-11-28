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

  before(:once) { course_with_student(active_all: true) }
  before(:each) { user_session(@student) }

  describe "GET 'show2'" do
    it "should not redirect to the old calendar even with default settings" do
      get 'show2', :user_id => @user.id
      expect(response).not_to redirect_to(calendar_url(anchor: ' '))
    end

    it "should assign variables" do
      course_event
      get 'show2', :user_id => @user.id
      expect(response).to be_success
      expect(assigns[:contexts]).not_to be_nil
      expect(assigns[:contexts]).not_to be_empty
      expect(assigns[:contexts][0]).to eql(@user)
      expect(assigns[:contexts][1]).to eql(@course)
    end

    specs_require_sharding

    it "should set permissions using contexts from the correct shard" do
      # non-shard-aware code could use a shard2 id on shard1. this could grab the wrong course,
      # or no course at all. this sort of aliasing used to break a permission check in show2
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
      expect(response).to be_success
    end
  end

  describe "POST 'switch_calendar'" do
    it "should not switch to the old calendar anymore" do
      expect(@user.preferences[:use_calendar1]).to be_nil

      post 'switch_calendar', {:preferred_calendar => '1'}
      expect(response).to redirect_to(calendar2_url(anchor: ' '))
      expect(@user.reload.preferences[:use_calendar1]).to be_truthy
    end

    it "should not switch to the old calendar if not allowed" do
      expect(@user.preferences[:use_calendar1]).to be_nil
      post 'switch_calendar', {:preferred_calendar => '1'}
      expect(response).to redirect_to(calendar2_url(anchor: ' '))

      # not messing with their preference in case they prefer cal1 in a
      # different account
      expect(@user.reload.preferences[:use_calendar1]).to be_truthy
    end

    it "should redirect to new calendar regardless of old preference settings" do
      expect(@user.preferences[:use_calendar1]).to be_nil

      post 'switch_calendar', {:preferred_calendar => '2'}
      expect(response).to redirect_to(calendar2_url(anchor: ' '))
      expect(@user.reload.preferences[:use_calendar1]).to be_nil
    end

    it "should switch to the new calendar if allowed" do
      @user.update_attribute(:preferences, {:use_calendar1 => true})

      post 'switch_calendar', {:preferred_calendar => '2'}
      expect(response).to redirect_to(calendar2_url(anchor: ' '))
      expect(@user.reload.preferences[:use_calendar1]).to be_nil
    end
  end
end

describe CalendarEventsApiController do
  def course_event(date=Time.now)
    @event = @course.calendar_events.create(:title => "some assignment", :start_at => date, :end_at => date)
  end

  describe "GET 'public_feed'" do
    before(:once) do
      course_with_student(:active_all => true)
      course_event
      @course.is_public = true
      @course.save!
      @course.assignments.create!(:title => "some assignment")
    end

    it "should assign variables" do
      get 'public_feed', :feed_code => "course_#{@course.uuid}", :format => 'ics'
      expect(response).to be_success
      expect(assigns[:events]).to be_present
      expect(assigns[:events][0]).to eql(@event)
    end

    it "should use the relevant event for that section" do
      s2 = @course.course_sections.create!(:name => 's2')
      c1 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => @course.default_section, :start_at => 2.hours.ago, :end_at => 1.hour.ago)
      c2 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => s2, :start_at => 3.hours.ago, :end_at => 2.hours.ago)
      get 'public_feed', :feed_code => "user_#{@user.uuid}", :format => 'ics'
      expect(response).to be_success
      expect(assigns[:events]).to be_present
      expect(assigns[:events]).to eq [c1]
    end

    it "should use the relevant event for that section, in the course feed" do
      skip "requires changing the format of the course feed url to include user information"
      s2 = @course.course_sections.create!(:name => 's2')
      c1 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => @course.default_section, :start_at => 2.hours.ago, :end_at => 1.hour.ago)
      c2 = factory_with_protected_attributes(@event.child_events, :description => @event.description, :title => @event.title, :context => s2, :start_at => 3.hours.ago, :end_at => 2.hours.ago)
      get 'public_feed', :feed_code => "course_#{@course.uuid}", :format => 'ics'
      expect(response).to be_success
      expect(assigns[:events]).to be_present
      expect(assigns[:events]).to eq [c1]
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code + 'x'
      expect(response).to render_template('shared/unauthorized_feed')
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all?{|e| e.authors.present?}).to be_truthy
    end
  end
end
