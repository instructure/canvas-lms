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

  describe ".config" do
    it "accepts any object with a call interface" do
      conf_class= Class.new do
        def call
          {'some' => 'config'}
        end
      end

      described_class.config = conf_class.new
      expect(described_class.config['some']).to eq('config')
    end

    it "rejects uncallable configs" do
      expect { described_class.config = Object.new }.to(
        raise_error(RuntimeError) do |e|
          expect(e.message).to match(/must respond to/)
        end
      )
    end
  end

  context "with valid configuration" do

    before do
      config = {
        'api_key' => 'key',
        'secret_key' => 'secret'
      }
      LinkedIn::Connection.config = proc{ config }
    end

    describe "#get_service_user_info" do
      it "returns service user info" do
        token_response_body = "<html><id>#1</id>"\
                              "<first-name>john</first-name>"\
                              "<last-name>doe</last-name>"\
                              "<public-profile-url>http://example.com/linkedin</public-profile-url>"\
                              "</html>"
        mock_access_token = double()
        expect(mock_access_token).to receive(:get)
                         .with('/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url)')
                         .and_return(double(body: token_response_body))

        linkedin = LinkedIn::Connection.new(mock_access_token)
        expect(linkedin.service_user_id).to eq("#1")
        expect(linkedin.service_user_name).to eq("john doe")
        expect(linkedin.service_user_url).to eq("http://example.com/linkedin")
      end
    end

    describe ".from_request_token" do
      it "builds access token based on the supplied parameters" do
        token = double
        secret = double
        oauth_verifier = double
        consumer = double
        request_token = double
        access_token = double
        expect(OAuth::Consumer).to receive(:new).and_return(consumer)
        expect(OAuth::RequestToken).to receive(:new).with(consumer, token, secret).and_return(request_token)
        expect(request_token).to receive(:get_access_token).with(:oauth_verifier => oauth_verifier).and_return(access_token)

        linkedin = LinkedIn::Connection.from_request_token(token, secret, oauth_verifier)
        expect(linkedin.access_token).to eq(access_token)
      end
    end

    describe ".request_token" do
      it "builds access token based on the supplied parameters" do
        consumer = double
        oauth_callback = double
        expect(OAuth::Consumer).to receive(:new).and_return(consumer)
        expect(consumer).to receive(:get_request_token).with(:oauth_callback => oauth_callback)

        LinkedIn::Connection.request_token(oauth_callback)
      end
    end

    describe ".config_check" do
      it "user the supplied parameters" do
        consumer = double(get_request_token: "present")
        expect(OAuth::Consumer).to receive(:new).with('my_key', 'my_secret', {
          :site => "https://api.linkedin.com",
          :request_token_path => "/uas/oauth/requestToken",
          :access_token_path => "/uas/oauth/accessToken",
          :authorize_path => "/uas/oauth/authorize",
          :signature_method => "HMAC-SHA1"
        }).and_return(consumer)

        LinkedIn::Connection.config_check({
          api_key: 'my_key',
          secret_key: 'my_secret'
        })
      end
    end
  end
end
