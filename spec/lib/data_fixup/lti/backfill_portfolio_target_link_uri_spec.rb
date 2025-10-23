# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe DataFixup::Lti::BackfillPortfolioTargetLinkUri do
  let_once(:account) { account_model }
  let_once(:developer_key) { DeveloperKey.create!(account:) }
  let_once(:lti_registration) { Lti::Registration.create!(account:, developer_key:, name: "Test Registration") }

  describe ".run" do
    context "when lti_tool_configuration is missing target_link_uri" do
      context "with portfolio.instructure.com domain" do
        let(:config_with_uri) do
          {
            "domain" => "test.portfolio.instructure.com",
            "target_link_uri" => "https://test.portfolio.instructure.com/launch",
            "claims" => [],
            "messages" => [
              {
                "type" => "LtiResourceLinkRequest",
                "target_link_uri" => "https://test.portfolio.instructure.com/launch",
                "label" => "Test Tool"
              }
            ]
          }
        end
        let(:config_without_uri) do
          {
            "domain" => "test.portfolio.instructure.com",
            "claims" => [],
            "messages" => [
              {
                "type" => "LtiResourceLinkRequest",
                "target_link_uri" => "https://test.portfolio.instructure.com/launch",
                "label" => "Test Tool"
              }
            ]
          }
        end
        let(:ims_registration) do
          registration = Lti::IMS::Registration.create!(
            developer_key:,
            lti_registration:,
            lti_tool_configuration: config_with_uri,
            client_name: "Test Client",
            initiate_login_uri: "https://test.portfolio.instructure.com/login",
            redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
            jwks_uri: "https://test.portfolio.instructure.com/jwks",
            scopes: []
          )
          registration.update_column(:lti_tool_configuration, config_without_uri)
          registration
        end

        it "backfills the target_link_uri from messages[0]" do
          expect(ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
          expect(ims_registration.workflow_state).to eq("active")
          described_class.run
          ims_registration.reload
          expect(ims_registration.lti_tool_configuration["target_link_uri"]).to eq("https://test.portfolio.instructure.com/launch")
        end

        context "when registration is deleted" do
          let(:deleted_ims_registration) do
            registration = Lti::IMS::Registration.create!(
              developer_key:,
              lti_registration:,
              lti_tool_configuration: config_with_uri,
              client_name: "Test Client Deleted",
              initiate_login_uri: "https://test.portfolio.instructure.com/login",
              redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
              jwks_uri: "https://test.portfolio.instructure.com/jwks",
              scopes: [],
              workflow_state: "deleted"
            )
            registration.update_column(:lti_tool_configuration, config_without_uri)
            registration
          end

          it "does not backfill deleted registrations" do
            expect(deleted_ims_registration.workflow_state).to eq("deleted")
            expect(deleted_ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
            described_class.run
            deleted_ims_registration.reload
            expect(deleted_ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
          end
        end
      end

      context "with non-portfolio domain" do
        let(:config_with_uri) do
          {
            "domain" => "example.com",
            "target_link_uri" => "https://example.com/launch",
            "claims" => [],
            "messages" => [
              {
                "type" => "LtiResourceLinkRequest",
                "target_link_uri" => "https://example.com/launch",
                "label" => "Test Tool"
              }
            ]
          }
        end
        let(:config_without_uri) do
          {
            "domain" => "example.com",
            "claims" => [],
            "messages" => [
              {
                "type" => "LtiResourceLinkRequest",
                "target_link_uri" => "https://example.com/launch",
                "label" => "Test Tool"
              }
            ]
          }
        end
        let(:ims_registration) do
          registration = Lti::IMS::Registration.create!(
            developer_key:,
            lti_registration:,
            lti_tool_configuration: config_with_uri,
            client_name: "Test Client",
            initiate_login_uri: "https://example.com/login",
            redirect_uris: ["https://example.com/redirect"],
            jwks_uri: "https://example.com/jwks",
            scopes: []
          )
          registration.update_column(:lti_tool_configuration, config_without_uri)
          registration
        end

        it "does not backfill the target_link_uri" do
          expect(ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
          described_class.run
          ims_registration.reload
          expect(ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
        end
      end
    end

    context "when lti_tool_configuration already has target_link_uri" do
      let(:config) do
        {
          "domain" => "test.portfolio.instructure.com",
          "target_link_uri" => "https://test.portfolio.instructure.com/existing",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://test.portfolio.instructure.com/launch",
              "label" => "Test Tool"
            }
          ]
        }
      end
      let(:ims_registration) do
        Lti::IMS::Registration.create!(
          developer_key:,
          lti_registration:,
          lti_tool_configuration: config,
          client_name: "Test Client",
          initiate_login_uri: "https://test.portfolio.instructure.com/login",
          redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
          jwks_uri: "https://test.portfolio.instructure.com/jwks",
          scopes: []
        )
      end

      it "does not modify the existing target_link_uri" do
        ims_registration
        expect(ims_registration.lti_tool_configuration["target_link_uri"]).to eq("https://test.portfolio.instructure.com/existing")
        described_class.run
        ims_registration.reload
        expect(ims_registration.lti_tool_configuration["target_link_uri"]).to eq("https://test.portfolio.instructure.com/existing")
      end
    end

    context "when messages[0].target_link_uri is missing" do
      let(:config_with_uri) do
        {
          "domain" => "test.portfolio.instructure.com",
          "target_link_uri" => "https://test.portfolio.instructure.com/launch",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "label" => "Test Tool"
            }
          ]
        }
      end
      let(:config_without_uri) do
        {
          "domain" => "test.portfolio.instructure.com",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "label" => "Test Tool"
            }
          ]
        }
      end
      let(:ims_registration) do
        registration = Lti::IMS::Registration.create!(
          developer_key:,
          lti_registration:,
          lti_tool_configuration: config_with_uri,
          client_name: "Test Client",
          initiate_login_uri: "https://test.portfolio.instructure.com/login",
          redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
          jwks_uri: "https://test.portfolio.instructure.com/jwks",
          scopes: []
        )
        registration.update_column(:lti_tool_configuration, config_without_uri)
        registration
      end
      let(:scope) { double("scope") }

      it "skips the registration and notifies Sentry" do
        expect(Sentry).to receive(:with_scope).and_yield(scope)
        expect(scope).to receive(:set_tags).with(lti_ims_registration_id: ims_registration.global_id)
        expect(Sentry).to receive(:capture_message)
          .with("DataFixup#backfill_portfolio_target_link_uri: missing target_link_uri in messages", { level: :warning })

        ims_registration
        expect(ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
        described_class.run
        ims_registration.reload
        expect(ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
      end
    end

    context "when an error occurs during update" do
      let(:config_with_uri) do
        {
          "domain" => "test.portfolio.instructure.com",
          "target_link_uri" => "https://test.portfolio.instructure.com/launch",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://test.portfolio.instructure.com/launch",
              "label" => "Test Tool"
            }
          ]
        }
      end
      let(:config_without_uri) do
        {
          "domain" => "test.portfolio.instructure.com",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://test.portfolio.instructure.com/launch",
              "label" => "Test Tool"
            }
          ]
        }
      end
      let(:ims_registration) do
        registration = Lti::IMS::Registration.create!(
          developer_key:,
          lti_registration:,
          lti_tool_configuration: config_with_uri,
          client_name: "Test Client",
          initiate_login_uri: "https://test.portfolio.instructure.com/login",
          redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
          jwks_uri: "https://test.portfolio.instructure.com/jwks",
          scopes: []
        )
        registration.update_column(:lti_tool_configuration, config_without_uri)
        registration
      end
      let(:scope) { double("scope") }

      it "captures the error using Sentry and continues" do
        expect(Sentry).to receive(:with_scope).and_yield(scope)
        expect(Sentry).to receive(:capture_message)
          .with("DataFixup#backfill_portfolio_target_link_uri", { level: :warning })
        expect(scope).to receive(:set_tags).with(lti_ims_registration_id: ims_registration.global_id)
        expect(scope).to receive(:set_context)
          .with("exception", { name: "StandardError", message: "whoops!" })

        allow_any_instance_of(Lti::IMS::Registration).to receive(:update!).and_raise(StandardError.new("whoops!"))

        ims_registration

        expect { described_class.run }.not_to raise_error
      end
    end

    context "with multiple registrations" do
      let(:config_portfolio_with_uri_1) do
        {
          "domain" => "test.portfolio.instructure.com",
          "target_link_uri" => "https://test.portfolio.instructure.com/launch1",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://test.portfolio.instructure.com/launch1",
              "label" => "Test Tool 1"
            }
          ]
        }
      end
      let(:config_portfolio_without_uri_1) do
        {
          "domain" => "test.portfolio.instructure.com",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://test.portfolio.instructure.com/launch1",
              "label" => "Test Tool 1"
            }
          ]
        }
      end
      let(:config_portfolio_with_uri_2) do
        {
          "domain" => "test2.portfolio.instructure.com",
          "target_link_uri" => "https://test2.portfolio.instructure.com/existing",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://test2.portfolio.instructure.com/launch2",
              "label" => "Test Tool 2"
            }
          ]
        }
      end
      let(:config_non_portfolio_with_uri) do
        {
          "domain" => "example.com",
          "target_link_uri" => "https://example.com/launch3",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://example.com/launch3",
              "label" => "Test Tool 3"
            }
          ]
        }
      end
      let(:config_non_portfolio_without_target) do
        {
          "domain" => "example.com",
          "claims" => [],
          "messages" => [
            {
              "type" => "LtiResourceLinkRequest",
              "target_link_uri" => "https://example.com/launch3",
              "label" => "Test Tool 3"
            }
          ]
        }
      end
      let!(:ims_registration1) do
        registration = Lti::IMS::Registration.create!(
          developer_key:,
          lti_registration:,
          lti_tool_configuration: config_portfolio_with_uri_1,
          client_name: "Test Client 1",
          initiate_login_uri: "https://test.portfolio.instructure.com/login",
          redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
          jwks_uri: "https://test.portfolio.instructure.com/jwks",
          scopes: []
        )
        registration.update_column(:lti_tool_configuration, config_portfolio_without_uri_1)
        registration
      end
      let!(:ims_registration2) do
        developer_key2 = DeveloperKey.create!(account:)
        lti_registration2 = Lti::Registration.create!(account:, developer_key: developer_key2, name: "Test Registration 2")
        Lti::IMS::Registration.create!(
          developer_key: developer_key2,
          lti_registration: lti_registration2,
          lti_tool_configuration: config_portfolio_with_uri_2,
          client_name: "Test Client 2",
          initiate_login_uri: "https://test2.portfolio.instructure.com/login",
          redirect_uris: ["https://test2.portfolio.instructure.com/redirect"],
          jwks_uri: "https://test2.portfolio.instructure.com/jwks",
          scopes: []
        )
      end
      let!(:ims_registration3) do
        developer_key3 = DeveloperKey.create!(account:)
        lti_registration3 = Lti::Registration.create!(account:, developer_key: developer_key3, name: "Test Registration 3")
        registration = Lti::IMS::Registration.create!(
          developer_key: developer_key3,
          lti_registration: lti_registration3,
          lti_tool_configuration: config_non_portfolio_with_uri,
          client_name: "Test Client 3",
          initiate_login_uri: "https://example.com/login",
          redirect_uris: ["https://example.com/redirect"],
          jwks_uri: "https://example.com/jwks",
          scopes: []
        )
        registration.update_column(:lti_tool_configuration, config_non_portfolio_without_target)
        registration
      end

      it "only updates portfolio registrations without target_link_uri" do
        described_class.run
        ims_registration1.reload
        ims_registration2.reload
        ims_registration3.reload
        expect(ims_registration1.lti_tool_configuration["target_link_uri"]).to eq("https://test.portfolio.instructure.com/launch1")
        expect(ims_registration2.lti_tool_configuration["target_link_uri"]).to eq("https://test2.portfolio.instructure.com/existing")
        expect(ims_registration3.lti_tool_configuration["target_link_uri"]).to be_nil
      end

      context "with deleted registration" do
        let!(:deleted_ims_registration) do
          developer_key4 = DeveloperKey.create!(account:)
          lti_registration4 = Lti::Registration.create!(account:, developer_key: developer_key4, name: "Test Registration 4")
          registration = Lti::IMS::Registration.create!(
            developer_key: developer_key4,
            lti_registration: lti_registration4,
            lti_tool_configuration: config_portfolio_with_uri_1,
            client_name: "Test Client 4",
            initiate_login_uri: "https://test.portfolio.instructure.com/login",
            redirect_uris: ["https://test.portfolio.instructure.com/redirect"],
            jwks_uri: "https://test.portfolio.instructure.com/jwks",
            scopes: [],
            workflow_state: "deleted"
          )
          registration.update_column(:lti_tool_configuration, config_portfolio_without_uri_1)
          registration
        end

        it "does not update deleted registrations" do
          described_class.run
          ims_registration1.reload
          ims_registration2.reload
          ims_registration3.reload
          deleted_ims_registration.reload
          expect(ims_registration1.lti_tool_configuration["target_link_uri"]).to eq("https://test.portfolio.instructure.com/launch1")
          expect(deleted_ims_registration.lti_tool_configuration["target_link_uri"]).to be_nil
        end
      end
    end
  end
end
