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
#

describe AuthenticationProvider::Google do
  subject(:ap) { AuthenticationProvider::Google.new(account: Account.default, client_id:) }

  let(:client_id) { "1234" }
  let(:base_token) do
    {
      "iss" => "https://accounts.google.com",
      "aud" => client_id,
      "iat" => Time.now.to_i,
      "exp" => Time.now.to_i + 30,
      "nonce" => nil
    }
  end

  def id_token(params)
    result = base_token.merge(params)
    allow(result).to receive_messages(alg: "RS256", hmac?: true, verify!: true)
    result
  end

  it "has valid recognized_params" do
    expect(AuthenticationProvider::Google.recognized_params).to include(
      *%i[client_id client_secret mfa_required skip_internal_mfa otp_via_sms login_attribute jit_provisioning hosted_domain]
    )
  end

  it "rejects non-matching hd" do
    ap.hosted_domain = "instructure.com"
    expect(CanvasSecurity).to receive(:decode_jwt).and_return(id_token("hd" => "school.edu", "sub" => "123"))
    userinfo = double("userinfo", parsed: {})
    token = double("token", params: { "id_token" => "dummy" }, options: {}, get: userinfo)

    expect { ap.unique_id(token) }.to raise_error('User is from unacceptable domain "school.edu".')
  end

  it "allows hd from list" do
    ap.hosted_domain = "canvaslms.com, instructure.com"
    expect(CanvasSecurity).to receive(:decode_jwt).and_return(id_token("hd" => "instructure.com", "sub" => "123"))
    userinfo = double("userinfo", parsed: {})
    token = double("token", params: { "id_token" => "dummy" }, options: {}, get: userinfo)

    expect(ap.unique_id(token)).to eq "123"
  end

  it "rejects missing hd" do
    ap.hosted_domain = "instructure.com"
    expect(CanvasSecurity).to receive(:decode_jwt).and_return(id_token("sub" => "123"))
    userinfo = double("userinfo", parsed: {})
    token = double("token", params: { "id_token" => "dummy" }, options: {}, get: userinfo)

    expect { ap.unique_id(token) }.to raise_error("Google Apps user not received, but required")
  end

  it "rejects missing hd for *" do
    ap.hosted_domain = "*"
    expect(CanvasSecurity).to receive(:decode_jwt).and_return(id_token("sub" => "123"))
    userinfo = double("userinfo", parsed: {})
    token = double("token", params: { "id_token" => "dummy" }, options: {}, get: userinfo)

    expect { ap.unique_id(token) }.to raise_error("Google Apps user not received, but required")
  end

  it "accepts any hd for '*'" do
    ap.hosted_domain = "*"
    expect(CanvasSecurity).to receive(:decode_jwt).once.and_return(id_token("hd" => "instructure.com", "sub" => "123"))
    token = double("token", params: { "id_token" => "dummy" }, options: {})

    expect(ap.unique_id(token)).to eq "123"
  end

  it "accepts when hosted domain isn't required" do
    expect(CanvasSecurity).to receive(:decode_jwt).once.and_return(id_token("sub" => "123"))
    userinfo = double("userinfo", parsed: {})
    token = double("token", params: { "id_token" => "dummy" }, options: {}, get: userinfo)

    expect(ap.unique_id(token)).to eq "123"
  end

  it "sets hosted domain to nil if empty string" do
    ap.hosted_domain = ""
    expect(ap.hosted_domain).to be_nil
  end

  it "requests * from google when configured for a list of domains" do
    ap.hosted_domain = "canvaslms.com, instructure.com"
    expect(ap.send(:authorize_options)[:hd]).to eq "*"
  end

  describe "#download_jwks" do
    it "updates if nothing changed, but was forced" do
      allow(subject).to receive(:jwks_uri).and_return("http://jwks")

      keypair = OpenSSL::PKey::RSA.new(2048)
      jwk = JSON::JWK.new(keypair.public_key)

      allow(CanvasHttp).to receive(:get).with("http://jwks").and_return(instance_double(Net::HTTPOK, body: [jwk].to_json))

      subject.save!
      expect(subject.jwks[jwk[:kid]]).to eq jwk.as_json

      subject.settings["jwks"] = { keys: [] }.to_json
      expect(subject.jwks).to be_empty
      subject.send(:download_jwks, force: true)
      expect(subject.jwks[jwk[:kid]]).to eq jwk.as_json
    end
  end
end
