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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FacebookController do
  before :all do
    Canvas::Plugin.register(:facebook, nil, :settings => {:app_id => 1, :secret => 'sekrit'})
  end

  describe "get_facebook_user" do
    before do
      # avoid making actual requests
      Facebook::Connection.stubs(:send_graph_request => '')
    end

    def signed_request(data={})
      str = [data.to_json].pack('m').chomp.tr('+/', '-_')
      sig = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), Facebook::Connection.config['secret'], str)).strip.tr('+/', '-_').sub(/=+$/, '')
      signed_request = [sig, str].join('.')
    end

    it "should find a user with a user_id" do
      @user = user_model
      UserService.create!(:user => @user, :service => 'facebook', :service_user_id => 'some_facebook_user_id')
      get 'index', :signed_request => signed_request(:user_id => 'some_facebook_user_id')
      expect(assigns[:user]).to eq @user
    end

    it "should not find a user without a user_id" do
      @user = user_model
      UserService.create!(:user => @user, :service => 'facebook', :service_user_id => 'garbage')
      get 'index', :signed_request => signed_request
      expect(assigns[:user]).to be_nil
    end
  end

  describe "#notification_preferences" do
    it "should reset unmentioned preferences to default frequency" do
      notification_model(category: 'TestWeekly')
      user = User.create!
      cc = user.communication_channels.create!(path: 'abc', path_type: 'facebook')
      p = cc.notification_policies.create!(notification: @notification, frequency: 'daily')
      session[:facebook_canvas_user_id] = user.id
      post 'notification_preferences', types: { }
      expect(response).to be_redirect
      expect(p.reload.frequency).to eq 'weekly'
    end
  end
end
