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

require_relative "../../lti_spec_helper"

describe Lti::AssetProcessorTiiMigrationWorker do
  include LtiSpecHelper

  let(:root_account) { Account.default }
  let(:sub_account) { account_model(parent_account: root_account, root_account:) }
  let(:email) { "test@example.com" }
  let(:worker) { described_class.new(sub_account, email) }

  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: "turnitin.com",
      product_code: "turnitin-lti",
      vendor_name: "TurnItIn",
      vendor_description: "TurnItIn LTI",
      website: "http://www.turnitin.com/",
      vendor_email: "support@turnitin.com",
      root_account:
    )
  end

  let(:tool_proxy) do
    create_tool_proxy(
      context: sub_account,
      product_family:,
      create_binding: true,
      raw_data: {
        "tool_profile" => {
          "service_offered" => [
            {
              "endpoint" => "https://sandbox.turnitin.com/api/v1/service"
            }
          ]
        }
      }
    )
  end

  let(:course) { course_model(account: sub_account) }

  let(:course_tool_proxy) do
    create_tool_proxy(
      context: course,
      product_family:,
      create_binding: true,
      raw_data: tool_proxy.raw_data
    )
  end

  let(:admin_user) { account_admin_user(account: root_account) }

  let(:progress) do
    Progress.create!(
      context: sub_account,
      tag: "lti_tii_ap_migration",
      user: admin_user
    )
  end

  let(:tii_registration) do
    registration = lti_registration_with_tool(
      account: root_account,
      configuration_params: {
        placements: [
          {
            placement: "ActivityAssetProcessor",
            enabled: true,
            message_type: "LtiDeepLinkingRequest",
            target_link_uri: "https://turnitin.example.com/launch"
          }
        ]
      }
    )
    registration&.deployments&.first&.context_controls&.first&.update!(available: false)
    registration
  end

  let(:developer_key) do
    tii_registration.developer_key
  end

  describe "#tool_proxies" do
    it "calls migrate_tool_proxy for each tool proxy" do
      product_family
      tool_proxy
      allow(worker).to receive(:migrate_tool_proxy)

      worker.perform(progress)

      expect(worker).to have_received(:migrate_tool_proxy).with(tool_proxy)
    end

    it "handles multiple tool proxies" do
      tool_proxy
      course_tool_proxy
      root_tp = create_tool_proxy(
        context: course_model(account: root_account),
        product_family:,
        create_binding: true,
        raw_data: tool_proxy.raw_data
      )
      allow(worker).to receive(:migrate_tool_proxy)

      worker.perform(progress)

      expect(worker).to have_received(:migrate_tool_proxy).with(tool_proxy)
      expect(worker).to have_received(:migrate_tool_proxy).with(course_tool_proxy)
      expect(worker).not_to have_received(:migrate_tool_proxy).with(root_tp)
    end

    it "does not migrate TPs of the subtree" do
      product_family
      tool_proxy1 = tool_proxy
      root_worker = described_class.new(root_account, email)
      allow(root_worker).to receive(:migrate_tool_proxy)

      root_worker.perform(progress)

      expect(root_worker).not_to have_received(:migrate_tool_proxy).with(tool_proxy1)
    end
  end

  describe "#migrate_tool_proxy" do
    before do
      Setting.set("turnitin_asset_processor_client_id", developer_key.global_id.to_s)
    end

    it "skips already migrated tool proxies" do
      cet = external_tool_1_3_model(context: sub_account)
      tool_proxy.update!(migrated_to_context_external_tool: cet)
      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, tool_proxy)
      end.not_to change { sub_account.context_external_tools.count }
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:warnings].first).to match(/has already been migrated/)
    end

    it "adds error when multiple deployments found in context hierarchy" do
      # Create two deployments with the same developer key and context controls
      tii_registration.new_external_tool(course)
      tii_registration.new_external_tool(sub_account)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, course_tool_proxy)
      worker.send(:migrate_tool_proxy, course_tool_proxy)

      expect(worker.instance_variable_get(:@results)[course_tool_proxy.id][:errors].first).to match(/Multiple TII AP deployments found/)
    end

    it "adds error when deployment found in parent context but not in tool proxy context" do
      # Create account-level deployment only (not matching course context)
      account_deployment = tii_registration.new_external_tool(sub_account)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, course_tool_proxy)
      worker.send(:migrate_tool_proxy, course_tool_proxy)

      expect(course_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      expect(worker.instance_variable_get(:@results)[course_tool_proxy.id][:errors].first).to match(/but none match the context/)
      expect(worker.instance_variable_get(:@results)[course_tool_proxy.id][:errors].first).to include("CET ID=#{account_deployment.id}")
    end

    it "creates a new account-level deployment when no deployment is found" do
      # Mock tii_tp_migration since we're only testing deployment creation
      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, tool_proxy)
      end.to change { sub_account.context_external_tools.where(lti_registration: tii_registration).count }.by(1)

      created_deployment = sub_account.context_external_tools.where(lti_registration: tii_registration).last
      expect(created_deployment.context).to eq(sub_account)
      expect(created_deployment.developer_key).to eq(developer_key)
      expect(worker).to have_received(:tii_tp_migration).with(tool_proxy, created_deployment)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors]).to be_empty
    end

    it "creates a new deployment when no deployment is found for course-level tool proxy" do
      # Mock tii_tp_migration since we're only testing deployment creation
      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, course_tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, course_tool_proxy)
      end.to change { course.context_external_tools.where(lti_registration: tii_registration).count }.by(1)

      created_deployment = course.context_external_tools.where(lti_registration: tii_registration).last
      expect(created_deployment.context).to eq(course)
      expect(created_deployment.developer_key).to eq(developer_key)
      expect(worker).to have_received(:tii_tp_migration).with(course_tool_proxy, created_deployment)
      expect(worker.instance_variable_get(:@results)[course_tool_proxy.id][:errors]).to be_empty
    end

    it "migrates to existing deployment when exactly one matching deployment is found" do
      # Create deployment in the same context as tool_proxy with available: true
      existing_deployment = tii_registration.new_external_tool(sub_account)
      existing_deployment.context_controls.first.update!(available: true)

      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, tool_proxy)
      end.not_to change { sub_account.context_external_tools.where(lti_registration: tii_registration).count }

      expect(worker).to have_received(:tii_tp_migration).with(tool_proxy, existing_deployment)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors]).to be_empty
    end

    it "adds error and returns early when developer key is not configured" do
      Setting.set("turnitin_asset_processor_client_id", "")

      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)
      worker.send(:migrate_tool_proxy, tool_proxy)

      expect(worker).not_to have_received(:tii_tp_migration)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors].first).to match(/Developer key not found/)
    end

    it "adds error and returns early when developer key is not found in database" do
      Setting.set("turnitin_asset_processor_client_id", "99999999")

      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)
      worker.send(:migrate_tool_proxy, tool_proxy)

      expect(worker).not_to have_received(:tii_tp_migration)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors].first).to match(/Developer key not found/)
    end

    it "adds error and returns early when deployment creation fails with Lti::ContextExternalToolErrors" do
      errors = double("errors", full_messages: ["Duplicate deployment"])
      allow_any_instance_of(Lti::Registration).to receive(:new_external_tool).and_raise(Lti::ContextExternalToolErrors.new(errors))

      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)
      worker.send(:migrate_tool_proxy, tool_proxy)

      expect(worker).not_to have_received(:tii_tp_migration)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors].first).to match(/Failed to create deployment/)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors].first).to include("Duplicate deployment")
    end

    it "adds error and returns early when deployment creation fails with unexpected error" do
      allow_any_instance_of(Lti::Registration).to receive(:new_external_tool).and_raise(StandardError, "Unexpected failure")

      allow(worker).to receive(:tii_tp_migration)

      worker.instance_variable_set(:@progress, progress)
      worker.send(:initialize_results, tool_proxy)
      worker.send(:migrate_tool_proxy, tool_proxy)

      expect(worker).not_to have_received(:tii_tp_migration)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors].first).to match(/Unexpected error creating deployment: Unexpected failure/)
    end
  end

  describe "#tii_tp_migration" do
    let(:deployment) do
      deployment = tii_registration.deployments.first
      deployment.context_controls.first.update!(available: true)
      deployment
    end

    let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }

    before do
      Setting.set("turnitin_asset_processor_client_id", developer_key.global_id.to_s)
      allow(Lti::KeyStorage).to receive(:present_key).and_return(rsa_key)
    end

    it "adds error when migration endpoint cannot be extracted" do
      # Create tool proxy without service_offered endpoint
      bad_tool_proxy = create_tool_proxy(
        context: sub_account,
        product_family:,
        create_binding: true,
        raw_data: { "tool_profile" => {} }
      )

      worker.send(:initialize_results, bad_tool_proxy)
      worker.send(:tii_tp_migration, bad_tool_proxy, deployment)

      expect(bad_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      expect(worker.instance_variable_get(:@results)[bad_tool_proxy.id][:errors].first).to match(/Failed to extract migration endpoint/)
    end

    it "accepts valid turnitin.com endpoint" do
      success_response = double("response", is_a?: true, code: "200", body: "success")
      allow(CanvasHttp).to receive(:post).and_return(success_response)

      worker.send(:initialize_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).with("https://sandbox.turnitin.com/api/migrate", anything, anything)
      expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
    end

    it "accepts valid turnitin.com subdomain endpoint" do
      subdomain_tool_proxy = create_tool_proxy(
        context: sub_account,
        product_family:,
        create_binding: true,
        raw_data: {
          "tool_profile" => {
            "service_offered" => [
              {
                "endpoint" => "https://api.turnitin.com/api/v1/service"
              }
            ]
          }
        }
      )

      success_response = double("response", is_a?: true, code: "200", body: "success")
      allow(CanvasHttp).to receive(:post).and_return(success_response)

      worker.send(:initialize_results, subdomain_tool_proxy)
      worker.send(:tii_tp_migration, subdomain_tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).with("https://api.turnitin.com/api/migrate", anything, anything)
      expect(subdomain_tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
    end

    it "rejects endpoint with invalid domain (not turnitin.com)" do
      invalid_tool_proxy = create_tool_proxy(
        context: sub_account,
        product_family:,
        create_binding: true,
        raw_data: {
          "tool_profile" => {
            "service_offered" => [
              {
                "endpoint" => "https://evil.com/api/v1/service"
              }
            ]
          }
        }
      )

      worker.send(:initialize_results, invalid_tool_proxy)
      worker.send(:tii_tp_migration, invalid_tool_proxy, deployment)

      expect(invalid_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      expect(worker.instance_variable_get(:@results)[invalid_tool_proxy.id][:errors].first).to match(/Failed to extract migration endpoint/)
    end

    it "rejects endpoint with domain ending in turnitin.com but not a subdomain" do
      invalid_tool_proxy = create_tool_proxy(
        context: sub_account,
        product_family:,
        create_binding: true,
        raw_data: {
          "tool_profile" => {
            "service_offered" => [
              {
                "endpoint" => "https://faketurnitin.com/api/v1/service"
              }
            ]
          }
        }
      )

      worker.send(:initialize_results, invalid_tool_proxy)
      worker.send(:tii_tp_migration, invalid_tool_proxy, deployment)

      expect(invalid_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      expect(worker.instance_variable_get(:@results)[invalid_tool_proxy.id][:errors].first).to match(/Failed to extract migration endpoint/)
    end

    it "makes HTTP POST request with correct authorization header and payload" do
      success_response = double("response", is_a?: true, code: "200", body: "success")
      allow(CanvasHttp).to receive(:post).and_return(success_response)

      worker.send(:initialize_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post) do |endpoint, headers, options|
        expect(endpoint).to eq("https://sandbox.turnitin.com/api/migrate")

        expect(headers["Authorization"]).to match(/^Bearer .+/)

        jwt_token = headers["Authorization"].sub("Bearer ", "")
        decoded_jwt = JSON::JWT.decode(jwt_token, rsa_key.public_key)
        expect(decoded_jwt["iss"]).to eq(Canvas::Security.config["lti_iss"])
        expect(decoded_jwt["aud"]).to eq(developer_key.global_id.to_s)
        expect(decoded_jwt["scope"]).to eq("https://turnitin.com/cpf/migrate/deployment")

        expect(options[:content_type]).to eq("application/json")

        payload = JSON.parse(options[:body])
        expect(payload["deployment_id"]).to eq(deployment.deployment_id)
        expect(payload["issuer"]).to eq(Canvas::Security.config["lti_iss"])
        expect(payload["client_id"]).to eq(developer_key.global_id.to_s)
        expect(payload["tool_proxy_id"]).to eq(tool_proxy.guid)
        expect(payload["platform_notification_service_url"]).to include("lti/notice-handlers")
        expect(payload["platform_notification_service_url"]).to include(deployment.id.to_s)
      end

      expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
    end

    it "retries once after 2 seconds on HTTP failure" do
      failure_response = double("response", is_a?: false, code: "500", body: "Internal Server Error")
      success_response = double("response", is_a?: true, code: "200", body: "success")

      allow(CanvasHttp).to receive(:post).and_return(failure_response, success_response)
      allow(worker).to receive(:sleep)

      worker.send(:initialize_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).twice
      expect(worker).to have_received(:sleep).with(2).once
      expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors]).to be_empty
    end

    it "retries once after 2 seconds on exception" do
      success_response = double("response", is_a?: true, code: "200", body: "success")

      call_count = 0
      allow(CanvasHttp).to receive(:post) do
        call_count += 1
        raise Timeout::Error, "Request timeout" if call_count == 1

        success_response
      end
      allow(worker).to receive(:sleep)

      worker.send(:initialize_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).twice
      expect(worker).to have_received(:sleep).with(2).once
      expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
      expect(worker.instance_variable_get(:@results)[tool_proxy.id][:errors]).to be_empty
    end
  end
end
