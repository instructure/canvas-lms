#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AdobeConnectConference do
  CONNECT_CONFIG = {
    :domain => 'http://connect.example.com',
    :username => 'user',
    :password => 'password',
    :password_dec => 'password',
    :meeting_container => 'canvas_meetings'
  }

  before(:each) do
    @conference = AdobeConnectConference.new
    @conference.stubs(:config).returns(CONNECT_CONFIG)
  end

  subject { AdobeConnectConference.new }

  context 'with an admin participant' do
    before(:each) do
      @user = User.new(:name => 'Don Draper')
      AdobeConnect::Service.stubs(:user_session).returns('CookieValue')
      @conference.expects(:add_host).with(@user).returns(@user)
    end

    it 'should generate an admin url using unique format if stored' do
      stored_url = 'canvas-mtg-ACCOUNT_ID-ID-CREATED_SECONDS'
      @conference.settings[:meeting_url_id] = stored_url
      expect(@conference.admin_join_url(@user)).to eq "http://connect.example.com/#{stored_url}"
    end

    it 'should generate an admin url using legacy format' do
      expect(@conference.admin_join_url(@user)).to eq "http://connect.example.com/canvas-meeting-#{@conference.id}"
    end
  end
end
