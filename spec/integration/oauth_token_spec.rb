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

%w{ Twitter GoogleDocs LinkedIn }.each do |integration|
describe integration do
  before do
    course_with_student_logged_in(:active_all => true)
  end

  def oauth_start(integration)
    UsersController.any_instance.expects(:feature_and_service_enabled?).with(integration.underscore).returns(true)
    integration.constantize.expects(:config).at_least_once.returns({})
    # mock up the response from the 3rd party service, so we don't actually contact it
    OAuth::Consumer.any_instance.expects(:token_request).returns({:oauth_token => "test_token", :oauth_token_secret => "test_secret", :authorize_url => "http://oauth.example.com/start"})
    OAuth::RequestToken.any_instance.expects(:authorize_url).returns("http://oauth.example.com/start")
    get "/oauth?service=#{integration.underscore}"
  end

  it "should error if the service isn't enabled" do
    UsersController.any_instance.expects(:feature_and_service_enabled?).with(integration.underscore).returns(false)
    get "/oauth?service=#{integration.underscore}"
    response.should redirect_to(user_profile_url(@user))
    flash[:error].should be_present
  end

  it "should redirect to the service for auth" do
    oauth_start(integration)
    response.should redirect_to("http://oauth.example.com/start")

    oreq = OauthRequest.last
    oreq.should be_present
    oreq.service.should == integration.underscore
    oreq.token.should == "test_token"
    oreq.secret.should == "test_secret"
    oreq.user.should == @user
    oreq.return_url.should == user_profile_url(@user)
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
      response.should redirect_to(user_profile_url(@user))
      flash[:error].should be_present
    end

    it "should fail with the wrong user" do
      OauthRequest.last.update_attribute(:user, User.create!)
      get "/oauth_success?service=#{integration.underscore}&oauth_token=test_token&oauth_verifier=test_verifier"
      response.should redirect_to(user_profile_url(@user))
      flash[:error].should be_present
    end

    it "should redirect to the original host if a different host is returned to" do
      get "http://otherschool.example.com/oauth_success?service=#{integration.underscore}&oauth_token=test_token&oauth_verifier=test_verifier"
      response.should redirect_to("http://www.example.com/oauth_success?oauth_token=test_token&oauth_verifier=test_verifier&service=#{integration.underscore}")
    end

    it "should create the UserService on successful auth" do
      oauth_start(integration)

      # mock up the response from the 3rd party service, so we don't actually contact it
      OAuth::Consumer.any_instance.expects(:token_request).with(anything, anything, anything, has_entry(:oauth_verifier, "test_verifier"), anything).returns({:oauth_token => "test_token", :oauth_token_secret => "test_secret"})
      if integration == "GoogleDocs"
        GoogleDocs.any_instance.expects(:google_docs_get_service_user).with(instance_of(OAuth::AccessToken)).returns(["test_user_id", "test_user_name"])
      else
        UsersController.any_instance.expects("#{integration.underscore}_get_service_user").with(instance_of(OAuth::AccessToken)).returns(["test_user_id", "test_user_name"])
      end

      get "/oauth_success?oauth_token=test_token&oauth_verifier=test_verifier&service=#{integration.underscore}"
      response.should redirect_to(user_profile_url(@user))
      flash[:error].should be_blank
      flash[:notice].should be_present
      us = UserService.find_by_service_and_user_id(integration.underscore, @user.id)
      us.should be_present
      us.service_user_id.should == "test_user_id"
      us.service_user_name.should == "test_user_name"
      us.token.should == "test_token"
      us.secret.should == "test_secret"
    end

    it "should fail creating the UserService if getting the initial user info fails" do
      oauth_start(integration)

      # mock up the response from the 3rd party service, so we don't actually contact it
      OAuth::Consumer.any_instance.expects(:token_request).with(anything, anything, anything, has_entry(:oauth_verifier, "test_verifier"), anything).returns({:oauth_token => "test_token", :oauth_token_secret => "test_secret"})

      # pretend that somehow we think we got a valid auth token, but we actually didn't
      if integration == "GoogleDocs"
        GoogleDocs.any_instance.expects(:google_docs_get_service_user).with(instance_of(OAuth::AccessToken)).raises(RuntimeError, "Third-party service totally like, failed")
      else
        UsersController.any_instance.expects("#{integration.underscore}_get_service_user").with(instance_of(OAuth::AccessToken)).raises(RuntimeError, "Third-party service totally like, failed")
      end

      get "/oauth_success?oauth_token=test_token&oauth_verifier=test_verifier&service=#{integration.underscore}"
      response.should redirect_to(user_profile_url(@user))
      flash[:error].should be_present
      flash[:notice].should be_blank
      us = UserService.find_by_service_and_user_id(integration.underscore, @user.id)
      us.should_not be_present
    end
  end
end
end
