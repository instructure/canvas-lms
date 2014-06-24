#
# Copyright (C) 2014 Instructure, Inc.
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

require "spec_helper"

describe Facebook::Connection do
  describe ".dashboard_increment_count" do
    let(:user_id) { 1 }
    let(:token) { "asdf" }
    let(:message) { "some message" }

    it "fetches data from facebook" do
      mock_client = stub("use_ssl=" => true)
      Net::HTTP.expects(:new).with("graph.facebook.com", 443).returns(mock_client)
      mock_response = stub(body: "{}")
      mock_client.expects(:post).with("/1/apprequests?access_token=asdf&message=some+message", "").returns(mock_response)

      response_json = Facebook::Connection.dashboard_increment_count(user_id, token, message)
      response_json.should == {}
    end

    it "returns errors" do
      mock_client = stub("use_ssl=" => true)
      Net::HTTP.expects(:new).with("graph.facebook.com", 443).returns(mock_client)
      mock_response = stub(body: "{\"error\": { \"message\": \"some error\" } }")
      mock_client.expects(:post).with("/1/apprequests?access_token=asdf&message=some+message", "").returns(mock_response)
      mock_logger = stub()
      mock_logger.expects(:error).with("some error")
      Facebook::Connection.logger = mock_logger

      response = Facebook::Connection.dashboard_increment_count(user_id, token, message)
      response.should == nil
    end
  end

  describe ".get_service_user_info" do
    let(:token) { "asdf" }

    it "fetches the user's info from facebook" do
      mock_client = stub("use_ssl=" => true)
      Net::HTTP.expects(:new).with("graph.facebook.com", 443).returns(mock_client)
      mock_response = stub(body: "{}")
      mock_client.expects(:get).with("/me?access_token=asdf").returns(mock_response)

      response_json = Facebook::Connection.get_service_user_info(token)
      response_json.should == {}
    end
  end

  describe ".authorize_url" do
    it "returns a http callback url" do
      Facebook::Connection.config = Proc.new do
        {
            "disable_ssl" => false,
            "canvas_domain" => "example.com",
            "app_id" => 1
        }
      end

      url = Facebook::Connection.authorize_url("some state")
      url.should == "https://www.facebook.com/dialog/oauth?client_id=1&redirect_uri=https%3A%2F%2Fexample.com%2Ffacebook_success.html&response_type=token&scope=offline_access&state=some+state"
    end

    it "returns a https callback url" do
      Facebook::Connection.config = Proc.new do
        {
            "disable_ssl" => true,
            "canvas_domain" => "example.com",
            "app_id" => 1
        }
      end

      url = Facebook::Connection.authorize_url("some state")
      url.should == "https://www.facebook.com/dialog/oauth?client_id=1&redirect_uri=http%3A%2F%2Fexample.com%2Ffacebook_success.html&response_type=token&scope=offline_access&state=some+state"
    end
  end

  describe ".app_url" do
    it "returns the url for the facebook app" do
      Facebook::Connection.config = Proc.new do
        {
            "canvas_name" => "app name"
        }
      end

      url = Facebook::Connection.app_url

      url.should == "http://apps.facebook.com/app%20name"
    end
  end

  describe ".config_check" do
    let(:settings) {
      {
          "app_id" => 1,
          "disable_ssl" => false,
          "canvas_domain" => "example.com",
          "secret" => "some_secret"

      }
    }
    let(:mock_request) { stub() }
    let(:mock_http_client) { stub("use_ssl=" => true) }

    before do
      Net::HTTP.expects(:new).with("graph.facebook.com", 443).returns(mock_http_client)
      Net::HTTP::Get.expects(:new).with("/oauth/access_token?client_id=1&redirect_uri=https://example.com&client_secret=some_secret&code=wrong&format=json").returns(mock_request)
    end

    it "returns nil if there are no config issues" do
      mock_response = stub(body: "{\"error\": {\"message\": \"Invalid verification code format.\"} }")
      mock_http_client.expects(:request).with(mock_request).returns(mock_response)

      response = Facebook::Connection.config_check(settings)
      response.should == nil
    end

    it "returns an error for invalid app id or secret" do
      mock_response = stub(body: "{\"error\": {\"message\": \"Error validating client secret.\"} }")
      mock_http_client.expects(:request).with(mock_request).returns(mock_response)

      response = Facebook::Connection.config_check(settings)
      response.should == "Invalid app id or app secret"
    end

    it "returns an error for invalid app id or redirect uri" do
      mock_response = stub(body: "{\"error\": {\"message\": \"Invalid redirect_uri: Given URL is not allowed by the Application configuration.\"} }")
      mock_http_client.expects(:request).with(mock_request).returns(mock_response)

      response = Facebook::Connection.config_check(settings)
      response.should == "Invalid app id or redirect uri"
    end

    it "handles unexpected errors" do
      mock_response = stub(body: "{\"error\": {} }")
      mock_http_client.expects(:request).with(mock_request).returns(mock_response)

      response = Facebook::Connection.config_check(settings)
      response.should == "Unexpected error"
    end

    it "handles no error hash being returned" do
      mock_response = stub(body: "{}")
      mock_http_client.expects(:request).with(mock_request).returns(mock_response)

      response = Facebook::Connection.config_check(settings)
      response.should == "Unexpected response from settings check"
    end
  end

  describe ".parse_signed_request" do
    before do
      Facebook::Connection.config = Proc.new do
        {"secret" => "some_secret"}
      end
    end

    it "it validates that the signature is valid for the data received without base64 padding" do
      signed_request = "rMW_EZsuewDRugWQcADJQHv6vACRm52j4fImobPGbc0.eyJiYXIiOiAxfQ"

      data, sig = Facebook::Connection.parse_signed_request(signed_request)

      data.should_not == nil
      sig.should_not == nil
    end

    it "it validates that the signature is valid for the data received" do
      signed_request = "hVszsr2l--5aA7urFPq998bflV9Ap6h4TUvcC8Q7NBY.eyJiYXIiOiAxfQ=="

      data, sig = Facebook::Connection.parse_signed_request(signed_request)

      data.should_not == nil
      sig.should_not == nil
    end

    it "returns nils when the json fails to parse" do
      signed_request = "OeErWYWEJNc9b1tG5PohWSyyer1HLTMMjpv6CFWbLzw.not_base64_encoded_json"

      data, sig = Facebook::Connection.parse_signed_request(signed_request)

      data.should == nil
      sig.should_not == nil
    end

    it "returns nils when the signature is wrong" do
      signed_request = "bad.eyJiYXIiOiAxfQ"

      data, sig = Facebook::Connection.parse_signed_request(signed_request)

      data.should_not == nil
      sig.should == nil
    end
  end
end