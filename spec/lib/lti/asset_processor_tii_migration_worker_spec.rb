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

  let(:developer_key) do
    tii_registration.developer_key
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
  let(:test_progress) do
    Progress.create!(
      context: sub_account,
      tag: "lti_tii_ap_migration",
      user: admin_user
    )
  end
  let(:admin_user) { account_admin_user(account: root_account) }
  let(:course_tool_proxy) do
    create_tool_proxy(
      context: course,
      product_family:,
      create_binding: true,
      raw_data: tii_raw_data
    )
  end
  let(:course) { course_model(account: sub_account) }
  let(:tool_proxy) do
    create_tool_proxy(
      context: sub_account,
      product_family:,
      create_binding: true,
      raw_data: tii_raw_data
    )
  end
  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: described_class::TII_TOOL_VENDOR_CODE,
      product_code: described_class::TII_TOOL_PRODUCT_CODE,
      vendor_name: "TurnItIn",
      vendor_description: "TurnItIn LTI",
      website: "http://www.turnitin.com/",
      vendor_email: "support@turnitin.com",
      root_account:
    )
  end
  let(:tii_raw_data) do
    {
      "tool_profile" => {
        "service_offered" => [
          {
            "endpoint" => "https://sandbox.turnitin.com/api/v1/service"
          }
        ]
      },
      "custom" => {
        "proxy_instance_id" => "test-proxy-instance-123"
      }
    }
  end
  let(:worker) { described_class.new(sub_account, email) }
  let(:email) { "test@example.com" }
  let(:sub_account) { account_model(parent_account: root_account, root_account:) }
  let(:root_account) { Account.default }

  describe "constants" do
    it "has correct TurnItIn vendor code" do
      expect(described_class::TII_TOOL_VENDOR_CODE).to eq("turnitin.com")
    end

    it "has correct TurnItIn product code" do
      expect(described_class::TII_TOOL_PRODUCT_CODE).to eq("turnitin-lti")
    end
  end

  describe "#perform" do
    let(:assignment) { assignment_model(course:) }
    let(:resource_handler) do
      Lti::ResourceHandler.create!(
        resource_type_code: "resource",
        name: "Test Resource",
        tool_proxy:
      )
    end
    let(:message_handler) do
      Lti::MessageHandler.create!(
        message_type: "basic-lti-launch-request",
        launch_path: "http://example.com/launch",
        resource_handler:,
        tool_proxy:,
        capabilities: [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2]
      )
    end
    let(:actl) do
      AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
        tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )
    end

    before do
      Setting.set("turnitin_asset_processor_client_id", developer_key.global_id.to_s)
    end

    describe "full migration flow" do
      let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }

      before do
        allow(Lti::KeyStorage).to receive(:present_key).and_return(rsa_key)
      end

      it "successfully migrates tool proxy and creates asset processor" do
        product_family
        actl

        # Mock only the external HTTP call to TurnItIn
        success_response = double("response", is_a?: true, code: "200", body: "success")
        allow(CanvasHttp).to receive(:post).and_return(success_response)

        expect(sub_account.context_external_tools.where(lti_registration: tii_registration).count).to eq(0)
        expect(Lti::AssetProcessor.where(assignment:).count).to eq(0)
        expect(tool_proxy.migrated_to_context_external_tool).to be_nil

        # Perform migration
        worker.perform(test_progress)

        # Verify deployment was created
        deployments = sub_account.context_external_tools.where(lti_registration: tii_registration)
        expect(deployments.count).to eq(1)
        deployment = deployments.first
        expect(deployment.context).to eq(sub_account)
        expect(deployment.developer_key).to eq(developer_key)

        # Verify tool proxy was migrated
        expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)

        # Verify asset processor was created
        asset_processors = Lti::AssetProcessor.where(assignment:)
        expect(asset_processors.count).to eq(1)
        asset_processor = asset_processors.first
        expect(asset_processor.context_external_tool).to eq(deployment)
        expect(asset_processor.assignment).to eq(assignment)
        expect(asset_processor.custom["migrated_from_cpf"]).to eq("true")
        expect(asset_processor.custom["proxy_instance_id"]).to be_present
        expect(asset_processor.migration_id).to eq("cpf_#{tool_proxy.guid}_#{assignment.global_id}")

        # Verify HTTP call was made with correct parameters
        expect(CanvasHttp).to have_received(:post) do |endpoint, headers, options|
          expect(endpoint).to eq("https://sandbox.turnitin.com/api/migrate")
          expect(headers["Authorization"]).to be_present

          payload = JSON.parse(options[:body])
          expect(payload["deployment_id"]).to eq(deployment.deployment_id)
          expect(payload["tool_proxy_id"]).to eq(tool_proxy.guid)
          expect(payload["platform_notification_service_url"]).to include(deployment.id.to_s)
        end

        # Verify progress was updated
        expect(test_progress.results).to be_present
        expect(test_progress.results[:proxies]).to be_present
      end
    end

    describe "tool_proxy migration" do
      it "migrates proxies on account and it's courses" do
        # Create ACTLs for different tool proxies
        actl # Account-level tool proxy ACTL

        course_actl_assignment = assignment_model(course:)
        course_resource_handler = Lti::ResourceHandler.create!(
          resource_type_code: "resource_course",
          name: "Course Resource",
          tool_proxy: course_tool_proxy
        )
        course_message_handler = Lti::MessageHandler.create!(
          message_type: "basic-lti-launch-request",
          launch_path: "http://example.com/launch",
          resource_handler: course_resource_handler,
          tool_proxy: course_tool_proxy,
          capabilities: [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2]
        )
        AssignmentConfigurationToolLookup.create!(
          assignment: course_actl_assignment,
          tool: course_message_handler,
          tool_type: "Lti::MessageHandler",
          tool_id: course_message_handler.id,
          tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
          tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
          tool_resource_type_code: course_resource_handler.resource_type_code,
          context_type: "Course"
        )

        allow(worker).to receive(:migrate_tool_proxy).and_call_original
        allow(worker).to receive(:create_asset_processor_from_actl)

        worker.perform(test_progress)

        expect(worker).to have_received(:migrate_tool_proxy).with(tool_proxy)
        expect(worker).to have_received(:migrate_tool_proxy).with(course_tool_proxy)
      end

      it "does not migrate proxies of the subtree" do
        product_family
        actl # Sub-account ACTL
        root_worker = described_class.new(root_account, email)
        allow(root_worker).to receive(:migrate_tool_proxy)

        root_worker.perform(test_progress)

        expect(root_worker).not_to have_received(:migrate_tool_proxy).with(tool_proxy)
      end

      it "does not migrate proxies on other (e.g. parent) account" do
        root_course = course_model(account: root_account)
        root_tp = create_tool_proxy(
          context: root_course,
          product_family:,
          create_binding: true,
          raw_data: tool_proxy.raw_data
        )
        root_assignment = assignment_model(course: root_course)
        root_resource_handler = Lti::ResourceHandler.create!(
          resource_type_code: "resource_root",
          name: "Root Resource",
          tool_proxy: root_tp
        )
        root_message_handler = Lti::MessageHandler.create!(
          message_type: "basic-lti-launch-request",
          launch_path: "http://example.com/launch",
          resource_handler: root_resource_handler,
          tool_proxy: root_tp,
          capabilities: [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2]
        )
        AssignmentConfigurationToolLookup.create!(
          assignment: root_assignment,
          tool: root_message_handler,
          tool_type: "Lti::MessageHandler",
          tool_id: root_message_handler.id,
          tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
          tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
          tool_resource_type_code: root_resource_handler.resource_type_code,
          context_type: "Course"
        )

        allow(worker).to receive(:migrate_tool_proxy)

        worker.perform(test_progress)

        expect(worker).not_to have_received(:migrate_tool_proxy).with(root_tp)
      end
    end

    describe "Asset Processor creation" do
      it "calls create_asset_processor_from_actl for each ACTL" do
        product_family
        tool_proxy.update!(migrated_to_context_external_tool: external_tool_1_3_model(context: sub_account))
        actl
        allow(worker).to receive(:create_asset_processor_from_actl).and_call_original

        worker.perform(test_progress)

        expect(worker).to have_received(:create_asset_processor_from_actl).with(actl, tool_proxy)
      end

      it "skips Asset Processor creation when CET creation failed for tool proxy" do
        product_family
        actl
        # Simulate prior CET creation failure
        allow(worker).to receive(:migrate_tool_proxy)
        allow(worker).to receive(:create_asset_processor_from_actl)

        worker.perform(test_progress)

        # Manually set cet_creation_failed flag to simulate the scenario
        results = worker.instance_variable_get(:@results)
        results[:proxies][tool_proxy.id][:cet_creation_failed] = true

        # Create another ACTL to test skipping
        assignment2 = assignment_model(course:)
        actl2 = AssignmentConfigurationToolLookup.create!(
          assignment: assignment2,
          tool: message_handler,
          tool_type: "Lti::MessageHandler",
          tool_id: message_handler.id,
          tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
          tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
          tool_resource_type_code: resource_handler.resource_type_code,
          context_type: "Course"
        )

        worker.send(:migrate_actls)

        expect(worker).not_to have_received(:create_asset_processor_from_actl).with(actl2, tool_proxy)
      end

      it "handles exceptions during ACTL migration and continues" do
        product_family
        actl
        tool_proxy.update!(migrated_to_context_external_tool: external_tool_1_3_model(context: sub_account))

        allow(worker).to receive(:create_asset_processor_from_actl).and_raise(StandardError, "Test error")
        allow(Canvas::Errors).to receive(:capture_exception)

        expect do
          worker.perform(test_progress)
        end.not_to raise_error

        expect(Canvas::Errors).to have_received(:capture_exception).with(:tii_migration, anything)
      end
    end

    context "prevalidations" do
      it "fails when developer key is not configured" do
        Setting.set("turnitin_asset_processor_client_id", "")
        product_family
        actl

        allow(worker).to receive(:migrate_tool_proxy)

        worker.perform(test_progress)

        expect(worker).not_to have_received(:migrate_tool_proxy)
        results = worker.instance_variable_get(:@results)
        expect(results[:fatal_error]).to eq("LTI 1.3 Developer key not found")
      end
    end
  end

  describe "#proxy_in_account?" do
    it "returns true when account-level tool proxy matches account" do
      expect(worker.send(:proxy_in_account?, tool_proxy, sub_account)).to be true
    end

    it "returns false when account-level tool proxy doesn't match account" do
      other_account = account_model(parent_account: root_account, root_account:)
      expect(worker.send(:proxy_in_account?, tool_proxy, other_account)).to be false
    end

    it "returns true when course-level tool proxy's course is in account" do
      expect(worker.send(:proxy_in_account?, course_tool_proxy, sub_account)).to be true
    end

    it "returns false when course-level tool proxy's course is not in account" do
      other_account = account_model(parent_account: root_account, root_account:)
      expect(worker.send(:proxy_in_account?, course_tool_proxy, other_account)).to be false
    end
  end

  describe "#sub_account_ids" do
    it "includes the account itself" do
      expect(worker.send(:sub_account_ids)).to include(sub_account.id)
    end

    it "includes sub-accounts recursively" do
      nested_account = account_model(parent_account: sub_account, root_account:)
      expect(worker.send(:sub_account_ids)).to include(nested_account.id)
    end
  end

  describe "#actls_for_account" do
    let(:assignment) { assignment_model(course:) }
    let(:resource_handler) do
      Lti::ResourceHandler.create!(
        resource_type_code: "resource",
        name: "Test Resource",
        tool_proxy:
      )
    end
    let(:message_handler) do
      Lti::MessageHandler.create!(
        message_type: "basic-lti-launch-request",
        launch_path: "http://example.com/launch",
        resource_handler:,
        tool_proxy:
      )
    end

    it "returns ACTLs for turnitin.com vendor code" do
      actl = AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
        tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )

      expect(worker.send(:actls_for_account)).to include(actl)
    end

    it "excludes ACTLs with different vendor codes" do
      actl = AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: "other.com",
        tool_product_code: "other-lti",
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )

      expect(worker.send(:actls_for_account)).not_to include(actl)
    end

    it "excludes ACTLs with deleted assignments" do
      actl = AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
        tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )
      assignment.destroy

      expect(worker.send(:actls_for_account)).not_to include(actl)
    end

    it "excludes ACTLs with deleted courses" do
      actl = AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
        tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )
      course.destroy

      expect(worker.send(:actls_for_account)).not_to include(actl)
    end
  end

  describe "#migrate_tool_proxy" do
    let(:test_progress) do
      Progress.create!(
        context: sub_account,
        tag: "lti_tii_ap_migration",
        user: admin_user
      )
    end

    before do
      Setting.set("turnitin_asset_processor_client_id", developer_key.global_id.to_s)
      # Set @progress instance variable for tests that call migrate_tool_proxy directly
      worker.instance_variable_set(:@progress, test_progress)
    end

    it "adds error when multiple deployments found in context hierarchy" do
      # Create two deployments with the same developer key and context controls
      tii_registration.new_external_tool(course)
      tii_registration.new_external_tool(sub_account)

      worker.send(:initialize_proxy_results, course_tool_proxy)
      worker.send(:migrate_tool_proxy, course_tool_proxy)

      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][course_tool_proxy.id][:errors].first).to match(/Multiple TII AP deployments found/)
    end

    it "adds error when deployment found in parent context but not in tool proxy context" do
      # Create account-level deployment only (not matching course context)
      account_deployment = tii_registration.new_external_tool(sub_account)

      worker.send(:initialize_proxy_results, course_tool_proxy)
      worker.send(:migrate_tool_proxy, course_tool_proxy)

      expect(course_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][course_tool_proxy.id][:errors].first).to match(/but none match the context/)
      expect(results[:proxies][course_tool_proxy.id][:errors].first).to include("CET ID=#{account_deployment.id}")
    end

    it "creates a new account-level deployment when no deployment is found" do
      # Mock tii_tp_migration since we're only testing deployment creation
      allow(worker).to receive(:tii_tp_migration)

      worker.send(:initialize_proxy_results, tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, tool_proxy)
      end.to change { sub_account.context_external_tools.where(lti_registration: tii_registration).count }.by(1)

      created_deployment = sub_account.context_external_tools.where(lti_registration: tii_registration).last
      expect(created_deployment.context).to eq(sub_account)
      expect(created_deployment.developer_key).to eq(developer_key)
      expect(worker).to have_received(:tii_tp_migration).with(tool_proxy, created_deployment)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors]).to be_empty
    end

    it "creates a new deployment when no deployment is found for course-level tool proxy" do
      # Mock tii_tp_migration since we're only testing deployment creation
      allow(worker).to receive(:tii_tp_migration)

      worker.send(:initialize_proxy_results, course_tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, course_tool_proxy)
      end.to change { course.context_external_tools.where(lti_registration: tii_registration).count }.by(1)

      created_deployment = course.context_external_tools.where(lti_registration: tii_registration).last
      expect(created_deployment.context).to eq(course)
      expect(created_deployment.developer_key).to eq(developer_key)
      expect(worker).to have_received(:tii_tp_migration).with(course_tool_proxy, created_deployment)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][course_tool_proxy.id][:errors]).to be_empty
    end

    it "migrates to existing deployment when exactly one matching deployment is found" do
      # Create deployment in the same context as tool_proxy with available: true
      existing_deployment = tii_registration.new_external_tool(sub_account)
      existing_deployment.context_controls.first.update!(available: true)

      allow(worker).to receive(:tii_tp_migration)

      worker.send(:initialize_proxy_results, tool_proxy)

      expect do
        worker.send(:migrate_tool_proxy, tool_proxy)
      end.not_to change { sub_account.context_external_tools.where(lti_registration: tii_registration).count }

      expect(worker).to have_received(:tii_tp_migration).with(tool_proxy, existing_deployment)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors]).to be_empty
    end

    it "adds error and returns early when deployment creation fails with Lti::ContextExternalToolErrors" do
      errors = double("errors", full_messages: ["Duplicate deployment"])
      allow_any_instance_of(Lti::Registration).to receive(:new_external_tool).and_raise(Lti::ContextExternalToolErrors.new(errors))

      allow(worker).to receive(:tii_tp_migration)

      worker.send(:initialize_proxy_results, tool_proxy)
      worker.send(:migrate_tool_proxy, tool_proxy)

      expect(worker).not_to have_received(:tii_tp_migration)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors].first).to match(/Failed to create deployment/)
      expect(results[:proxies][tool_proxy.id][:errors].first).to include("Duplicate deployment")
    end

    it "adds error and returns early when deployment creation fails with unexpected error" do
      allow_any_instance_of(Lti::Registration).to receive(:new_external_tool).and_raise(StandardError, "Unexpected failure")

      allow(worker).to receive(:tii_tp_migration)

      worker.send(:initialize_proxy_results, tool_proxy)
      worker.send(:migrate_tool_proxy, tool_proxy)

      expect(worker).not_to have_received(:tii_tp_migration)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors].first).to match(/Unexpected error creating deployment for Tool Proxy ID=.*: Unexpected failure/)
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

      worker.send(:initialize_proxy_results, bad_tool_proxy)
      worker.send(:tii_tp_migration, bad_tool_proxy, deployment)

      expect(bad_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][bad_tool_proxy.id][:errors].first).to match(/Failed to extract migration endpoint/)
    end

    it "accepts valid turnitin.com endpoint" do
      success_response = double("response", is_a?: true, code: "200", body: "success")
      allow(CanvasHttp).to receive(:post).and_return(success_response)

      worker.send(:initialize_proxy_results, tool_proxy)
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

      worker.send(:initialize_proxy_results, subdomain_tool_proxy)
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

      worker.send(:initialize_proxy_results, invalid_tool_proxy)
      worker.send(:tii_tp_migration, invalid_tool_proxy, deployment)

      expect(invalid_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][invalid_tool_proxy.id][:errors].first).to match(/Failed to extract migration endpoint/)
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

      worker.send(:initialize_proxy_results, invalid_tool_proxy)
      worker.send(:tii_tp_migration, invalid_tool_proxy, deployment)

      expect(invalid_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][invalid_tool_proxy.id][:errors].first).to match(/Failed to extract migration endpoint/)
    end

    it "makes HTTP POST request with correct authorization header and payload" do
      success_response = double("response", is_a?: true, code: "200", body: "success")
      allow(CanvasHttp).to receive(:post).and_return(success_response)

      worker.send(:initialize_proxy_results, tool_proxy)
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

      worker.send(:initialize_proxy_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).twice
      expect(worker).to have_received(:sleep).with(2).once
      expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors]).to be_empty
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

      worker.send(:initialize_proxy_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).twice
      expect(worker).to have_received(:sleep).with(2).once
      expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors]).to be_empty
    end

    it "logs error and returns false after max retries" do
      failure_response = double("response", is_a?: false, code: "500", body: "Internal Server Error")

      allow(CanvasHttp).to receive(:post).and_return(failure_response)
      allow(worker).to receive(:sleep)
      allow(Canvas::Errors).to receive(:capture_exception)

      worker.send(:initialize_proxy_results, tool_proxy)
      worker.send(:tii_tp_migration, tool_proxy, deployment)

      expect(CanvasHttp).to have_received(:post).twice
      expect(worker).to have_received(:sleep).with(2).once
      expect(tool_proxy.reload.migrated_to_context_external_tool).to be_nil
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][tool_proxy.id][:errors].first).to match(/HTTP 500/)
    end
  end

  describe "#create_asset_processor_from_actl" do
    let(:test_course) { course_model(account: sub_account) }
    let(:test_assignment) { assignment_model(course: test_course) }
    let(:test_product_family) do
      Lti::ProductFamily.create!(
        vendor_code: described_class::TII_TOOL_VENDOR_CODE,
        product_code: described_class::TII_TOOL_PRODUCT_CODE,
        vendor_name: "TurnItIn",
        root_account: sub_account
      )
    end
    let(:test_tool_proxy) do
      create_tool_proxy(
        context: test_course,
        product_family: test_product_family,
        create_binding: true,
        raw_data: { "custom" => { "proxy_instance_id" => "test_proxy_123" } }
      )
    end
    let(:resource_handler) do
      Lti::ResourceHandler.create!(
        resource_type_code: "resource",
        name: "Test Resource",
        tool_proxy: test_tool_proxy
      )
    end
    let(:message_handler) do
      Lti::MessageHandler.create!(
        message_type: "basic-lti-launch-request",
        launch_path: "http://example.com/launch",
        resource_handler:,
        tool_proxy: test_tool_proxy
      )
    end
    let(:actl) do
      AssignmentConfigurationToolLookup.create!(
        assignment: test_assignment,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: test_product_family.vendor_code,
        tool_product_code: test_product_family.product_code,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )
    end
    let(:ap_tool) do
      test_course.context_external_tools.create!(
        name: "Asset Processor Tool",
        domain: "example.com",
        consumer_key: "key",
        shared_secret: "secret"
      )
    end

    before do
      # Set up test_tool_proxy as migrated
      test_tool_proxy.update!(migrated_to_context_external_tool: ap_tool)
      worker.send(:initialize_proxy_results, test_tool_proxy)
    end

    it "creates an AssetProcessor with correct attributes" do
      asset_processor = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

      expect(asset_processor).to be_a(Lti::AssetProcessor)
      expect(asset_processor).to be_persisted
      expect(asset_processor.title).to be_nil
      expect(asset_processor.text).to be_nil
      expect(asset_processor.assignment).to eq(test_assignment)
      expect(asset_processor.context_external_tool).to eq(ap_tool)
    end

    it "sets custom params with proxy_instance_id" do
      worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

      asset_processor = Lti::AssetProcessor.last
      expect(asset_processor.custom).to be_a(Hash)
      expect(asset_processor.custom["proxy_instance_id"]).to eq("test_proxy_123")
    end

    it "sets migrated_from_cpf flag" do
      worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

      asset_processor = Lti::AssetProcessor.last
      expect(asset_processor.custom["migrated_from_cpf"]).to eq("true")
    end

    it "creates migration_id from tool_proxy guid and assignment global_id" do
      worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

      asset_processor = Lti::AssetProcessor.last
      expected_migration_id = "cpf_#{test_tool_proxy.guid}_#{test_assignment.global_id}"
      expect(asset_processor.migration_id).to eq(expected_migration_id)
    end

    context "when tool_proxy has no proxy_instance_id in custom" do
      let(:test_tool_proxy) do
        create_tool_proxy(
          context: test_course,
          product_family: test_product_family,
          create_binding: true,
          raw_data: { "enabled_capability" => [] }
        )
      end

      it "creates AssetProcessor with nil proxy_instance_id" do
        worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

        asset_processor = Lti::AssetProcessor.last
        expect(asset_processor).to be_persisted
        expect(asset_processor.custom["proxy_instance_id"]).to be_nil
      end
    end

    it "saves the AssetProcessor to the database" do
      expect do
        worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)
      end.to change(Lti::AssetProcessor, :count).by(1)
      asset_processor = Lti::AssetProcessor.last
      expect(test_assignment.reload.lti_asset_processors).to include(asset_processor)
      expect(ap_tool.reload.lti_asset_processors).to include(asset_processor)
    end

    context "when tool_proxy has not been migrated" do
      let(:unmigrated_tool_proxy) do
        create_tool_proxy(
          context: test_course,
          product_family: test_product_family,
          create_binding: true,
          raw_data: { "custom" => { "proxy_instance_id" => "test_proxy_123" } }
        )
      end
      let(:unmigrated_resource_handler) do
        Lti::ResourceHandler.create!(
          resource_type_code: "resource_unmigrated",
          name: "Unmigrated Resource",
          tool_proxy: unmigrated_tool_proxy
        )
      end
      let(:message_handler_unmigrated) do
        Lti::MessageHandler.create!(
          message_type: "basic-lti-launch-request",
          launch_path: "http://example.com/launch",
          resource_handler: unmigrated_resource_handler,
          tool_proxy: unmigrated_tool_proxy
        )
      end
      let(:actl_unmigrated) do
        AssignmentConfigurationToolLookup.create!(
          assignment: test_assignment,
          tool: message_handler_unmigrated,
          tool_type: "Lti::MessageHandler",
          tool_id: message_handler_unmigrated.id,
          tool_vendor_code: test_product_family.vendor_code,
          tool_product_code: test_product_family.product_code,
          tool_resource_type_code: unmigrated_resource_handler.resource_type_code,
          context_type: "Course"
        )
      end

      it "returns early without creating asset processor" do
        worker.send(:initialize_proxy_results, unmigrated_tool_proxy)
        result = worker.send(:create_asset_processor_from_actl, actl_unmigrated, unmigrated_tool_proxy)

        expect(result).to be_nil
        expect(Lti::AssetProcessor.count).to eq(0)
      end
    end

    context "when asset processor already exists for ACTL" do
      it "skips creation and returns existing asset processor" do
        # Create the asset processor first
        first_ap = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

        # Try to create again
        second_ap = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

        expect(second_ap).to eq(first_ap)
        expect(Lti::AssetProcessor.count).to eq(1)
      end
    end

    context "when save fails" do
      it "logs error and returns nil" do
        allow_any_instance_of(Lti::AssetProcessor).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        allow(Canvas::Errors).to receive(:capture_exception)

        result = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)

        expect(result).to be_nil
        results = worker.instance_variable_get(:@results)
        expect(results[:proxies][test_tool_proxy.id][:errors].first).to match(/Failed to create Asset Processor/)
        expect(Canvas::Errors).to have_received(:capture_exception).with(:tii_migration, anything)
      end
    end
  end

  describe "result tracking methods" do
    let(:test_progress) do
      Progress.create!(
        context: sub_account,
        tag: "lti_tii_ap_migration",
        user: admin_user
      )
    end

    before do
      worker.instance_variable_set(:@progress, test_progress)
    end

    describe "#initialize_proxy_results" do
      it "initializes results hash for tool proxy" do
        worker.send(:initialize_proxy_results, tool_proxy)

        results = worker.instance_variable_get(:@results)
        expect(results[:proxies][tool_proxy.id]).to eq({ errors: [], warnings: [] })
      end

      it "does not overwrite existing results" do
        worker.send(:initialize_proxy_results, tool_proxy)
        results = worker.instance_variable_get(:@results)
        results[:proxies][tool_proxy.id][:errors] << "existing error"

        worker.send(:initialize_proxy_results, tool_proxy)

        expect(results[:proxies][tool_proxy.id][:errors]).to eq(["existing error"])
      end
    end

    describe "#log_proxy_error" do
      it "adds error to proxy results" do
        worker.send(:initialize_proxy_results, tool_proxy)
        worker.send(:log_proxy_error, tool_proxy, "Test error")

        results = worker.instance_variable_get(:@results)
        expect(results[:proxies][tool_proxy.id][:errors]).to include("Test error")
      end
    end

    describe "#log_proxy_warning" do
      it "adds warning to proxy results" do
        worker.send(:initialize_proxy_results, tool_proxy)
        worker.send(:log_proxy_warning, tool_proxy, "Test warning")

        results = worker.instance_variable_get(:@results)
        expect(results[:proxies][tool_proxy.id][:warnings]).to include("Test warning")
      end
    end

    describe "#get_proxy_result and #set_proxy_result" do
      it "gets and sets custom result keys" do
        worker.send(:initialize_proxy_results, tool_proxy)
        worker.send(:set_proxy_result, tool_proxy, :custom_key, "custom_value")

        result = worker.send(:get_proxy_result, tool_proxy, :custom_key)
        expect(result).to eq("custom_value")
      end
    end

    describe "#proxy_errors" do
      it "returns errors for tool proxy" do
        worker.send(:initialize_proxy_results, tool_proxy)
        worker.send(:log_proxy_error, tool_proxy, "Error 1")
        worker.send(:log_proxy_error, tool_proxy, "Error 2")

        errors = worker.send(:proxy_errors, tool_proxy)
        expect(errors).to eq(["Error 1", "Error 2"])
      end
    end
  end

  describe "#tii_developer_key" do
    let(:test_progress) do
      Progress.create!(
        context: sub_account,
        tag: "lti_tii_ap_migration",
        user: admin_user
      )
    end

    before do
      Setting.set("turnitin_asset_processor_client_id", developer_key.global_id.to_s)
      worker.instance_variable_set(:@progress, test_progress)
    end

    it "caches developer key lookup" do
      expect(DeveloperKey).to receive(:find).once.and_return(developer_key)

      worker.send(:tii_developer_key)
      worker.send(:tii_developer_key) # Should use cached value
    end

    it "returns nil when setting is blank" do
      Setting.set("turnitin_asset_processor_client_id", "")

      expect(worker.send(:tii_developer_key)).to be_nil
    end

    it "returns nil and logs warning when developer key not found" do
      Setting.set("turnitin_asset_processor_client_id", "99999999")

      expect(worker.send(:tii_developer_key)).to be_nil
    end
  end

  describe "#construct_pns_url" do
    it "constructs PNS URL with correct parameters" do
      deployment = tii_registration.new_external_tool(sub_account)

      pns_url = worker.send(:construct_pns_url, deployment)

      expect(pns_url).to include("lti/notice-handlers")
      expect(pns_url).to include(deployment.id.to_s)
      expect(pns_url).to include(root_account.environment_specific_domain)
    end
  end

  describe "#generate_migration_jwt" do
    let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }

    before do
      allow(Lti::KeyStorage).to receive(:present_key).and_return(rsa_key)
    end

    it "generates JWT with correct claims" do
      issuer = Canvas::Security.config["lti_iss"]
      client_id = developer_key.global_id.to_s

      jwt = worker.send(:generate_migration_jwt, issuer:, client_id:)
      decoded = JSON::JWT.decode(jwt, rsa_key.public_key)

      expect(decoded["iss"]).to eq(issuer)
      expect(decoded["aud"]).to eq(client_id)
      expect(decoded["scope"]).to eq("https://turnitin.com/cpf/migrate/deployment")
      expect(decoded["iat"]).to be_present
      expect(decoded["exp"]).to be_present
    end
  end
end
