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
    progress = Progress.create!(
      context: sub_account,
      tag: "lti_tii_ap_migration",
      user: admin_user
    )
    progress.start! # because progress.process_job calls start!
    progress
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
        tool_proxy.update_columns(subscription_id: "test-subscription-123")
        actl
        success_response = double("response", is_a?: true, code: "200", body: "success")
        allow(CanvasHttp).to receive(:post).and_return(success_response)
        expect(sub_account.context_external_tools.where(lti_registration: tii_registration).count).to eq(0)
        expect(Lti::AssetProcessor.where(assignment:).count).to eq(0)
        expect(tool_proxy.migrated_to_context_external_tool).to be_nil

        worker.perform(test_progress)

        deployments = sub_account.context_external_tools.where(lti_registration: tii_registration)
        expect(deployments.count).to eq(1)
        deployment = deployments.first
        expect(deployment.context).to eq(sub_account)
        expect(deployment.developer_key).to eq(developer_key)

        expect(tool_proxy.reload.migrated_to_context_external_tool_id).to eq(deployment.id)

        asset_processors = Lti::AssetProcessor.where(assignment:)
        expect(asset_processors.count).to eq(1)
        asset_processor = asset_processors.first
        expect(asset_processor.context_external_tool).to eq(deployment)
        expect(asset_processor.assignment).to eq(assignment)
        expect(asset_processor.custom["migrated_from_cpf"]).to eq("true")
        expect(asset_processor.custom["proxy_instance_id"]).to be_present
        expect(asset_processor.migration_id).to eq("cpf_#{tool_proxy.guid}_#{assignment.global_id}")

        expect(CanvasHttp).to have_received(:post) do |endpoint, headers, options|
          expect(endpoint).to eq("https://sandbox.turnitin.com/api/migrate")
          expect(headers["Authorization"]).to be_present
          payload = JSON.parse(options[:body])
          expect(payload["deployment_id"]).to eq(deployment.deployment_id)
          expect(payload["tool_proxy_id"]).to eq(tool_proxy.guid)
          expect(payload["platform_notification_service_url"]).to include(deployment.id.to_s)
        end

        expect(test_progress.results).to be_present
        expect(test_progress.results[:proxies]).to be_present
        expect(test_progress).to be_completed

        expect(tool_proxy.reload.subscription_id).to be_nil
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
        # Call migrate_actls with a CSV object
        CSV.generate do |csv|
          csv << ["Header1", "Header2"]
          worker.send(:migrate_actls, csv)
        end
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
        expect(Canvas::Errors).to have_received(:capture_exception).with(:tii_migration, anything).at_least(:once)
      end
    end

    describe "CSV report generation" do
      it "reports successful migration with all fields populated" do
        product_family
        tool_proxy.update!(migrated_to_context_external_tool: external_tool_1_3_model(context: sub_account))
        actl

        worker.perform(test_progress)
        csv_content = worker.instance_variable_get(:@csv_content)

        expect(csv_content).to be_present
        csv_rows = CSV.parse(csv_content)
        expect(csv_rows.length).to eq(2) # Header + 1 data row

        # Check header
        expect(csv_rows[0]).to eq(["Account ID",
                                   "Account Name",
                                   "Assignment ID",
                                   "Assignment Name",
                                   "Course ID",
                                   "Tool Proxy ID",
                                   "Lti 1.3 Tool ID",
                                   "Asset Processor Migration",
                                   "Asset Report Migration",
                                   "Number of Reports Migrated",
                                   "Error Message",
                                   "Warnings"])

        # Check data row
        data_row = csv_rows[1]
        expect(data_row[0]).to eq(assignment.course.account.id.to_s)
        expect(data_row[1]).to eq(assignment.course.account.name)
        expect(data_row[2]).to eq(assignment.id.to_s)
        expect(data_row[3]).to eq(assignment.name)
        expect(data_row[4]).to eq(course.id.to_s)
        expect(data_row[5]).to eq(tool_proxy.id.to_s)
        expect(data_row[6]).to be_present
        expect(data_row[7]).to eq("created")
        expect(data_row[8]).to eq("success")
        expect(data_row[9]).to eq("0")
        expect(data_row[10]).to eq("")
      end

      it "reports assignments skipped due to cet_creation_failed with proper status" do
        product_family
        actl

        assignment2 = assignment_model(course:)
        AssignmentConfigurationToolLookup.create!(
          assignment: assignment2,
          tool: message_handler,
          tool_type: "Lti::MessageHandler",
          tool_id: message_handler.id,
          tool_vendor_code: described_class::TII_TOOL_VENDOR_CODE,
          tool_product_code: described_class::TII_TOOL_PRODUCT_CODE,
          tool_resource_type_code: resource_handler.resource_type_code,
          context_type: "Course"
        )

        allow(worker).to receive(:find_tii_asset_processor_deployments).and_raise(StandardError, "Simulated deployment lookup error")

        worker.perform(test_progress)
        csv_content = worker.instance_variable_get(:@csv_content)

        expect(csv_content).to be_present
        csv_rows = CSV.parse(csv_content)
        expect(csv_rows.length).to eq(3) # Header + 2 data rows

        first_item = csv_rows[1]
        expect(first_item[0]).to eq(sub_account.id.to_s)
        expect(first_item[1]).to eq(sub_account.name)
        expect(first_item[2]).to eq(assignment.id.to_s)
        expect(first_item[7]).to eq("failed")
        expect(first_item[8]).to eq("failed")
        expect(first_item[10]).to include("Unexpected error when migrating Tool Proxy")

        second_item = csv_rows[2]
        expect(second_item[0]).to eq(sub_account.id.to_s)
        expect(second_item[1]).to eq(sub_account.name)
        expect(second_item[2]).to eq(assignment2.id.to_s)
        expect(second_item[7]).to eq("failed")
        expect(second_item[8]).to eq("failed")
        expect(second_item[9]).to eq("0")
        expect(second_item[10]).to include("Unexpected error when migrating Tool Proxy")
      end
    end

    describe "progress status" do
      it "marks progress as completed when migration succeeds without errors" do
        product_family
        tool_proxy.update!(migrated_to_context_external_tool: external_tool_1_3_model(context: sub_account))
        actl

        worker.perform(test_progress)

        expect(test_progress).to be_completed
        expect(test_progress).not_to be_failed
      end

      it "marks progress as failed when fatal error occurs" do
        Setting.set("turnitin_asset_processor_client_id", "")
        product_family
        actl

        worker.perform(test_progress)

        expect(test_progress).to be_failed
        expect(test_progress).not_to be_completed
      end

      it "marks progress as failed when tool proxy migration has errors" do
        product_family
        tool_proxy.update_columns(subscription_id: "test-subscription-789")
        actl
        allow(worker).to receive(:find_tii_asset_processor_deployments).and_raise(StandardError, "Deployment error")

        worker.perform(test_progress)

        expect(test_progress).to be_failed
        expect(test_progress).not_to be_completed
        expect(tool_proxy.reload.subscription_id).to eq("test-subscription-789")
      end

      it "marks progress as failed when unexpected exception occurs during migration" do
        product_family
        actl
        allow(worker).to receive(:create_asset_processor_from_actl).and_raise(RuntimeError, "Unexpected error")
        allow(Canvas::Errors).to receive(:capture_exception)

        worker.perform(test_progress)

        expect(test_progress).to be_failed
        expect(test_progress).not_to be_completed
        expect(Canvas::Errors).to have_received(:capture_exception).with(:tii_migration, anything).at_least(:once)
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

    it "throws error when multiple deployments found in the context" do
      # Create two deployments with the same developer key and context controls
      tii_registration.new_external_tool(course)
      tii_registration.new_external_tool(course)
      worker.send(:initialize_proxy_results, course_tool_proxy)
      worker.send(:migrate_tool_proxy, course_tool_proxy)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][course_tool_proxy.id][:errors].first).to match(/Multiple TII AP deployments found/)
    end

    it "throws no error when multiple deployments found in context hierarchy, but only one is matching the context" do
      # Create two deployments with the same developer key and context controls
      tii_registration.new_external_tool(course)
      tii_registration.new_external_tool(sub_account)
      allow(worker).to receive(:tii_tp_migration)
      worker.send(:initialize_proxy_results, course_tool_proxy)
      worker.send(:migrate_tool_proxy, course_tool_proxy)
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][course_tool_proxy.id][:errors]).to be_empty
    end

    it "creates new deployment when deployment found in parent context but not in tool proxy context" do
      # Create account-level deployment only (not matching course context)
      tii_registration.new_external_tool(sub_account)
      allow(worker).to receive(:tii_tp_migration)
      worker.send(:initialize_proxy_results, course_tool_proxy)

      worker.send(:migrate_tool_proxy, course_tool_proxy)

      newcet = course_tool_proxy.context.context_external_tools.where(lti_registration: tii_registration).last
      expect(newcet).not_to be_nil
      results = worker.instance_variable_get(:@results)
      expect(results[:proxies][course_tool_proxy.id][:errors]).to be_empty
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
      status, asset_processor = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)
      expect(status).to eq(:created)
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
        status, asset_processor = worker.send(:create_asset_processor_from_actl, actl_unmigrated, unmigrated_tool_proxy)
        expect(status).to eq(:failed)
        expect(asset_processor).to be_nil
        expect(Lti::AssetProcessor.count).to eq(0)
      end
    end

    context "when asset processor already exists for ACTL" do
      it "skips creation and returns existing asset processor" do
        # Create the asset processor first
        first_status, first_ap = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)
        expect(first_status).to eq(:created)
        # Try to create again
        second_status, second_ap = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)
        expect(second_status).to eq(:existing)
        expect(second_ap).to eq(first_ap)
        expect(Lti::AssetProcessor.count).to eq(1)
      end
    end

    context "when save fails" do
      it "logs error and returns nil" do
        allow_any_instance_of(Lti::AssetProcessor).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        allow(Canvas::Errors).to receive(:capture_exception)
        status, asset_processor = worker.send(:create_asset_processor_from_actl, actl, test_tool_proxy)
        expect(status).to eq(:failed)
        expect(asset_processor).to be_nil
        results = worker.instance_variable_get(:@results)
        expect(results[:actl_errors][actl.id].first).to match(/Failed to create Asset Processor/)
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

    describe "#add_proxy_error" do
      it "adds error to proxy results" do
        worker.send(:initialize_proxy_results, tool_proxy)
        worker.send(:add_proxy_error, tool_proxy, "Test error")
        results = worker.instance_variable_get(:@results)
        expect(results[:proxies][tool_proxy.id][:errors]).to include("Test error")
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
        worker.send(:add_proxy_error, tool_proxy, "Error 1")
        worker.send(:add_proxy_error, tool_proxy, "Error 2")
        errors = worker.send(:proxy_errors, tool_proxy)
        expect(errors).to eq(["Error 1", "Error 2"])
      end
    end

    describe "#capture_and_log_exception" do
      it "captures exception and stores error report ID when present" do
        exception = StandardError.new("Test error")
        error_report_id = 12_345
        allow(Canvas::Errors).to receive(:capture_exception).and_return({ error_report: error_report_id })

        worker.send(:capture_and_log_exception, exception)

        results = worker.instance_variable_get(:@results)
        expect(results[:error_report_ids]).to eq([error_report_id])
        expect(Canvas::Errors).to have_received(:capture_exception).with(:tii_migration, exception)
      end

      it "handles multiple exceptions and stores all error report IDs" do
        exception1 = StandardError.new("Error 1")
        exception2 = StandardError.new("Error 2")
        allow(Canvas::Errors).to receive(:capture_exception).and_return({ error_report: 111 }, { error_report: 222 })

        worker.send(:capture_and_log_exception, exception1)
        worker.send(:capture_and_log_exception, exception2)

        results = worker.instance_variable_get(:@results)
        expect(results[:error_report_ids]).to eq([111, 222])
      end

      it "does not store error report ID when not present in response" do
        exception = StandardError.new("Test error")
        allow(Canvas::Errors).to receive(:capture_exception).and_return({})

        worker.send(:capture_and_log_exception, exception)

        results = worker.instance_variable_get(:@results)
        expect(results[:error_report_ids]).to be_nil
      end

      it "handles non-hash return values gracefully" do
        exception = StandardError.new("Test error")
        allow(Canvas::Errors).to receive(:capture_exception).and_return(nil)

        expect do
          worker.send(:capture_and_log_exception, exception)
        end.not_to raise_error

        results = worker.instance_variable_get(:@results)
        expect(results[:error_report_ids]).to be_nil
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

  describe "#send_migration_report_email" do
    it "sends email when email is provided and report URL exists" do
      download_url = "https://example.com/accounts/#{sub_account.id}/files/123/download"

      results = worker.instance_variable_get(:@results)
      results[:migration_report_url] = download_url
      # Ensure no errors in results
      results[:proxies] = {}

      mailer_instance = double("mailer")
      expect(Mailer).to receive(:create_message) do |message|
        expect(message.to).to eq(email)
        expect(message.subject).to eq("Turnitin Asset Processor Migration Report")
        expect(message.body).to include("Turnitin migration from LTI 2.0 to LTI 1.3")
        expect(message.body).to include(sub_account.name)
        expect(message.body).to include(download_url)
        mailer_instance
      end
      expect(Mailer).to receive(:deliver).with(mailer_instance)

      worker.send(:send_migration_report_email)
    end

    it "sends success email body when migration completes without errors" do
      download_url = "https://example.com/accounts/#{sub_account.id}/files/123/download"

      results = worker.instance_variable_get(:@results)
      results[:migration_report_url] = download_url
      # Ensure no errors in results
      results[:proxies] = {}

      mailer_instance = double("mailer")
      expect(Mailer).to receive(:create_message) do |message|
        expect(message.body).to include("completed successfully")
        expect(message.body).to include("Turnitin migration from LTI 2.0 to LTI 1.3")
        expect(message.body).not_to include("with errors")
        mailer_instance
      end
      expect(Mailer).to receive(:deliver).with(mailer_instance)

      worker.send(:send_migration_report_email)
    end

    it "sends failure email body when migration completes with errors" do
      download_url = "https://example.com/accounts/#{sub_account.id}/files/123/download"

      results = worker.instance_variable_get(:@results)
      results[:migration_report_url] = download_url
      # Add errors to results
      results[:proxies] = { 123 => { errors: ["Test error"] } }

      mailer_instance = double("mailer")
      expect(Mailer).to receive(:create_message) do |message|
        expect(message.body).to include("completed with errors")
        expect(message.body).to include("Turnitin migration from LTI 2.0 to LTI 1.3")
        expect(message.body).not_to include("successfully")
        mailer_instance
      end
      expect(Mailer).to receive(:deliver).with(mailer_instance)

      worker.send(:send_migration_report_email)
    end

    it "does not send email when email is blank" do
      no_email_worker = described_class.new(sub_account, nil)
      results = no_email_worker.instance_variable_get(:@results)
      results[:migration_report_url] = "https://example.com/report"

      expect(Mailer).not_to receive(:deliver)
      no_email_worker.send(:send_migration_report_email)
    end

    it "does not send email when report URL is missing" do
      # Don't set migration_report_url
      expect(Mailer).not_to receive(:deliver)
      worker.send(:send_migration_report_email)
    end

    it "handles exceptions gracefully" do
      results = worker.instance_variable_get(:@results)
      results[:migration_report_url] = "https://example.com/report"

      allow(Mailer).to receive(:deliver).and_raise(StandardError, "Test error")
      allow(Canvas::Errors).to receive(:capture_exception)

      expect do
        worker.send(:send_migration_report_email)
      end.not_to raise_error

      expect(Canvas::Errors).to have_received(:capture_exception).with(:tii_migration, anything)
    end
  end

  describe "#success_email_body" do
    it "generates success email body with correct content" do
      download_url = "https://example.com/download/123"
      body = worker.send(:success_email_body, download_url)

      expect(body).to include("Turnitin migration from LTI 2.0 to LTI 1.3")
      expect(body).to include("completed successfully")
      expect(body).to include(sub_account.name)
      expect(body).to include(download_url)
      expect(body).not_to include("with errors")
    end
  end

  describe "#failure_email_body" do
    it "generates failure email body with correct content" do
      download_url = "https://example.com/download/123"
      body = worker.send(:failure_email_body, download_url)

      expect(body).to include("Turnitin migration from LTI 2.0 to LTI 1.3")
      expect(body).to include("completed with errors")
      expect(body).to include(sub_account.name)
      expect(body).to include(download_url)
      expect(body).not_to include("successfully")
    end
  end

  describe "#any_error_occurred?" do
    it "returns false when no errors present" do
      results = worker.instance_variable_get(:@results)
      results[:proxies] = {}

      expect(worker.send(:any_error_occurred?)).to be false
    end

    it "returns true when fatal error present" do
      results = worker.instance_variable_get(:@results)
      results[:fatal_error] = "Critical error"
      results[:proxies] = {}

      expect(worker.send(:any_error_occurred?)).to be true
    end

    it "returns true when proxy errors present" do
      results = worker.instance_variable_get(:@results)
      results[:proxies] = { 123 => { errors: ["Test error"] } }

      expect(worker.send(:any_error_occurred?)).to be true
    end

    it "returns false when proxies have empty error arrays" do
      results = worker.instance_variable_get(:@results)
      results[:proxies] = { 123 => { errors: [] } }

      expect(worker.send(:any_error_occurred?)).to be false
    end

    it "returns true when any proxy has errors" do
      results = worker.instance_variable_get(:@results)
      results[:proxies] = {
        123 => { errors: [] },
        456 => { errors: ["Error in second proxy"] }
      }

      expect(worker.send(:any_error_occurred?)).to be true
    end

    it "returns true when actl errors present" do
      results = worker.instance_variable_get(:@results)
      results[:proxies] = {}
      results[:actl_errors] = { 1 => ["ACTL error"] }

      expect(worker.send(:any_error_occurred?)).to be true
    end
  end

  describe "#migrate_reports" do
    let(:assignment) { assignment_model(course:) }
    let(:submission) { submission_model(assignment:, user: user_model) }
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
    let(:asset_processor) do
      Lti::AssetProcessor.create!(
        assignment:,
        context_external_tool: external_tool_1_3_model(context: sub_account)
      )
    end

    it "returns failed status when no asset processor is provided" do
      status, count = worker.send(:migrate_reports, actl, tool_proxy, nil)

      expect(status).to eq(:failed)
      expect(count).to eq(0)
    end

    it "returns success status when no reports exist" do
      status, count = worker.send(:migrate_reports, actl, tool_proxy, asset_processor)

      expect(status).to eq(:success)
      expect(count).to eq(0)
    end

    it "migrates a single originality report" do
      attachment = attachment_model(context: course)
      OriginalityReport.create!(
        attachment:,
        submission:,
        originality_score: 75.5,
        workflow_state: "scored"
      )

      status, count = worker.send(:migrate_reports, actl, tool_proxy, asset_processor)

      expect(status).to eq(:success)
      expect(count).to eq(1)
      expect(Lti::AssetReport.count).to eq(1)

      asset_report = Lti::AssetReport.last
      expect(asset_report.asset_processor).to eq(asset_processor)
      expect(asset_report.result).to eq("75.5%")
      expect(asset_report.report_type).to eq(described_class::MIGRATED_ASSET_REPORT_TYPE)
      expect(asset_report.title).to eq("Turnitin Similarity")
    end

    it "migrates multiple originality reports for different submissions" do
      submission1 = submission
      submission2 = submission_model(assignment:, user: user_model)
      attachment1 = attachment_model(context: course)
      attachment2 = attachment_model(context: course)

      OriginalityReport.create!(
        attachment: attachment1,
        submission: submission1,
        originality_score: 25,
        workflow_state: "scored"
      )
      OriginalityReport.create!(
        attachment: attachment2,
        submission: submission2,
        originality_score: 50,
        workflow_state: "scored"
      )

      status, count = worker.send(:migrate_reports, actl, tool_proxy, asset_processor)

      expect(status).to eq(:success)
      expect(count).to eq(2)
      expect(Lti::AssetReport.count).to eq(2)
    end

    it "only migrates the most recent report for each submission/attachment combination" do
      attachment = attachment_model(context: course)

      # Create older report
      OriginalityReport.create!(
        attachment:,
        submission:,
        originality_score: 30,
        workflow_state: "scored",
        created_at: 2.days.ago
      )

      # Create newer report
      OriginalityReport.create!(
        attachment:,
        submission:,
        originality_score: 75,
        workflow_state: "scored",
        created_at: 1.day.ago
      )

      status, count = worker.send(:migrate_reports, actl, tool_proxy, asset_processor)

      expect(status).to eq(:success)
      expect(count).to eq(1)
      expect(Lti::AssetReport.count).to eq(1)

      asset_report = Lti::AssetReport.last
      expect(asset_report.result).to eq("75.0%")
    end

    it "handles exceptions during report migration and returns partially_failed status" do
      attachment = attachment_model(context: course)
      report1 = OriginalityReport.create!(
        attachment:,
        submission:,
        originality_score: 75,
        workflow_state: "scored"
      )

      submission2 = submission_model(assignment:, user: user_model)
      attachment2 = attachment_model(context: course)
      OriginalityReport.create!(
        attachment: attachment2,
        submission: submission2,
        originality_score: 50,
        workflow_state: "scored"
      )

      # Make first report migration fail
      allow(worker).to receive(:migrate_report).and_wrap_original do |method, *args|
        if args[1] == report1
          raise StandardError, "Test error"
        else
          method.call(*args)
        end
      end

      allow(Canvas::Errors).to receive(:capture_exception)

      status, count = worker.send(:migrate_reports, actl, tool_proxy, asset_processor)

      expect(status).to eq(:partially_failed)
      expect(count).to eq(1)
      expect(Canvas::Errors).to have_received(:capture_exception).once
    end

    it "returns failed status when all report migrations fail" do
      attachment = attachment_model(context: course)
      OriginalityReport.create!(
        attachment:,
        submission:,
        originality_score: 75,
        workflow_state: "scored"
      )

      allow(worker).to receive(:migrate_report).and_raise(StandardError, "Test error")
      allow(Canvas::Errors).to receive(:capture_exception)

      status, count = worker.send(:migrate_reports, actl, tool_proxy, asset_processor)

      expect(status).to eq(:failed)
      expect(count).to eq(0)
    end
  end

  describe "#migrate_report" do
    let(:assignment) { assignment_model(course:) }
    let(:user) { user_model }
    let(:submission) { submission_model(assignment:, user:) }
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
    let(:asset_processor) do
      Lti::AssetProcessor.create!(
        assignment:,
        context_external_tool: external_tool_1_3_model(context: sub_account)
      )
    end

    context "with attachment-based report" do
      it "creates asset report with all required fields" do
        attachment = attachment_model(context: course)
        cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 75.5,
          workflow_state: "scored"
        )

        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        expect(Lti::AssetReport.count).to eq(1)
        asset_report = Lti::AssetReport.last
        expect(asset_report.asset_processor).to eq(asset_processor)
        expect(asset_report.asset.attachment).to eq(attachment)
        expect(asset_report.asset.submission).to eq(submission)
        expect(asset_report.result).to eq("75.5%")
        expect(asset_report.report_type).to eq(described_class::MIGRATED_ASSET_REPORT_TYPE)
        expect(asset_report.title).to eq("Turnitin Similarity")
        expect(asset_report.processing_progress).to eq(Lti::AssetReport::PROGRESS_PROCESSED)
        expect(asset_report.priority).to eq(Lti::AssetReport::PRIORITY_TIME_CRITICAL)
      end

      it "sets correct indication color based on similarity score" do
        attachment = attachment_model(context: course)
        cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 85,
          workflow_state: "scored"
        )

        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        asset_report = Lti::AssetReport.last
        expect(asset_report.indication_color).to be_present
        expect(asset_report.indication_alt).to be_present
      end

      it "sets correct indication color for low similarity score" do
        attachment = attachment_model(context: course)
        cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 15,
          workflow_state: "scored"
        )

        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        asset_report = Lti::AssetReport.last
        expect(asset_report.indication_color).to eq("#00AC18")
        expect(asset_report.indication_alt).to eq("Low similarity - acceptable")
      end

      it "stores custom_sourcedid in extensions when present" do
        attachment = attachment_model(context: course)
        cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 50,
          workflow_state: "scored"
        )

        # Mock extract_custom_sourcedid to return a value
        allow(worker).to receive(:extract_custom_sourcedid).and_return("abc123")

        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        asset_report = Lti::AssetReport.last
        expect(asset_report.extensions["https://www.instructure.com/legacy_custom_sourcedid"]).to eq("abc123")
      end

      it "adds warning when custom_sourcedid is missing" do
        attachment = attachment_model(context: course)
        cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 50,
          workflow_state: "scored"
        )

        worker.send(:initialize_proxy_results, tool_proxy)
        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        results = worker.instance_variable_get(:@results)
        warnings = results[:actl_warnings][actl.id]
        expect(warnings).to include("No custom_sourcedid found on report")
      end

      it "replaces existing report for the same asset" do
        attachment = attachment_model(context: course)

        # First migration
        first_cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 50,
          workflow_state: "scored"
        )

        worker.send(:migrate_report, actl, first_cpf_report, asset_processor)

        expect(Lti::AssetReport.active.count).to eq(1)
        first_asset_report_id = Lti::AssetReport.last.id

        # Second migration with newer report - should replace the first
        second_cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 75,
          workflow_state: "scored"
        )
        second_cpf_report.update_column(:updated_at, 1.hour.from_now)

        worker.send(:migrate_report, actl, second_cpf_report, asset_processor)

        # Should delete older report and create new one (soft delete)
        expect(Lti::AssetReport.active.exists?(first_asset_report_id)).to be false
        expect(Lti::AssetReport.active.count).to eq(1)

        new_report = Lti::AssetReport.active.last
        expect(new_report.result).to eq("75.0%")
      end
    end

    context "with text-entry report (no attachment)" do
      it "raises error when submission attempt cannot be found" do
        cpf_report = OriginalityReport.create!(
          submission:,
          originality_score: 75,
          workflow_state: "scored",
          submission_time: 1.day.ago
        )

        expect do
          worker.send(:migrate_report, actl, cpf_report, asset_processor)
        end.to raise_error("Cannot find submission attempt for report ID=#{cpf_report.id}")
      end

      it "creates asset report with submission attempt when found" do
        cpf_report = OriginalityReport.create!(
          submission:,
          originality_score: 60,
          workflow_state: "scored",
          submission_time: 1.day.ago
        )

        # Mock find_attempt_for_report to return a valid attempt
        allow(worker).to receive(:find_attempt_for_report).with(cpf_report).and_return(1)

        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        expect(Lti::AssetReport.count).to eq(1)
        asset_report = Lti::AssetReport.last
        expect(asset_report.asset_processor).to eq(asset_processor)
        expect(asset_report.asset.submission).to eq(submission)
        expect(asset_report.asset.submission_attempt).to eq(1)
        expect(asset_report.result).to eq("60.0%")
        expect(asset_report.report_type).to eq(described_class::MIGRATED_ASSET_REPORT_TYPE)
      end
    end

    context "visible_to_owner setting" do
      it "sets visible_to_owner based on turnitin_settings" do
        attachment = attachment_model(context: course)
        assignment.update!(turnitin_settings: { s_view_report: "1" })
        cpf_report = OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 50,
          workflow_state: "scored"
        )

        worker.send(:migrate_report, actl, cpf_report, asset_processor)

        asset_report = Lti::AssetReport.last
        expect(asset_report.visible_to_owner).to be true
      end
    end
  end

  describe "#priority_from_cpf_report" do
    it "returns TIME_CRITICAL priority for error state" do
      report = double("report", workflow_state: "error", originality_score: nil)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_TIME_CRITICAL)
    end

    it "returns TIME_CRITICAL priority for score >= 75" do
      report = double("report", workflow_state: "scored", originality_score: 80)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_TIME_CRITICAL)
    end

    it "returns SEMI_TIME_CRITICAL priority for score >= 50 and < 75" do
      report = double("report", workflow_state: "scored", originality_score: 60)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_SEMI_TIME_CRITICAL)
    end

    it "returns NOT_TIME_CRITICAL priority for score >= 25 and < 50" do
      report = double("report", workflow_state: "scored", originality_score: 35)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_NOT_TIME_CRITICAL)
    end

    it "returns GOOD priority for score < 25" do
      report = double("report", workflow_state: "scored", originality_score: 10)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_GOOD)
    end

    it "returns GOOD priority for scored state with no score" do
      report = double("report", workflow_state: "scored", originality_score: nil)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_GOOD)
    end

    it "returns GOOD priority for pending state" do
      report = double("report", workflow_state: "pending", originality_score: nil)
      priority = worker.send(:priority_from_cpf_report, report)
      expect(priority).to eq(Lti::AssetReport::PRIORITY_GOOD)
    end
  end

  describe "#processing_progress_from_cpf_report" do
    it "returns PROCESSING for pending state" do
      report = double("report", workflow_state: "pending")
      progress = worker.send(:processing_progress_from_cpf_report, report)
      expect(progress).to eq(Lti::AssetReport::PROGRESS_PROCESSING)
    end

    it "returns FAILED for error state" do
      report = double("report", workflow_state: "error")
      progress = worker.send(:processing_progress_from_cpf_report, report)
      expect(progress).to eq(Lti::AssetReport::PROGRESS_FAILED)
    end

    it "returns PROCESSED for scored state" do
      report = double("report", workflow_state: "scored")
      progress = worker.send(:processing_progress_from_cpf_report, report)
      expect(progress).to eq(Lti::AssetReport::PROGRESS_PROCESSED)
    end

    it "returns NOT_READY for other states" do
      report = double("report", workflow_state: "unknown")
      progress = worker.send(:processing_progress_from_cpf_report, report)
      expect(progress).to eq(Lti::AssetReport::PROGRESS_NOT_READY)
    end
  end

  describe "#extract_custom_sourcedid" do
    it "extracts custom_sourcedid from resource_url" do
      report = double("report")
      lti_link = double("lti_link", resource_url: "https://example.com/launch?custom_sourcedid=abc123&other=param")
      allow(report).to receive(:lti_link).and_return(lti_link)

      sourcedid = worker.send(:extract_custom_sourcedid, report)
      expect(sourcedid).to eq("abc123")
    end

    it "returns nil when resource_url is nil" do
      report = double("report")
      lti_link = double("lti_link", resource_url: nil)
      allow(report).to receive(:lti_link).and_return(lti_link)

      sourcedid = worker.send(:extract_custom_sourcedid, report)
      expect(sourcedid).to be_nil
    end

    it "returns nil when lti_link is nil" do
      report = double("report", lti_link: nil)

      sourcedid = worker.send(:extract_custom_sourcedid, report)
      expect(sourcedid).to be_nil
    end

    it "returns nil when custom_sourcedid is not present" do
      report = double("report")
      lti_link = double("lti_link", resource_url: "https://example.com/launch?other=param")
      allow(report).to receive(:lti_link).and_return(lti_link)

      sourcedid = worker.send(:extract_custom_sourcedid, report)
      expect(sourcedid).to be_nil
    end

    it "returns nil for invalid URI" do
      report = double("report")
      lti_link = double("lti_link", resource_url: "not a valid uri")
      allow(report).to receive(:lti_link).and_return(lti_link)

      sourcedid = worker.send(:extract_custom_sourcedid, report)
      expect(sourcedid).to be_nil
    end
  end

  describe "#calc_indications_from_cpf_report" do
    it "returns red indication for very high similarity (failure)" do
      report = double("report", originality_score: 95)
      allow(Turnitin).to receive(:state_from_similarity_score).with(95).and_return("failure")

      color, alt = worker.send(:calc_indications_from_cpf_report, report)
      expect(color).to eq("#8B1A1A")
      expect(alt).to eq("Very high similarity - immediate attention required")
    end

    it "returns red indication for high similarity (problem)" do
      report = double("report", originality_score: 80)
      allow(Turnitin).to receive(:state_from_similarity_score).with(80).and_return("problem")

      color, alt = worker.send(:calc_indications_from_cpf_report, report)
      expect(color).to eq("#EE0612")
      expect(alt).to eq("High similarity - attention needed")
    end

    it "returns orange indication for medium similarity (warning)" do
      report = double("report", originality_score: 60)
      allow(Turnitin).to receive(:state_from_similarity_score).with(60).and_return("warning")

      color, alt = worker.send(:calc_indications_from_cpf_report, report)
      expect(color).to eq("#FC5E13")
      expect(alt).to eq("Medium similarity - review recommended")
    end

    it "returns green indication for low similarity (acceptable)" do
      report = double("report", originality_score: 15)
      allow(Turnitin).to receive(:state_from_similarity_score).with(15).and_return("acceptable")

      color, alt = worker.send(:calc_indications_from_cpf_report, report)
      expect(color).to eq("#00AC18")
      expect(alt).to eq("Low similarity - acceptable")
    end

    it "returns green indication for no similarity (none)" do
      report = double("report", originality_score: 0)
      allow(Turnitin).to receive(:state_from_similarity_score).with(0).and_return("none")

      color, alt = worker.send(:calc_indications_from_cpf_report, report)
      expect(color).to eq("#00AC18")
      expect(alt).to eq("No matching content found")
    end

    it "returns nil values when originality_score is not present" do
      report = double("report", originality_score: nil)

      color, alt = worker.send(:calc_indications_from_cpf_report, report)
      expect(color).to be_nil
      expect(alt).to be_nil
    end
  end

  describe "consolidated email for bulk migrations" do
    let(:bulk_migration_id) { SecureRandom.uuid }
    let(:coordinator) do
      coordinator = Progress.create!(
        context: root_account,
        tag: Lti::AssetProcessorTiiMigrationWorker::COORDINATOR_TAG,
        user: admin_user
      )
      coordinator.set_results({ bulk_migration_id:, email: "test@example.com" })
      coordinator.start!
      coordinator
    end
    let(:sub_account2) { account_model(parent_account: root_account, root_account:) }

    def create_migration_progress(context:, workflow_state:, coordinator_id: nil, attachment_id: nil)
      progress = Progress.create!(
        context:,
        tag: Lti::AssetProcessorTiiMigrationWorker::PROGRESS_TAG,
        workflow_state:
      )
      results = {}
      results[:coordinator_id] = coordinator_id if coordinator_id
      results[:migration_report_attachment_id] = attachment_id if attachment_id
      progress.set_results(results)
      progress
    end

    describe "#check_and_send_consolidated_email" do
      it "waits until all migrations with same coordinator have report" do
        create_migration_progress(
          context: sub_account,
          workflow_state: "completed",
          coordinator_id: coordinator.id
        )

        create_migration_progress(
          context: sub_account2,
          workflow_state: "running",
          coordinator_id: coordinator.id
        )

        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        expect(worker).not_to receive(:send_consolidated_report_email)
        worker.send(:check_and_send_consolidated_email)
      end

      it "sends consolidated email when all migrations have reports" do
        report1_csv = "csv1"
        attachment1 = Attachment.create!(
          context: sub_account,
          filename: "report1.csv",
          uploaded_data: StringIO.new(report1_csv)
        )

        report2_csv = "csv2"
        attachment2 = Attachment.create!(
          context: sub_account2,
          filename: "report2.csv",
          uploaded_data: StringIO.new(report2_csv)
        )

        create_migration_progress(
          context: sub_account,
          workflow_state: "completed",
          coordinator_id: coordinator.id,
          attachment_id: attachment1.id
        )

        create_migration_progress(
          context: sub_account2,
          workflow_state: "completed",
          coordinator_id: coordinator.id,
          attachment_id: attachment2.id
        )

        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        expect(worker).to receive(:send_consolidated_report_email).and_return(true)
        worker.send(:check_and_send_consolidated_email)

        expect(coordinator.reload.results[:report_created]).to be true
        expect(coordinator.reload).to be_completed
      end

      it "does not send email if already sent (report_created flag on coordinator)" do
        coordinator_with_report_created = Progress.create!(
          context: root_account,
          tag: Lti::AssetProcessorTiiMigrationWorker::COORDINATOR_TAG,
          user: admin_user
        )
        coordinator_with_report_created.set_results({ bulk_migration_id: SecureRandom.uuid, email: "test@example.com", report_created: true })

        create_migration_progress(
          context: sub_account,
          workflow_state: "completed",
          coordinator_id: coordinator_with_report_created.id
        )

        create_migration_progress(
          context: sub_account2,
          workflow_state: "completed",
          coordinator_id: coordinator_with_report_created.id
        )

        worker = described_class.new(sub_account, "test@example.com", coordinator_with_report_created.id)
        expect(worker).not_to receive(:send_consolidated_report_email)
        worker.send(:check_and_send_consolidated_email)
      end
    end

    describe "#generate_consolidated_report" do
      it "concatenates all individual migration reports" do
        # Create mock CSV content for report 1
        report1_csv = CSV.generate do |csv|
          csv << ["Account ID", "Account Name", "Assignment ID", "Assignment Name", "Course ID", "Tool Proxy ID", "Lti 1.3 Tool ID", "Asset Processor Migration", "Asset Report Migration", "Number of Reports Migrated", "Error Message", "Warnings"]
          csv << [sub_account.id, sub_account.name, "1", "Assignment 1", "100", "tp1", "tool1", "success", "success", "5", "", ""]
          csv << [sub_account.id, sub_account.name, "2", "Assignment 2", "100", "tp1", "tool1", "success", "success", "3", "", ""]
        end

        # Create mock CSV content for report 2
        report2_csv = CSV.generate do |csv|
          csv << ["Account ID", "Account Name", "Assignment ID", "Assignment Name", "Course ID", "Tool Proxy ID", "Lti 1.3 Tool ID", "Asset Processor Migration", "Asset Report Migration", "Number of Reports Migrated", "Error Message", "Warnings"]
          csv << [sub_account2.id, sub_account2.name, "3", "Assignment 3", "200", "tp2", "tool2", "success", "success", "2", "", ""]
        end

        # Create attachments with the CSV content
        attachment1 = Attachment.create!(
          context: root_account,
          filename: "report1.csv",
          content_type: "text/csv",
          uploaded_data: StringIO.new(report1_csv)
        )

        attachment2 = Attachment.create!(
          context: root_account,
          filename: "report2.csv",
          content_type: "text/csv",
          uploaded_data: StringIO.new(report2_csv)
        )

        progress1 = create_migration_progress(
          context: sub_account,
          workflow_state: "completed",
          attachment_id: attachment1.id
        )

        progress2 = create_migration_progress(
          context: sub_account2,
          workflow_state: "completed",
          attachment_id: attachment2.id
        )

        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        csv_content = worker.send(:generate_consolidated_report, [progress1, progress2])
        rows = CSV.parse(csv_content)

        # Should have: 1 header + 2 rows from report1 + 1 row from report2 = 4 rows
        expect(rows.length).to eq(4)
        expect(rows[0]).to eq(["Account ID", "Account Name", "Assignment ID", "Assignment Name", "Course ID", "Tool Proxy ID", "Lti 1.3 Tool ID", "Asset Processor Migration", "Asset Report Migration", "Number of Reports Migrated", "Error Message", "Warnings"])

        # Check data rows include assignments from both reports
        assignment_ids = rows[1..].pluck(2)
        expect(assignment_ids).to contain_exactly("1", "2", "3")
      end

      it "handles missing report attachments gracefully" do
        progress1 = create_migration_progress(
          context: sub_account,
          workflow_state: "completed",
          attachment_id: nil
        )

        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        csv_content = worker.send(:generate_consolidated_report, [progress1])
        rows = CSV.parse(csv_content)

        # When no attachments are found, returns empty string which parses to no rows
        expect(rows.length).to eq(0)
      end
    end

    describe "#consolidated_email_body" do
      it "returns success message when all migrations succeeded" do
        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        body = worker.send(:consolidated_email_body, "http://example.com/report", 3, false)
        expect(body).to include("completed successfully")
        expect(body).to include("3 account(s)")
        expect(body).to include("http://example.com/report")
      end

      it "returns partial failure message when some migrations failed" do
        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        body = worker.send(:consolidated_email_body, "http://example.com/report", 3, true)
        expect(body).to include("completed with some failures")
        expect(body).to include("3 account(s)")
        expect(body).to include("http://example.com/report")
      end
    end

    describe "individual email sending during bulk migration" do
      before do
        allow(developer_key).to receive(:global_id).and_return(999)
        allow(root_account).to receive_messages(
          turnitin_asset_processor_client_id: developer_key.global_id,
          feature_enabled?: true
        )
      end

      it "skips individual email when coordinator_id is present" do
        worker = described_class.new(sub_account, "test@example.com", coordinator.id)
        progress = Progress.create!(context: sub_account, tag: Lti::AssetProcessorTiiMigrationWorker::PROGRESS_TAG)
        progress.start!

        allow(worker).to receive_messages(
          prevalidations_successful?: true,
          actls_for_account_count: 0,
          migrate_actls: nil,
          save_migration_report: nil,
          any_error_occurred?: false
        )
        expect(worker).to receive(:check_and_send_consolidated_email)
        expect(worker).not_to receive(:send_migration_report_email)

        worker.perform(progress)
      end

      it "sends individual email when coordinator_id is not present" do
        worker = described_class.new(sub_account, "test@example.com", nil)
        progress = Progress.create!(context: sub_account, tag: Lti::AssetProcessorTiiMigrationWorker::PROGRESS_TAG)
        progress.start!

        allow(worker).to receive_messages(
          prevalidations_successful?: true,
          actls_for_account_count: 0,
          migrate_actls: nil,
          save_migration_report: nil,
          any_error_occurred?: false
        )
        expect(worker).to receive(:send_migration_report_email)
        expect(worker).not_to receive(:check_and_send_consolidated_email)

        worker.perform(progress)
      end
    end
  end

  describe "#rollback" do
    let(:test_course) { course_model(account: sub_account) }
    let(:test_assignment1) { assignment_model(course: test_course) }
    let(:test_assignment2) { assignment_model(course: test_course) }

    let(:migrated_tool_proxy) do
      create_tool_proxy(
        context: test_course,
        product_family:,
        create_binding: true,
        raw_data: { "custom" => { "proxy_instance_id" => "test_proxy_123" } }
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

    let(:resource_handler) do
      Lti::ResourceHandler.create!(
        resource_type_code: "resource",
        name: "Test Resource",
        tool_proxy: migrated_tool_proxy
      )
    end

    let(:message_handler) do
      Lti::MessageHandler.create!(
        message_type: "basic-lti-launch-request",
        launch_path: "http://example.com/launch",
        resource_handler:,
        tool_proxy: migrated_tool_proxy
      )
    end

    let(:actl1) do
      AssignmentConfigurationToolLookup.create!(
        assignment: test_assignment1,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: product_family.vendor_code,
        tool_product_code: product_family.product_code,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )
    end

    let(:actl2) do
      AssignmentConfigurationToolLookup.create!(
        assignment: test_assignment2,
        tool: message_handler,
        tool_type: "Lti::MessageHandler",
        tool_id: message_handler.id,
        tool_vendor_code: product_family.vendor_code,
        tool_product_code: product_family.product_code,
        tool_resource_type_code: resource_handler.resource_type_code,
        context_type: "Course"
      )
    end

    it "destroys asset processors and clears migrated_to_context_external_tool for all ACTLs" do
      migrated_tool_proxy.update!(migrated_to_context_external_tool: ap_tool)
      allow_any_instance_of(Lti::ToolProxy).to receive(:manage_subscription)

      actl1
      actl2

      Lti::AssetProcessor.create!(
        assignment: test_assignment1,
        context_external_tool: ap_tool,
        migration_id: worker.send(:generate_migration_id, migrated_tool_proxy, actl1),
        workflow_state: "active"
      )

      Lti::AssetProcessor.create!(
        assignment: test_assignment2,
        context_external_tool: ap_tool,
        migration_id: worker.send(:generate_migration_id, migrated_tool_proxy, actl2),
        workflow_state: "active"
      )

      expect(migrated_tool_proxy.migrated_to_context_external_tool).to eq(ap_tool)
      expect(Lti::AssetProcessor.active.where(assignment: [test_assignment1, test_assignment2]).count).to eq(2)

      worker.rollback

      expect(Lti::AssetProcessor.active.where(assignment: [test_assignment1, test_assignment2]).count).to eq(0)
      expect(migrated_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
    end

    it "skips tool proxies from other accounts and continues processing" do
      other_account = account_model(parent_account: root_account, root_account:)
      other_course = course_model(account: other_account)
      other_tool_proxy = create_tool_proxy(
        context: other_course,
        product_family:,
        create_binding: true
      )
      other_tool_proxy.update!(migrated_to_context_external_tool: ap_tool)

      migrated_tool_proxy.update!(migrated_to_context_external_tool: ap_tool)
      allow_any_instance_of(Lti::ToolProxy).to receive(:manage_subscription)

      actl1
      actl2

      ap1 = Lti::AssetProcessor.create!(
        assignment: test_assignment1,
        context_external_tool: ap_tool,
        migration_id: worker.send(:generate_migration_id, migrated_tool_proxy, actl1),
        workflow_state: "active"
      )

      ap2 = Lti::AssetProcessor.create!(
        assignment: test_assignment2,
        context_external_tool: ap_tool,
        migration_id: worker.send(:generate_migration_id, migrated_tool_proxy, actl2),
        workflow_state: "active"
      )

      allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:associated_tool_proxy) do |actl|
        if actl.id == actl1.id
          other_tool_proxy
        else
          migrated_tool_proxy
        end
      end

      worker.rollback

      expect(ap1.reload.workflow_state).to eq("active")
      expect(ap2.reload.workflow_state).to eq("deleted")
      expect(other_tool_proxy.reload.migrated_to_context_external_tool).to eq(ap_tool)
      expect(migrated_tool_proxy.reload.migrated_to_context_external_tool).to be_nil
    end
  end
end
