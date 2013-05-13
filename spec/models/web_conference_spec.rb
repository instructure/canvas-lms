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
  before do
    WebConference.stubs(:plugins).returns(
        [web_conference_plugin_mock("dim_dim", {:domain => "dimdim.instructure.com"}),
         web_conference_plugin_mock("big_blue_button", {:domain => "bbb.instructure.com", :secret_dec => "secret"}),
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

  context "dim_dim" do
    it "should correctly retrieve a config hash" do
      conference = DimDimConference.new
      config = conference.config
      config.should_not be_nil
      config[:conference_type].should eql('DimDim')
      config[:class_name].should eql('DimDimConference')
    end
    
    it "should correctly generate join urls" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.config.should_not be_nil
      conference.admin_join_url(@user).should eql("http://dimdim.instructure.com/dimdim/html/envcheck/connect.action?action=host&email=#{CGI::escape(email)}&confKey=#{conference.conference_key}&attendeePwd=#{conference.attendee_key}&presenterPwd=#{conference.presenter_key}&displayName=#{CGI::escape(@user.name)}&meetingRoomName=#{conference.conference_key}&confName=#{CGI::escape(conference.title)}&presenterAV=av&collabUrl=#{CGI::escape("http://#{HostUrl.context_host(conference.context)}/dimdim_welcome.html")}&returnUrl=#{CGI::escape("http://www.instructure.com")}")
      conference.participant_join_url(@user).should eql("http://dimdim.instructure.com/dimdim/html/envcheck/connect.action?action=join&email=#{CGI::escape(email)}&confKey=#{conference.conference_key}&attendeePwd=#{conference.attendee_key}&displayName=#{CGI::escape(@user.name)}&meetingRoomName=#{conference.conference_key}")
    end
    
    it "should confirm valid config" do
      DimDimConference.new.should be_valid_config
      DimDimConference.new(:conference_type => "DimDim").should be_valid_config
    end
  end

  context "big_blue_button" do
    it "should correctly retrieve a config hash" do
      conference = BigBlueButtonConference.new
      config = conference.config
      config.should_not be_nil
      config[:conference_type].should eql('BigBlueButton')
      config[:class_name].should eql('BigBlueButtonConference')
    end

    it "should correctly generate join urls" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = BigBlueButtonConference.create!(:title => "my conference", :user => @user)
      conference.config.should_not be_nil

      # set some vars so it thinks it's been created and doesn't do an api call
      conference.conference_key = 'test'
      conference.settings[:admin_key] = 'admin'
      conference.settings[:user_key] = 'user'
      conference.save

      params = {:fullName => user.name, :meetingID => conference.conference_key, :userID => user.id}
      admin_params = params.merge(:password => 'admin').to_query
      user_params = params.merge(:password => 'user').to_query
      conference.admin_join_url(@user).should eql("http://bbb.instructure.com/bigbluebutton/api/join?#{admin_params}&checksum=" + Digest::SHA1.hexdigest("join#{admin_params}secret"))
      conference.participant_join_url(@user).should eql("http://bbb.instructure.com/bigbluebutton/api/join?#{user_params}&checksum=" + Digest::SHA1.hexdigest("join#{user_params}secret"))
    end

    it "should confirm valid config" do
      BigBlueButtonConference.new.should be_valid_config
      BigBlueButtonConference.new(:conference_type => "BigBlueButton").should be_valid_config
    end

    it "should recreate the conference if it's been empty for too long" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = BigBlueButtonConference.create!(:title => "my conference", :user => @user)
      conference.expects(:send_request).with(:isMeetingRunning, anything).at_least(1).returns({:running => 'false'}, {:running => 'true'}, {:running => 'false'})
      conference.expects(:send_request).with(:create, anything).twice.returns(true)

      conference.craft_url(@user).should match(/\Ahttp:\/\/bbb\.instructure\.com\/bigbluebutton\/api\/join/)
      # second one doesn't trigger another create call
      conference.craft_url(@user).should match(/\Ahttp:\/\/bbb\.instructure\.com\/bigbluebutton\/api\/join/)

      WebConference.where(:id => conference).update_all(:updated_at => 1.day.ago)
      conference.reload

      conference.craft_url(@user).should match(/\Ahttp:\/\/bbb\.instructure\.com\/bigbluebutton\/api\/join/)
    end
  end

  context "user settings" do
    it "should ignore invalid user settings" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :user_settings => {:foo => :bar})
      conference.user_settings.should be_empty
    end

    it "should not expose internal settings to users" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.new(:title => "my conference", :user => @user)
      conference.settings = {:not => :for_user}
      conference.save
      conference.reload
      conference.user_settings.should be_empty
    end
  end

  context "starting and ending" do
    it "should not set start and end times by default" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
      conference.start_at.should be_nil
      conference.end_at.should be_nil
      conference.started_at.should be_nil
      conference.ended_at.should be_nil
    end
    
    it "should set start and end times when a paricipant is added" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
      conference.add_attendee(@user)
      conference.start_at.should_not be_nil
      conference.end_at.should eql(conference.start_at + conference.duration_in_seconds)
      conference.started_at.should eql(conference.start_at)
      conference.ended_at.should be_nil
    end
    
    it "should not set ended_at if the conference is still active" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      conference.ended_at.should be_nil
      conference.should be_active
      conference.ended_at.should be_nil
    end
    
    it "should not set ended_at if the conference is no longer active but end_at has not passed" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:closed)
      conference.ended_at.should be_nil
      conference.active?(true).should eql(false)
      conference.ended_at.should be_nil
    end
    
    it "should set ended_at if the conference is no longer active and end_at has passed" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
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
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
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
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      conference.should_not be_finished
      conference.should be_restartable
    end
    
    it "should not be restartable if end_at has passed" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :duration => 60)
      conference.add_attendee(@user)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      conference.stubs(:conference_status).returns(:active)
      conference.should be_finished
      conference.should_not be_restartable
    end

    it "should not be restartable if it's long running" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.start_at = 30.minutes.ago
      conference.close
      conference.stubs(:conference_status).returns(:active)
      conference.should be_finished
      conference.should_not be_restartable
    end
  end

  context "notifications" do
    before do
      Notification.create!(:name => 'Web Conference Invitation', :category => "TestImmediately")
      course_with_student(:active_all => 1)
      @student.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email").confirm
    end

    it "should send notifications" do
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :context => @course)
      conference.add_attendee(@student)
      conference.save!
      conference.messages_sent['Web Conference Invitation'].should_not be_empty
    end

    it "should not send notifications to inactive users" do
      @course.restrict_enrollments_to_course_dates = true
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :context => @course)
      conference.add_attendee(@student)
      conference.save!
      conference.messages_sent['Web Conference Invitation'].should be_blank
    end
  end
end
