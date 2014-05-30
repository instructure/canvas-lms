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

require 'spec_helper'

describe LinkedIn::Connection do
  before do
    config = {
      'api_key' => 'key',
      'secret_key' => 'secret'
    }
    LinkedIn::Connection.config = Proc.new do
      config
    end
  end

  let (:connection) {LinkedIn::Connection.new}

  describe "#get_service_user_info" do
    it "returns service user info" do
      token_response_body = "<html><id>#1</id><first-name>john</first-name><last-name>doe</last-name><public-profile-url>http://example.com/linkedin</public-profile-url></html>"
      mock_access_token = stub()
      mock_access_token.expects(:get)
                       .with('/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url)')
                       .returns(stub(body: token_response_body))

      service_user_id, service_user_name, service_user_url = connection.get_service_user_info(mock_access_token)
      service_user_id.should == "#1"
      service_user_name.should == "john doe"
      service_user_url.should == "http://example.com/linkedin"
    end
  end

  describe "#get_access_token" do
    it "builds access token based on the supplied parameters" do
      token = mock
      secret = mock
      oauth_verifier = mock
      consumer = mock
      request_token = mock
      OAuth::Consumer.expects(:new).returns(consumer)
      OAuth::RequestToken.expects(:new).with(consumer, token, secret).returns(request_token)
      request_token.expects(:get_access_token).with(:oauth_verifier => oauth_verifier)

      connection.get_access_token(token, secret, oauth_verifier)
    end
  end

  describe "#request_token" do
    it "builds access token based on the supplied parameters" do
      consumer = mock
      oauth_callback = mock
      OAuth::Consumer.expects(:new).returns(consumer)
      consumer.expects(:get_request_token).with(:oauth_callback => oauth_callback)

      connection.request_token(oauth_callback)
    end
  end

  describe ".consumer" do
    it "uses the config values" do

      OAuth::Consumer.expects(:new).with('key', 'secret', {
        :site => "https://api.linkedin.com",
        :request_token_path => "/uas/oauth/requestToken",
        :access_token_path => "/uas/oauth/accessToken",
        :authorize_path => "/uas/oauth/authorize",
        :signature_method => "HMAC-SHA1"
      })

      LinkedIn::Connection.consumer
    end

    it "user the supplied parameters" do
      OAuth::Consumer.expects(:new).with('my_key', 'my_secret', {
        :site => "https://api.linkedin.com",
        :request_token_path => "/uas/oauth/requestToken",
        :access_token_path => "/uas/oauth/accessToken",
        :authorize_path => "/uas/oauth/authorize",
        :signature_method => "HMAC-SHA1"
      })

      LinkedIn::Connection.consumer('my_key', 'my_secret')
    end
  end
end
