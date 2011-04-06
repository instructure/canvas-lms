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
  before(:all) do
    WebConference.instance_eval do
      def plugins
        [OpenObject.new(:id => "dim_dim", :settings => {:domain => "dimdim.instructure.com"}, :valid_settings? => true),
         OpenObject.new(:id => "big_blue_button", :settings => {:domain => "bbb.instructure.com", :secret_dec => "secret"}, :valid_settings? => true),
         OpenObject.new(:id => "broken_plugin", :settings => {:foo => :bar}, :valid_settings? => true)]
      end
    end
  end
  after(:all) do
    WebConference.instance_eval do
      def plugins; Canvas::Plugin.all_for_tag(:web_conferencing); end
    end
  end

  context "broken_plugin" do
    it "should return false on valid_config? if no matching config" do
      WebConference.new.valid_config?.should be_false
      conf = WebConference.new
      conf.conference_type = 'bad_type'
      conf.valid_config?.should be_false
    end

    it "should return false on valid_config? if plugin subclass is broken/missing" do
      conf = WebConference.new
      conf.conference_type = "broken_plugin"
      conf.valid_config?.should be_false
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
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.config.should_not be_nil
      conference.admin_join_url(@user).should eql("http://dimdim.instructure.com/dimdim/html/envcheck/connect.action?action=host&email=#{CGI::escape(email)}&confKey=#{conference.conference_key}&attendeePwd=#{conference.attendee_key}&presenterPwd=#{conference.presenter_key}&displayName=#{CGI::escape(@user.name)}&meetingRoomName=#{conference.conference_key}&confName=#{CGI::escape(conference.title)}&presenterAV=av&collabUrl=#{CGI::escape("http://#{HostUrl.context_host(conference.context)}/dimdim_welcome.html")}&returnUrl=#{CGI::escape("http://www.instructure.com")}")
      conference.participant_join_url(@user).should eql("http://dimdim.instructure.com/dimdim/html/envcheck/connect.action?action=join&email=#{CGI::escape(email)}&confKey=#{conference.conference_key}&attendeePwd=#{conference.attendee_key}&displayName=#{CGI::escape(@user.name)}&meetingRoomName=#{conference.conference_key}")
    end
    
    it "should confirm valid config" do
      DimDimConference.new.valid_config?.should be_true
      DimDimConference.new(:conference_type => "DimDim").valid_config?.should be_true
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
      @user.stub!(:email).and_return(email)
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
      BigBlueButtonConference.new.valid_config?.should be_true
      BigBlueButtonConference.new(:conference_type => "BigBlueButton").valid_config?.should be_true
    end
  end
  
  context "starting and ending" do
    it "should not set start and end times by default" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.start_at.should be_nil
      conference.end_at.should be_nil
      conference.started_at.should be_nil
      conference.ended_at.should be_nil
    end
    
    it "should set start and end times when a paricipant is added" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.start_at.should_not be_nil
      conference.end_at.should eql(conference.start_at + conference.duration_in_seconds)
      conference.started_at.should eql(conference.start_at)
      conference.ended_at.should be_nil
    end
    
    it "should not set ended_at if the conference is still active" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.stub!(:conference_status).and_return(:active)
      conference.ended_at.should eql(nil)
      conference.active?.should eql(true)
      conference.ended_at.should eql(nil)
    end
    
    it "should not set ended_at if the conference is no longer active but end_at has not passed" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.stub!(:conference_status).and_return(:closed)
      conference.ended_at.should eql(nil)
      conference.active?(true).should eql(false)
      conference.ended_at.should be_nil
    end
    
    it "should set ended_at if the conference is no longer active and end_at has passed" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.stub!(:conference_status).and_return(:closed)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      conference.ended_at.should eql(nil)
      conference.active?(true).should eql(false)
      conference.ended_at.should_not be_nil
      conference.ended_at.should < Time.now
    end
    
    it "should set ended_at if it's more than 15 minutes past end_at" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.stub!(:conference_status).and_return(:active)
      conference.ended_at.should eql(nil)
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
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.stub!(:conference_status).and_return(:active)
      conference.finished?.should eql(false)
      conference.restartable?.should eql(true)
    end
    
    it "should not be restartable if end_at has passed" do
      user_model
      email = "email@email.com"
      @user.stub!(:email).and_return(email)
      conference = DimDimConference.create!(:title => "my conference", :user => @user)
      conference.add_attendee(@user)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      conference.stub!(:conference_status).and_return(:active)
      conference.finished?.should eql(true)
      conference.restartable?.should eql(false)
    end
  end
end
