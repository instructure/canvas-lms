#
# Copyright (C) 2013 Instructure, Inc.
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
require_relative('web_conference_spec_helper')

describe BigBlueButtonConference do
  include_examples 'WebConference'

  context "big_blue_button" do
    before do
      WebConference.stubs(:plugins).returns([
        web_conference_plugin_mock("big_blue_button", {
          :domain => "bbb.instructure.com", 
          :secret_dec => "secret",
        })
      ])
    end

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
      conference = BigBlueButtonConference.create!(:title => "my conference", :user => @user, :context => Account.default)
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

    it "should recreate the conference" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = BigBlueButtonConference.create!(:title => "my conference", :user => @user, :context => Account.default)
      conference.expects(:send_request).with(:create, anything).returns(true)

      conference.craft_url(@user).should match(/\Ahttp:\/\/bbb\.instructure\.com\/bigbluebutton\/api\/join/)

      # load a new instance to clear out @conference_active
      conference = WebConference.find(conference.id)
      conference.expects(:send_request).with(:create, anything).returns(true)
      conference.craft_url(@user).should match(/\Ahttp:\/\/bbb\.instructure\.com\/bigbluebutton\/api\/join/)
    end

    it "should not recreate the conference if it is active" do
      user_model
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = BigBlueButtonConference.create!(:title => "my conference", :user => @user, :context => Account.default)
      conference.expects(:send_request).once.with(:create, anything).returns(true)
      conference.initiate_conference
      conference.active?.should be_true
      conference.craft_url(@user).should match(/\Ahttp:\/\/bbb\.instructure\.com\/bigbluebutton\/api\/join/)
    end
  end

  describe 'plugin setting recording_enabled is enabled' do
    before do
      WebConference.stubs(:plugins).returns([
        web_conference_plugin_mock("big_blue_button", {
          :domain => "bbb.instructure.com",
          :secret_dec => "secret",
          :recording_enabled => true,
        })
      ])
    end

    it "should have visible record user_setting" do
      BigBlueButtonConference.user_setting_fields[:record][:visible].call.should be_true
    end

    it "should send record flag if record user_setting is set" do
      bbb = BigBlueButtonConference.new
      bbb.user_settings = { :record => true }
      bbb.user = user
      bbb.context = Account.default
      bbb.save!
      bbb.expects(:send_request).with do |verb, options|
        verb.should eql :create
        options[:record].should eql "true"
      end
      bbb.initiate_conference
    end

    it "should not send record flag if record user setting is unset" do
      bbb = BigBlueButtonConference.new
      bbb.user_settings = { :record => false }
      bbb.user = user
      bbb.context = Account.default
      bbb.save!
      bbb.expects(:send_request).with do |verb, options|
        verb.should eql :create
        options[:record].should eql "false"
      end
      bbb.initiate_conference
    end

    it "should properly serialize a response with no recordings" do
      bbb = BigBlueButtonConference.new
      bbb.stubs(:conference_key).returns('12345')
      bbb.user_settings = { record: true }
      bbb.user = user
      bbb.context = Account.default
      bbb.save!
      response = {returncode: 'SUCCESS', recordings: "\n  ",
                  messageKey: 'noRecordings', message: 'There are not
                  recordings for the meetings'}
      bbb.stubs(:send_request).returns(response)
      bbb.recordings.should == []
    end

    it "should look for recordings only if record user setting is set" do
      bbb = BigBlueButtonConference.new
      bbb.user_settings = { :record => false }
      bbb.user = user
      bbb.context = Account.default

      # set some vars so it thinks it's been created and doesn't do an api call
      bbb.conference_key = 'test'
      bbb.settings[:admin_key] = 'admin'
      bbb.settings[:user_key] = 'user'
      bbb.save

      bbb.expects(:send_request).never
      bbb.recordings

      bbb.user_settings = { :record => true }
      bbb.save

      bbb.expects(:send_request)
      bbb.recordings
    end
  end

  describe 'plugin setting recording disabled' do
    before do
      WebConference.stubs(:plugins).returns([
        web_conference_plugin_mock("big_blue_button", {
          :domain => "bbb.instructure.com",
          :secret_dec => "secret",
          :recording_enabled => false,
        })
      ])
    end

    it "should have invisible record user_setting" do
      BigBlueButtonConference.user_setting_fields[:record][:visible].call.should be_false
    end

    it "should not send record flag even if record user_setting is set" do
      bbb = BigBlueButtonConference.new
      bbb.user_settings = { :record => true }
      bbb.user = user
      bbb.context = Account.default
      bbb.save!
      bbb.expects(:send_request).with do |verb, options|
        verb.should eql :create
        options[:record].should eql "false"
      end
      bbb.initiate_conference
      bbb.user_settings[:record].should be_false
    end
  end

end
