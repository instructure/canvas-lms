#
# Copyright (C) 2011 - present Instructure, Inc.
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

%w{ Twitter }.each do |integration|
describe integration do
  before do
    course_with_student_logged_in(:active_all => true)
  end

  def oauth_start(integration)
    expect_any_instance_of(UsersController).to receive(:feature_and_service_enabled?).with(integration.underscore).and_return(true)
    if integration == "Twitter"
      expect(Twitter::Connection).to receive(:config).at_least(:once).and_return({})
    else
      expect(integration.constantize).to receive(:config).at_least(:once).and_return({})
    end

    # mock up the response from the 3rd party service, so we don't actually contact it
    expect_any_instance_of(OAuth::Consumer).to receive(:token_request).and_return({:oauth_token => "test_token", :oauth_token_secret => "test_secret", :authorize_url => "http://oauth.example.com/start"})
    expect_any_instance_of(OAuth::RequestToken).to receive(:authorize_url).and_return("http://oauth.example.com/start")
    get "/oauth?service=#{integration.underscore}"
  end

  it "should error if the service isn't enabled" do
    expect_any_instance_of(UsersController).to receive(:feature_and_service_enabled?).with(integration.underscore).and_return(false)
    get "/oauth?service=#{integration.underscore}"
    expect(response).to redirect_to(user_profile_url(@user))
    expect(flash[:error]).to be_present
  end

  it "should redirect to the service for auth" do
    oauth_start(integration)
    expect(response).to redirect_to("http://oauth.example.com/start")

    oreq = OauthRequest.last
    expect(oreq).to be_present
    expect(oreq.service).to eq integration.underscore
    expect(oreq.token).to eq "test_token"
    expect(oreq.secret).to eq "test_secret"
    expect(oreq.user).to eq @user
    expect(oreq.return_url).to eq user_profile_url(@user)
  end

  describe "oauth_success" do
    before do
      OauthRequest.create!({
        :service => integration.underscore,
        :token => "test_token",
        :secret => "test_secret",
        :return_url => user_profile_url(@user),
        :user => @user,
        :original_host_with_port => "www.example.com",
      })
    end

    it "should fail without a valid token" do
      get "/oauth_success?service=#{integration.underscore}&oauth_token=wrong&oauth_verifier=test_verifier"
      expect(response).to redirect_to(user_profile_url(@user))
      expect(flash[:error]).to be_present
    end

    it "should fail with the wrong user" do
      OauthRequest.last.update_attribute(:user, User.create!)
      get "/oauth_success?service=#{integration.underscore}&oauth_token=test_token&oauth_verifier=test_verifier"
      expect(response).to redirect_to(user_profile_url(@user))
      expect(flash[:error]).to be_present
    end

    it "should redirect to the original host if a different host is returned to" do
      get "http://otherschool.example.com/oauth_success?service=#{integration.underscore}&oauth_token=test_token&oauth_verifier=test_verifier"
      expect(response).to redirect_to("http://www.example.com/oauth_success?oauth_token=test_token&oauth_verifier=test_verifier&service=#{integration.underscore}")
    end

    it "should create the UserService on successful auth" do
      oauth_start(integration)

      if integration == "Twitter"
        expect(Twitter::Connection).to receive(:from_request_token).and_return(double("TwitterConnection",
          access_token: double("AccessToken", token: 'test_token', secret: 'test_secret'),
          service_user_id: "test_user_id",
          service_user_name: "test_user_name"
        ))
      end

      get "/oauth_success?oauth_token=test_token&oauth_verifier=test_verifier&service=#{integration.underscore}"
      expect(response).to redirect_to(user_profile_url(@user))
      expect(flash[:error]).to be_blank
      expect(flash[:notice]).to be_present
      us = UserService.where(service: integration.underscore, user_id: @user).first
      expect(us).to be_present
      expect(us.service_user_id).to eq "test_user_id"
      expect(us.service_user_name).to eq "test_user_name"
      expect(us.token).to eq "test_token"
      expect(us.secret).to eq "test_secret"
    end

    it "should fail creating the UserService if getting the initial user info fails" do
      oauth_start(integration)

      # pretend that somehow we think we got a valid auth token, but we actually didn't
      if integration == "Twitter"
        expect(Twitter::Connection).to receive(:from_request_token).
          and_raise(RuntimeError, "Third-party service totally like, failed")
      end

      get "/oauth_success?oauth_token=test_token&oauth_verifier=test_verifier&service=#{integration.underscore}"
      expect(response).to redirect_to(user_profile_url(@user))
      expect(flash[:error]).to be_present
      expect(flash[:notice]).to be_blank
      us = UserService.where(service: integration.underscore, user_id: @user).first
      expect(us).not_to be_present
    end
  end
end
end
