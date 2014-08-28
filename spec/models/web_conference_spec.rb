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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe WebConference do
  before(:record) { stub_plugins }
  before(:each)   { stub_plugins }

  def stub_plugins
    WebConference.stubs(:plugins).returns(
        [web_conference_plugin_mock("big_blue_button", {:domain => "bbb.instructure.com", :secret_dec => "secret"}),
         web_conference_plugin_mock("wimba", {:domain => "wimba.test"}),
         web_conference_plugin_mock("broken_plugin", {:foor => :bar})]
    )
  end

  context "broken_plugin" do
    it "should return false on valid_config? if no matching config" do
      WebConference.new.should_not be_valid_config
      conf = WebConference.new
      conf.conference_type = 'bad_type'
      conf.should_not be_valid_config
    end

    it "should return false on valid_config? if plugin subclass is broken/missing" do
      conf = WebConference.new
      conf.conference_type = "broken_plugin"
      conf.should_not be_valid_config
    end
  end

  context "user settings" do
    before :once do
      user_model
    end

    it "should ignore invalid user settings" do
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = WimbaConference.create!(:title => "my conference", :user => @user, :user_settings => {:foo => :bar}, :context => course)
      conference.user_settings.should be_empty
    end

    it "should not expose internal settings to users" do
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = BigBlueButtonConference.new(:title => "my conference", :user => @user, :context => course)
      conference.settings = {:record => true, :not => :for_user}
      conference.save
      conference.reload
      conference.user_settings.should eql({:record => true})
    end

  end

  context "starting and ending" do
    before :once do
      user_model
    end

    let_once(:conference) do
      WimbaConference.create!(:title => "my conference", :user => @user, :duration => 60, :context => course)
    end

    before :each do
      email = "email@email.com"
      @user.stubs(:email).returns(email)
    end

    it "should not set start and end times by default" do
      conference.start_at.should be_nil
      conference.end_at.should be_nil
      conference.started_at.should be_nil
      conference.ended_at.should be_nil
    end
    
    it "should set start and end times when a paricipant is added" do
      conference.add_attendee(@user)
      conference.start_at.should_not be_nil
      conference.end_at.should eql(conference.start_at + conference.duration_in_seconds)
      conference.started_at.should eql(conference.start_at)
      conference.ended_at.should be_nil
    end
    
    it "should not set ended_at if the conference is still active" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      conference.ended_at.should be_nil
      conference.should be_active
      conference.ended_at.should be_nil
    end
    
    it "should not set ended_at if the conference is no longer active but end_at has not passed" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:closed)
      conference.ended_at.should be_nil
      conference.active?(true).should eql(false)
      conference.ended_at.should be_nil
    end
    
    it "should set ended_at if the conference is no longer active and end_at has passed" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:closed)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      conference.ended_at.should be_nil
      conference.active?(true).should eql(false)
      conference.ended_at.should_not be_nil
      conference.ended_at.should < Time.now
    end
    
    it "should set ended_at if it's more than 15 minutes past end_at" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      conference.ended_at.should be_nil
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      conference.active?(true).should eql(false)
      conference.conference_status.should eql(:active)
      conference.ended_at.should_not be_nil
      conference.ended_at.should < Time.now
    end
    
    it "should be restartable if end_at has not passed" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      conference.should_not be_finished
      conference.should be_restartable
    end
    
    it "should not be restartable if end_at has passed" do
      conference.add_attendee(@user)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      conference.stubs(:conference_status).returns(:active)
      conference.should be_finished
      conference.should_not be_restartable
    end

    it "should not be restartable if it's long running" do
      conference = WimbaConference.create!(:title => "my conference", :user => @user, :context => course)
      conference.add_attendee(@user)
      conference.start_at = 30.minutes.ago
      conference.close
      conference.stubs(:conference_status).returns(:active)
      conference.should be_finished
      conference.should_not be_restartable
    end
  end

  context "notifications" do
    before :once do
      Notification.create!(:name => 'Web Conference Invitation', :category => "TestImmediately")
      course_with_student(:active_all => 1)
      @student.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email").confirm
    end

    it "should send notifications" do
      conference = WimbaConference.create!(:title => "my conference", :user => @user, :context => @course)
      conference.add_attendee(@student)
      conference.save!
      conference.messages_sent['Web Conference Invitation'].should_not be_empty
    end

    it "should not send notifications to inactive users" do
      @course.restrict_enrollments_to_course_dates = true
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!
      conference = WimbaConference.create!(:title => "my conference", :user => @user, :context => @course)
      conference.add_attendee(@student)
      conference.save!
      conference.messages_sent['Web Conference Invitation'].should be_blank
    end
  end

  context "scheduled conferences" do
    before :once do
      course_with_student(:active_all => 1)
      @conference = WimbaConference.create!(:title => "my conference", :user => @user, :duration => 60, :context => course)
    end

    it "has a start date" do
      @conference.start_at = Time.now
      @conference.scheduled?.should be_false
    end

    it "has a schduled date in the past" do
      @conference.stubs(:scheduled_date).returns(Time.now - 10.days)
      @conference.scheduled?.should be_false
    end

    it "has a schduled date in the future" do
      @conference.stubs(:scheduled_date).returns(Time.now + 10.days)
      @conference.scheduled?.should be_true
    end

  end

end
