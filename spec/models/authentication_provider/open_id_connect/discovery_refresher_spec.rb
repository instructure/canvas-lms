# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

describe AuthenticationProvider::OpenIDConnect::DiscoveryRefresher do
  subject { AuthenticationProvider::OpenIDConnect::DiscoveryRefresher }

  let(:google_discovery_url) { "https://accounts.google.com/.well-known/openid-configuration" }
  let(:google_discovery) do
    {
      issuer: "https://accounts.google.com",
      authorization_endpoint: "https://accounts.google.com/o/oauth2/v2/auth",
      device_authorization_endpoint: "https://oauth2.googleapis.com/device/code",
      token_endpoint: "https://oauth2.googleapis.com/token",
      userinfo_endpoint: "https://openidconnect.googleapis.com/v1/userinfo",
      revocation_endpoint: "https://oauth2.googleapis.com/revoke",
      jwks_uri: "https://www.googleapis.com/oauth2/v3/certs",
      response_types_supported: [
        "code",
        "token",
        "id_token",
        "code token",
        "code id_token",
        "token id_token",
        "code token id_token",
        "none"
      ],
      subject_types_supported: [
        "public"
      ],
      id_token_signing_alg_values_supported: [
        "RS256"
      ],
      scopes_supported: %w[
        openid
        email
        profile
      ],
      token_endpoint_auth_methods_supported: [
        "client_secret_post",
        "client_secret_basic"
      ],
      claims_supported: %w[
        aud
        email
        email_verified
        exp
        family_name
        given_name
        iat
        iss
        name
        picture
        sub
      ],
      code_challenge_methods_supported: [
        "plain",
        "S256"
      ],
      grant_types_supported: [
        "authorization_code",
        "refresh_token",
        "urn:ietf:params:oauth:grant-type:device_code",
        "urn:ietf:params:oauth:grant-type:jwt-bearer"
      ]
    }.to_json
  end
  let(:google_jwks) do
    {
      keys: [
        {
          kty: "RSA",
          e: "AQAB",
          kid: "e863fe292fa2a2967cd7551c42a1211bcac55071",
          use: "sig",
          n: "wf1QrSd3mb3vX2ntibkz-lyQ67UeNJ_q44U-VzJIv9ysj2fM_tOplcS3zPG1nQ0_o85LmP_ivM6svoUwZ4PPizDaE6-Ahk6Cngv9FtN98GbsFDuou3aLNuwA6cvR_TCMXyfAO69oDjph9wviHH0WSyV-jqXjvzt8fVOiARhYN5BsH25YgnGRKW3r5RUxLYEamDWQ8UMCy8x1OPrY6LioKR5lXchjUAGLjx-dBUw6sj6fA8LJKt4XaQ62bGQrs93jlIKir_hRUPeEhrNSFLCr3W0yVjlCh5a9dIcgSkaa5oIJYQTFQq6jHznrsKC4i4POa601TcjMsjBc_6n5Qof8iQ",
          alg: "RS256"
        },
        {
          alg: "RS256",
          kty: "RSA",
          e: "AQAB",
          n: "3zWQqZ_EHrbvwfuq3H7TCBDeanfgxcPxno8GuNQwo5vZQG6hVPqB_NfKNejm2PQG6icoueswY1x-TXdYhn7zuVRrbdiz1Cn2AsUFHhD-FyUipbeXxJPe7dTSQaYwPyzQKNWU_Uj359lXdqXQ_iT-M_QknGTXsf4181r1FTaRMb-89Koj2ZHSHZx-uaPKNzrS92XHoxFXqlMMZYivqEAUE_kAJp-jQ5I5AAQf318zVGPVJX7BxkbcPaM46SZNJaD0ya7uhKWwluqgSjHkOObI5bbq9LmV3N51jzPgxGrH2OEeQBCXzggYzjMVlNuUnfQbNKvF3Xqc4HHWXulDsszGRQ",
          use: "sig",
          kid: "1dc0f172e8d6ef382d6d3a231f6c197dd68ce5ef"
        }
      ]
    }.to_json
  end

  describe ".refresh_providers" do
    before do
      jwks_response = instance_double(Net::HTTPSuccess, :body => google_jwks, :value => nil, :[] => nil)
      allow(CanvasHttp).to receive(:get).with("https://www.googleapis.com/oauth2/v3/certs").and_yield(jwks_response).and_return(jwks_response)
      allow(CanvasHttp).to receive(:get).with("https://www.googleapis.com/oauth2/v3/certs", {}).and_yield(jwks_response).and_return(jwks_response)
    end

    it "works" do
      discovery_response = instance_double(Net::HTTPSuccess, :body => google_discovery, :value => nil, :[] => nil)
      allow(CanvasHttp).to receive(:get).with(google_discovery_url).and_yield(discovery_response).and_return(discovery_response)
      allow(CanvasHttp).to receive(:get).with(google_discovery_url, {}).and_yield(discovery_response).and_return(discovery_response)

      ap = AuthenticationProvider::OpenIDConnect.create!(account: Account.default, discovery_url: google_discovery_url)
      subject.refresh_providers
      ap.reload
      expect(ap.settings["jwks"]).to eq google_jwks
    end
  end
end
