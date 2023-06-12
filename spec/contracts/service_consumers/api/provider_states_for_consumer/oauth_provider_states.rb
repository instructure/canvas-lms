# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module LtiProviderStateHelper
  def self.set_lti_context_id(account)
    # Set lti_context_id to the same one used when generating the contracts
    # in the live-events-lti repo.
    account.update!(lti_context_id: "794d72b707af6ea82cfe3d5d473f16888a8366c7")
  end

  def self.jwk
    {
      "kty" => "RSA",
      "e" => "test",
      "n" => "test",
      "kid" => "test",
      "alg" => "RS256",
      "use" => "test",
      "iss" => "test",
      "aud" => "http://example.org/login/oauth2/token",
      "sub" => "test",
      "exp" => 10.minutes.from_now.to_i,
      "iat" => Time.zone.now.to_i,
      "jti" => "test",
    }
  end

  def self.developer_key(jwk)
    account = Pact::Canvas.base_state.account
    developer_key = account.developer_keys.create!(
      public_jwk: jwk,
      public_jwk_url: "example.org",
      scopes: [
        "https://canvas.instructure.com/lti/public_jwk/scope/update",
        "https://canvas.instructure.com/lti/data_services/scope/create",
        "https://canvas.instructure.com/lti/data_services/scope/show",
        "https://canvas.instructure.com/lti/data_services/scope/update",
        "https://canvas.instructure.com/lti/data_services/scope/list",
        "https://canvas.instructure.com/lti/data_services/scope/destroy",
        "https://canvas.instructure.com/lti/data_services/scope/list_event_types",
        "https://canvas.instructure.com/lti/feature_flags/scope/show",
      ]
    )
    enable_developer_key_account_binding!(developer_key)
    developer_key.developer_key_account_bindings.first.workflow_state = "on"
    developer_key.developer_key_account_bindings.first.save!

    developer_key
  end

  def self.create_external_tool(developer_key)
    configuration = {
      title: "Canvas Data Services",
      scopes: [
        "https://canvas.instructure.com/lti/public_jwk/scope/update",
        "https://canvas.instructure.com/lti/data_services/scope/create",
        "https://canvas.instructure.com/lti/data_services/scope/show",
        "https://canvas.instructure.com/lti/data_services/scope/update",
        "https://canvas.instructure.com/lti/data_services/scope/list",
        "https://canvas.instructure.com/lti/data_services/scope/destroy",
        "https://canvas.instructure.com/lti/data_services/scope/list_event_types",
        "https://canvas.instructure.com/lti/feature_flags/scope/show"
      ],
      public_jwk_url: "http://live-events-lti/api/jwks",
      description: "Data service management for Canvas LMS",
      target_link_uri: "http://live-events-lti/resource_link_request",
      oidc_initiation_url: "http://live-events-lti/login",
      extensions: [
        {
          platform: "canvas.instructure.com",
          domain: "http://live-events-lti",
          privacy_level: "public",
          settings: {
            placements: [
              {
                text: "Data Services",
                enabled: true,
                placement: "account_navigation",
                target_link_uri: "http://live-events-lti/resource_link_request",
                required_permissions: "manage_data_services"
              }
            ]
          }
        }
      ],
      custom_fields: {
        canvas_account_uuid: "$vnd.Canvas.root_account.uuid",
        canvas_api_domain: "$Canvas.api.domain",
        canvas_user_uuid: "$Canvas.user.globalId",
        canvas_high_contrast_enabled: "$Canvas.user.prefersHighContrast"
      }
    }
    tool_config = Lti::ToolConfiguration.create!(developer_key:, settings: configuration, privacy_level: "public")
    external_tool = tool_config.new_external_tool(developer_key.account)
    external_tool.save!
  end
end

Pact.provider_states_for PactConfig::Consumers::ALL do
  provider_state "an account with an LTI developer key" do
    set_up do
      account = Pact::Canvas.base_state.account
      LtiProviderStateHelper.set_lti_context_id(account)

      jwk = LtiProviderStateHelper.jwk
      developer_key = LtiProviderStateHelper.developer_key(jwk)

      allow_any_instance_of(Canvas::OAuth::Provider)
        .to receive(:key).and_return(developer_key)

      allow_any_instance_of(Canvas::OAuth::ClientCredentialsProvider)
        .to receive(:get_jwk_from_url).and_return(jwk)
    end
  end

  provider_state "a course with live events" do
    set_up do
      jwk = LtiProviderStateHelper.jwk
      developer_key = LtiProviderStateHelper.developer_key(jwk)
      LtiProviderStateHelper.create_external_tool(developer_key)

      account = Pact::Canvas.base_state.account
      LtiProviderStateHelper.set_lti_context_id(account)

      allow_any_instance_of(Canvas::OAuth::Provider)
        .to receive(:key).and_return(developer_key)

      allow_any_instance_of(Canvas::OAuth::ClientCredentialsProvider)
        .to receive(:get_jwk_from_url).and_return(jwk)

      # The jwt_signing_key file is the same one used to sign the JWTs in the contract
      # tests in the live-events-lti repo. Make that key be the one that Canvas uses
      # to decode JWTs.
      lti_tool_key = OpenSSL::PKey::RSA.new(File.read("../../jwt_signing_key"))
      allow(CanvasSecurity).to receive(:encryption_keys).and_return([lti_tool_key])

      # The JWT in the contracts will be expired; tell Canvas to accept it anyway.
      a_long_time = Time.zone.now.to_i + 3600
      allow(Setting).to receive(:get).and_call_original
      allow(Setting).to receive(:get).with("oauth2_jwt_iat_ago_in_seconds", anything).and_return(a_long_time.to_s)
      allow_any_instance_of(Canvas::Security::JwtValidator).to receive(:exp).and_return(true)

      allow(Rails.application.credentials).to receive(:dig).and_call_original
      allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :signing_secret).and_return("astringthatisactually32byteslong")
      allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :encryption_secret).and_return("astringthatisactually32byteslong")

      # DynamicSettings is not available on Jenkins -- need to stub it to return these values.
      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with("live-events-subscription-service", any_args).and_return({
                                                                         "app-host" => ENV.fetch("SUBSCRIPTION_SERVICE_HOST", "http://les.docker:80")
                                                                       })

      # Always set ignore_expiration to true when calling the decode_jwt method.
      CanvasSecurity.class_eval do
        @old_decode_jwt = method(:decode_jwt)

        def self.decode_jwt(body, keys = [])
          @old_decode_jwt.call(body, keys, ignore_expiration: true)
        end
      end
    end

    tear_down do
      CanvasSecurity.class_eval do
        define_singleton_method(:decode_jwt, @old_decode_jwt)
        remove_instance_variable(:@old_decode_jwt)
      end
    end
  end
end
