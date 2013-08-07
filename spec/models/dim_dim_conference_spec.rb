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

describe DimDimConference do
  it_should_behave_like 'WebConference'

  context "dim_dim" do
    before do
      WebConference.stubs(:plugins).returns([
        web_conference_plugin_mock("dim_dim", {
          :domain => "dimdim.instructure.com",
        })
      ])
    end

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
      conference = DimDimConference.create!(:title => "my conference", :user => @user, :context => course)
      conference.config.should_not be_nil
      conference.admin_join_url(@user).should eql("http://dimdim.instructure.com/dimdim/html/envcheck/connect.action?action=host&email=#{CGI::escape(email)}&confKey=#{conference.conference_key}&attendeePwd=#{conference.attendee_key}&presenterPwd=#{conference.presenter_key}&displayName=#{CGI::escape(@user.name)}&meetingRoomName=#{conference.conference_key}&confName=#{CGI::escape(conference.title)}&presenterAV=av&collabUrl=#{CGI::escape("http://#{HostUrl.context_host(conference.context)}/dimdim_welcome.html")}&returnUrl=#{CGI::escape("http://www.instructure.com")}")
      conference.participant_join_url(@user).should eql("http://dimdim.instructure.com/dimdim/html/envcheck/connect.action?action=join&email=#{CGI::escape(email)}&confKey=#{conference.conference_key}&attendeePwd=#{conference.attendee_key}&displayName=#{CGI::escape(@user.name)}&meetingRoomName=#{conference.conference_key}")
    end
    
    it "should confirm valid config" do
      DimDimConference.new.should be_valid_config
      DimDimConference.new(:conference_type => "DimDim").should be_valid_config
    end
  end

end
