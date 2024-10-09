# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Schemas::Lti::IMS::OidcRegistration do
  let(:valid) do
    # Example from https://www.imsglobal.org/spec/lti-dr/v1p0#supported-types-property
    # Fields we don't (yet) support in the schema and Dyn Reg endpoint are commented out
    {
      "application_type" => "web",
      "response_types" => ["id_token"],
      "grant_types" => ["implicit", "client_credentials"],
      "initiate_login_uri" => "https://client.example.org/lti",
      "redirect_uris" =>
        ["https://client.example.org/callback",
         "https://client.example.org/callback2"],
      "client_name" => "Virtual Garden",
      # "client_name#ja" => "バーチャルガーデン", # l18n like this not supported
      "jwks_uri" => "https://client.example.org/.well-known/jwks.json",
      "logo_uri" => "https://client.example.org/logo.png",
      "client_uri" => "https://client.example.org",
      # "client_uri#ja" => "https://client.example.org?lang=ja", # not supported
      "policy_uri" => "https://client.example.org/privacy",
      # "policy_uri#ja" => "https://client.example.org/privacy?lang=ja", # not supported
      "tos_uri" => "https://client.example.org/tos",
      # "tos_uri#ja" => "https://client.example.org/tos?lang=ja", # not supported
      "token_endpoint_auth_method" => "private_key_jwt",
      "contacts" => ["ve7jtb@example.org", "mary@example.org"],
      "scope" => "https://purl.imsglobal.org/spec/lti-ags/scope/score openid https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
      "https://purl.imsglobal.org/spec/lti-tool-configuration" => {
        "domain" => "client.example.org",
        "deployment_id" => "foo",
        # secondary_domains not supported (as if Aug 2024) in code but passed through and stored in model.
        "secondary_domains" => ["client2.example.org"],
        "description" => "Learn Botany by tending to your little (virtual) garden.",
        # "description#ja" => "小さな（仮想）庭に行くことで植物学を学びましょう。", # not supported
        "target_link_uri" => "https://client.example.org/lti",
        "custom_parameters" => {
          "context_history" => "$Context.id.history"
        },
        "claims" => %w[iss sub name given_name family_name],
        "messages" => [
          {
            "type" => "LtiDeepLinkingRequest",
            "target_link_uri" => "https://client.example.org/lti/dl",
            "label" => "Add a virtual garden",
            # "label#ja" => "バーチャルガーデンを追加する", # not supported
            "custom_parameters" => {
              "botanical_set" => "12943,49023,50013"
            },
            "placements" => ["ContentArea"],
            # "supported_types" => ["ltiResourceLink"] # not supported
          },
          {
            "type" => "LtiDeepLinkingRequest",
            "label" => "Add your Garden image",
            # "label#ja" => "あなたの庭を選んでください",
            "placements" => ["RichTextEditor"],
            "roles" => [
              "http =>//purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper",
              "http =>//purl.imsglobal.org/vocab/lis/v2/membership#Instructor"
            ],
            # "supported_types" => ["file"], # not supported
            # "supported_media_types" => ["image/*"] # not supported
          }
        ]
      }
    }
  end

  describe ".to_model_attrs" do
    it "returns errors when the input is invalid" do
      described_class.to_model_attrs({})
      expect(described_class.to_model_attrs({})).to match({
                                                            errors: [a_string_matching(/required/)],
                                                            registration_attrs: nil
                                                          })
    end

    it "returns a hash that can be used to construct an Lti::IMS::Registration" do
      described_class.to_model_attrs(valid) => {errors:, registration_attrs:}
      expect(errors).to be_nil
      reg = Lti::IMS::Registration.create!(
        developer_key: developer_key_model,
        root_account_id: account_model.id,
        guid: SecureRandom.uuid,
        unified_tool_id: "unified_tool_id",
        registration_url: "https://example.com",
        **registration_attrs.except(*Lti::IMS::Registration::IMPLIED_SPEC_ATTRIBUTES)
      )
      expect(reg).to be_persisted
      expect(reg.contacts).to eq(["ve7jtb@example.org", "mary@example.org"])
      expect(reg.lti_tool_configuration["messages"][0]["type"]).to eq("LtiDeepLinkingRequest")
    end

    it "returns attributes that can be used to construct a DeveloperKey" do
      described_class.to_model_attrs(valid) => {errors:, registration_attrs:}
      developer_key = DeveloperKey.create!(
        current_user: user_model,
        name: registration_attrs["client_name"],
        account: nil,
        redirect_uris: registration_attrs["redirect_uris"],
        public_jwk_url: registration_attrs["jwks_uri"],
        oidc_initiation_url: registration_attrs["initiate_login_uri"],
        is_lti_key: true,
        scopes: registration_attrs["scopes"],
        icon_url: registration_attrs["logo_uri"]
      )
      expect(developer_key).to be_persisted
    end

    it "splits up scopes and removes the openid scope" do
      described_class.to_model_attrs(valid) => {errors:, registration_attrs:}
      expect(registration_attrs["scopes"]).to eq([
                                                   "https://purl.imsglobal.org/spec/lti-ags/scope/score",
                                                   "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"
                                                 ])
    end
  end

  describe ".validate_and_filter" do
    def merge_or_delete!(hash, **keys)
      keys = keys.deep_stringify_keys
      deletes = keys.select { |_, v| v == :delete }.keys
      deletes.each { |k| hash.delete(k) }
      keys = keys.except(*deletes)
      hash.merge!(keys)
    end

    def validate_and_filter(ltc: {}, message: {}, **merges)
      json = valid.deep_dup
      merge_or_delete!(
        json["https://purl.imsglobal.org/spec/lti-tool-configuration"]["messages"][0],
        **message
      )
      merge_or_delete!(
        json["https://purl.imsglobal.org/spec/lti-tool-configuration"],
        **ltc
      )
      merge_or_delete!(json, **merges)
      described_class.validate_and_filter(json)
    end

    def errors(**merges)
      validate_and_filter(**merges)[:errors]&.join("\n")
    end

    def expect_no_errors(**merges)
      errs = errors(**merges)
      expect(errs).to be_blank, "Expected no errors, got: #{errs.inspect}"
    end

    # Some of the tested things are actually in Schemas::Lti::LtiToolConfiguration
    it("allows valid json") { expect_no_errors }

    it("deep stringifies keys") do
      expect(described_class.validate_and_filter(valid.deep_stringify_keys)).to eq({
                                                                                     errors: nil,
                                                                                     registration_params: valid,
                                                                                   })
    end

    it("allows extra properties at top level") { expect_no_errors extra: "foo" }
    it("allows extra properties under lti tool config") { expect_no_errors ltc: { extra: "foo" } }
    it("allows extra properties under lti messages") { expect_no_errors message: { extra: "a" } }

    it "returns an array of errors if there are multiple problems with the input" do
      res = validate_and_filter(
        ltc: { domain: "#@#@" },
        message: { type: "invalid" }
      )
      expect(res[:errors].length).to be > 1
      expect(res[:errors]).to include(a_string_matching(/domain/), a_string_matching(/type/))
    end

    it "filters out unknown properties" do
      res = validate_and_filter(extra: "foo", ltc: { extra: "bar" }, message: { extra: "baz" })
      expect(res[:registration_params]).to eq(valid.deep_stringify_keys)
    end

    it "requires application_type to be 'web'" do
      expect(errors(application_type: "invalid")).to include("application_type")
    end

    it "requires grant_types to be an array of strings" do
      expect(errors(grant_types: "invalid")).to include("grant_types")
    end

    it "requires grant_types to include 'client_credentials'" do
      expect(errors(grant_types: ["implicit", "foo"])).to include("grant_types")
    end

    it "requires grant_types to include 'implicit'" do
      expect(errors(grant_types: ["client_credentials", "foo"])).to include("grant_types")
    end

    it "allows extra grant_types" do
      expect_no_errors(grant_types: %w[implicit client_credentials foo])
    end

    it "requires response_types to be an array of strings" do
      expect(errors(response_types: "invalid")).to include("response_types")
    end

    it "requires response_types to include 'id_token'" do
      expect(errors(response_types: ["foo"])).to include("response_types")
    end

    it "allows extra response_types" do
      expect_no_errors(response_types: ["id_token", "foo"])
    end

    it "requires redirect_uris to be an array of uri strings (at least one)" do
      expect(errors(redirect_uris: "invalid")).to include("redirect_uris")
      expect(errors(redirect_uris: [])).to include("redirect_uris")
      expect_no_errors(redirect_uris: ["https://example.com", "https://example.org"])
    end

    it "requires initate_login_uri to be a uri string" do
      expect(errors(initiate_login_uri: "invalid")).to include("initiate_login_uri")
    end

    it "requires client_name to be a non-empty string" do
      expect(errors(client_name: "")).to include("client_name")
    end

    it "requires jws_uri to be a uri string" do
      expect(errors(jwks_uri: "invalid")).to include("jwks_uri")
    end

    it "requires token_endpoint_auth_method to be 'private_key_jwt'" do
      expect(errors(token_endpoint_auth_method: "invalid")).to include("token_endpoint_auth_method")
    end

    it "requires (if present & non-null) scope to be a string" do
      expect(errors(scope: 123)).to include("scope")
      expect_no_errors(scope: nil)
      expect_no_errors(scope: :delete)
    end

    it "requires (if present) contacts to be a list of emails" do
      expect(errors(contacts: "invalid")).to include("contacts")
      expect(errors(contacts: nil)).to include("contacts")
      expect_no_errors(contacts: :delete)
    end

    it "requires (if present & non-null) logo_uri to be a uri string" do
      expect(errors(logo_uri: "invalid")).to include("logo_uri")
      expect_no_errors(logo_uri: nil)
      expect_no_errors(logo_uri: :delete)
    end

    it "requires (if present & non-null) client_uri to be a uri string" do
      expect(errors(client_uri: "invalid")).to include("client_uri")
      expect_no_errors(client_uri: nil)
      expect_no_errors(client_uri: :delete)
    end

    it "requires (if present & non-null) tos_uri to be a uri string" do
      expect(errors(tos_uri: "invalid")).to include("tos_uri")
      expect_no_errors(tos_uri: nil)
      expect_no_errors(tos_uri: :delete)
    end

    it "requires (if present & non-null) policy_uri to be a uri string" do
      expect(errors(policy_uri: "invalid")).to include("policy_uri")
      expect_no_errors(policy_uri: nil)
      expect_no_errors(policy_uri: :delete)
    end

    describe "https://purl.imsglobal.org/spec/lti-tool-configuration" do
      it "requires it to be an object" do
        errs = errors(
          "https://purl.imsglobal.org/spec/lti-tool-configuration" => "invalid"
        )

        expect(errs).to match(/purl.imsglobal.org.*lti-tool-configuration/)
      end

      it "allows extra properties" do
        expect_no_errors(ltc: { extra: "foo" })
      end

      it "requires domain to be a hostname or hostname with port" do
        expect(errors(ltc: { domain: "#@#@" })).to include("domain")
        expect(errors(ltc: { domain: "https://example.com:1234" })).to include("domain")
        expect_no_errors(ltc: { domain: "example.com" })
        expect_no_errors(ltc: { domain: "example.com:1234" })
      end

      it "requires custom_parameters (if present) to be an object with string values" do
        expect(errors(ltc: { custom_parameters: { foo: 123 } })).to include("custom_parameters")
        expect(errors(ltc: { custom_parameters: nil })).to include("custom_parameters")
        expect_no_errors(ltc: { custom_parameters: :delete })
        expect_no_errors(ltc: { custom_parameters: {} })
      end

      it "requires description (if present & non-null) to be a string" do
        expect(errors(ltc: { description: 123 })).to include("description")
        expect_no_errors(ltc: { description: nil })
        expect_no_errors(ltc: { description: :delete })
      end

      it "requires claims to be an array" do
        expect(errors(ltc: { claims: "invalid" })).to include("claims")
      end

      it "requires messages to be an array" do
        expect(errors(ltc: { messages: "invalid" })).to include("messages")
      end

      describe "each message" do
        it "requires it to be an object" do
          expect(errors(ltc: { messages: ["invalid"] })).to include("messages")
        end

        it "requires type to be one of Lti::ResourcePlacement::LTI_ADVANTAGE_MESSAGE_TYPES" do
          expect(errors(message: { type: "invalid" })).to include("type")
        end

        it "request target_link_uri (if present & non-null) to be a uri string" do
          expect(errors(message: { target_link_uri: "invalid" })).to include("target_link_uri")
          expect_no_errors(message: { target_link_uri: nil })
          expect_no_errors(message: { target_link_uri: :delete })
        end

        it "requires label (if present & non-null) to be a string" do
          expect(errors(message: { label: 123 })).to include("label")
          expect_no_errors(message: { label: nil })
          expect_no_errors(message: { label: :delete })
        end

        it "requires icon_uri (if present & non-null) to be a uri string" do
          expect(errors(message: { icon_uri: 123 })).to include("icon_uri")
          expect_no_errors(message: { icon_uri: nil })
          expect_no_errors(message: { icon_uri: :delete })
        end

        it "retuires custom_parameters (if present) to be an object with string values" do
          expect(errors(message: { custom_parameters: { foo: 123 } })).to include("custom_parameters")
          expect(errors(message: { custom_parameters: nil })).to include("custom_parameters")
          expect_no_errors(message: { custom_parameters: {} })
          expect_no_errors(message: { custom_parameters: :delete })
        end

        it "request placements (if present) to be an array of strings" do
          expect(errors(message: { placements: "invalid" })).to include("placements")
          expect(errors(message: { placements: nil })).to include("placements")
          expect_no_errors(message: { placements: :delete })
        end

        it "requires roles (if present) to be an array of strings" do
          expect(errors(message: { roles: "invalid" })).to include("roles")
          expect(errors(message: { roles: [1] })).to include("roles")
          expect(errors(message: { roles: nil })).to include("roles")
          expect_no_errors(message: { roles: [] })
          expect_no_errors(message: { roles: :delete })
        end

        it "requires Canvas extension course_navigation.default_enabled (if present) to be a boolean" do
          key = Lti::IMS::Registration::COURSE_NAV_DEFAULT_ENABLED_EXTENSION
          expect(errors(message: { key => "invalid" })).to match(/course_navigation.*default_enabled/)
          expect(errors(message: { key => nil })).to match(/course_navigation.*default_enabled/)
          expect_no_errors(message: { key => true })
        end

        it "requires Canvas extension placement_visibility (if present & non null) to be one of Lti::IMS::Registration::PLACEMENT_VISIBILITY_OPTIONS" do
          key = Lti::IMS::Registration::PLACEMENT_VISIBILITY_EXTENSION
          expect(errors(message: { key => "invalid" })).to include("visibility")
          expect_no_errors(message: { key => nil })
          expect_no_errors(message: { key => "admins" })
          expect_no_errors(message: { key => "members" })
          expect_no_errors(message: { key => "public" })
        end

        it "requires Canvas extension display_type (if present & non null) to be a from an enum" do
          key = Lti::IMS::Registration::DISPLAY_TYPE_EXTENSION
          expect(errors(message: { key => 123 })).to include("display_type")
          expect(errors(message: { key => "something-invalid" })).to include("display_type")
          expect_no_errors(message: { key => nil })
          expect_no_errors(message: { key => "in_nav_context" })
          expect_no_errors(message: { key => "default" })
        end

        it "requires Canvas extension launch_width (if present & non null) to be an integer or string" do
          key = Lti::IMS::Registration::LAUNCH_WIDTH_EXTENSION
          expect(errors(message: { key => true })).to include("launch_width")
          expect_no_errors(message: { key => nil })
          expect_no_errors(message: { key => 123 })
          expect_no_errors(message: { key => "100%" })
        end

        it "requires Canvas extension launch_height (if present & non null) to be an integer or string" do
          key = Lti::IMS::Registration::LAUNCH_HEIGHT_EXTENSION
          expect(errors(message: { key => true })).to include("launch_height")
          expect_no_errors(message: { key => nil })
          expect_no_errors(message: { key => 123 })
          expect_no_errors(message: { key => "100%" })
        end

        it "requires Canvas extension tool_id (if present & non-null) to be a string" do
          key = Lti::IMS::Registration::TOOL_ID_EXTENSION
          expect(errors(ltc: { key => 123 })).to include("tool_id")
          expect_no_errors(ltc: { key => nil })
          expect_no_errors(ltc: { key => :delete })
          expect_no_errors(ltc: { key => "foo" })
        end
      end

      it "requires Canvas extension privacy_level (if present & non-null) to be one of the supported levels" do
        key = Lti::IMS::Registration::PRIVACY_LEVEL_EXTENSION
        expect(errors(ltc: { key => "invalid" })).to include("privacy_level")
        expect_no_errors(ltc: { key => nil })
        Lti::PrivacyLevelExpander::SUPPORTED_LEVELS.each do |val|
          expect_no_errors(ltc: { key => val })
        end
      end

      it "requires secondary_domains (if present) to be an array of hostnames" do
        expect(errors(ltc: { secondary_domains: "invalid" })).to include("secondary_domains")
        expect(errors(ltc: { secondary_domains: [123] })).to include("secondary_domains")
        expect_no_errors(ltc: { secondary_domains: [] })
        expect_no_errors(ltc: { secondary_domains: :delete })
      end

      it "requires deployment_id (if present & non-null) to be a string" do
        expect(errors(ltc: { deployment_id: 123 })).to include("deployment_id")
        expect_no_errors(ltc: { deployment_id: nil })
        expect_no_errors(ltc: { deployment_id: :delete })
      end
    end
  end
end
