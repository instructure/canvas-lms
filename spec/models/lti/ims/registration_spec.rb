# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Lti::IMS
  describe Registration do
    let(:application_type) { :web }
    let(:grant_types) { [:client_credentials, :implicit] }
    let(:response_types) { [:id_token] }
    let(:redirect_uris) { ["http://example.com"] }
    let(:initiate_login_uri) { "http://example.com/login" }
    let(:client_name) { "Example Tool" }
    let(:jwks_uri) { "http://example.com/jwks" }
    let(:logo_uri) { "http://example.com/logo.png" }
    let(:client_uri) { "http://example.com/" }
    let(:tos_uri) { "http://example.com/tos" }
    let(:policy_uri) { "http://example.com/policy" }
    let(:token_endpoint_auth_method) { "private_key_jwt" }
    let(:lti_tool_configuration) do
      {
        domain: "example.com",
        messages: [],
        claims: []
      }
    end
    let(:scopes) { [] }

    let(:registration) do
      r = Registration.new({
        application_type: application_type,
        grant_types: grant_types,
        response_types: response_types,
        redirect_uris: redirect_uris,
        initiate_login_uri: initiate_login_uri,
        client_name: client_name,
        jwks_uri: jwks_uri,
        logo_uri: logo_uri,
        client_uri: client_uri,
        tos_uri: tos_uri,
        policy_uri: policy_uri,
        token_endpoint_auth_method: token_endpoint_auth_method,
        lti_tool_configuration: lti_tool_configuration,
        scopes: scopes
      }.compact)
      r.developer_key = developer_key
      r
    end
    let(:developer_key) { DeveloperKey.create }

    describe "validations" do
      subject { registration.validate }

      context "when valid" do
        it { is_expected.to be true }
      end

      context "application_type" do
        context "is \"web\"" do
          it { is_expected.to be true }
        end

        context "is not \"web\"" do
          let(:application_type) { "native" }

          it { is_expected.to be false }
        end

        context "is not included" do
          let(:application_type) { nil }

          it { is_expected.to be false }
        end
      end

      context "grant_types" do
        context "includes other types" do
          let(:grant_types) { %i[client_credentials implicit foo bar] }

          it { is_expected.to be true }
        end

        context "does not include implicit" do
          let(:grant_types) { [:client_credentials, :foo] }

          it { is_expected.to be false }
        end

        context "does not include client_credentials" do
          let(:grant_types) { [:implicit, :foo] }

          it { is_expected.to be false }
        end
      end

      context "response_types" do
        context "includes other types" do
          let(:response_types) { %i[id_token foo bar] }

          it { is_expected.to be true }
        end

        context "is not included" do
          let(:response_types) { nil }

          it { is_expected.to be false }
        end

        context "does not include id_token" do
          let(:response_types) { [:foo, :bar] }

          it { is_expected.to be false }
        end
      end

      context "redirect_uris" do
        context "includes valid uris" do
          let(:redirect_uris) { ["https://example.com", "https://example.com/foo"] }

          it { is_expected.to be true }
        end

        context "is not included" do
          let(:redirect_uris) { nil }

          it { is_expected.to be false }
        end

        context "includes a non-url" do
          let(:redirect_uris) { ["https://example.com", "asdf"] }

          it { is_expected.to be false }
        end
      end

      context "initiate_login_uri" do
        context "is not included" do
          let(:initiate_login_uri) { nil }

          it { is_expected.to be false }
        end

        context "is a valid uri" do
          let(:initiate_login_uri) { "http://example.com/login" }

          it { is_expected.to be true }
        end

        context "is not a valid uri" do
          let(:initiate_login_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "client_name" do
        context "is not included" do
          let(:client_name) { nil }

          it { is_expected.to be false }
        end
      end

      context "jwks_uri" do
        context "is not included" do
          let(:jwks_uri) { nil }

          it { is_expected.to be false }
        end

        context "is not a valid uri" do
          let(:jwks_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "token_endpoint_auth_method" do
        context "is not \"private_key_jwt\"" do
          let(:token_endpoint_auth_method) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "logo_uri" do
        context "is not a valid uri" do
          let(:logo_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "client_uri" do
        context "is not a valid uri" do
          let(:client_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "tos_uri" do
        context "is not a valid uri" do
          let(:tos_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "policy_uri" do
        context "is not a valid uri" do
          let(:policy_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "scopes" do
        context "contains invalid scopes" do
          let(:scopes) { ["asdf"] }

          it { is_expected.to be false }
        end
      end
    end
  end
end
