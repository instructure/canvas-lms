# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe AuthenticationProvider::OpenIDConnect do
  describe "#scope_for_options" do
    it "automatically infers according to requested claims" do
      connect = described_class.new
      connect.federated_attributes = { "email" => { "attribute" => "email" } }
      connect.login_attribute = "preferred_username"
      expect(connect.send(:scope_for_options)).to eq "openid profile email"
    end
  end

  describe "#unique_id" do
    it "decodes jwt and extracts subject attribute" do
      connect = described_class.new
      payload = { sub: "some-login-attribute" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      uid = connect.unique_id(double(params: { "id_token" => id_token }, options: {}))
      expect(uid).to eq("some-login-attribute")
    end

    it "requests more attributes if necessary" do
      connect = described_class.new
      connect.userinfo_endpoint = "moar"
      connect.login_attribute = "not_in_id_token"
      payload = { sub: "1" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      token = double(options: {}, params: { "id_token" => id_token })
      expect(token).to receive(:get).with("moar").and_return(double(parsed: { "not_in_id_token" => "myid", "sub" => "1" }))
      expect(connect.unique_id(token)).to eq "myid"
    end

    it "ignores userinfo that doesn't match" do
      connect = described_class.new
      connect.userinfo_endpoint = "moar"
      connect.login_attribute = "not_in_id_token"
      payload = { sub: "1" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      token = double(options: {}, params: { "id_token" => id_token })
      expect(token).to receive(:get).with("moar").and_return(double(parsed: { "not_in_id_token" => "myid", "sub" => "2" }))
      expect(connect.unique_id(token)).to be_nil
    end

    it "returns nil if the id_token is missing" do
      connect = described_class.new
      uid = connect.unique_id(instance_double(OAuth2::AccessToken, params: { "id_token" => nil }, token: nil, options: {}))
      expect(uid).to be_nil
    end
  end

  describe "#user_logout_url" do
    it "returns the end_session_endpoint" do
      ap = AuthenticationProvider::OpenIDConnect.new(end_session_endpoint: "http://somewhere/logout")
      expect(ap.user_logout_redirect(nil, nil)).to eq "http://somewhere/logout"
    end
  end
end
