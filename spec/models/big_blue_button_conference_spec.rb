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
  it_should_behave_like 'WebConference'

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

end
