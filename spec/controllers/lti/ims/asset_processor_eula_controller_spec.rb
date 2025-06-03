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
require_relative "concerns/advantage_services_shared_context"

describe Lti::IMS::AssetProcessorEulaController do
  include_context "advantage services context"

  let(:cet) { developer_key.context_external_tools.first }
  let(:tool_id) { cet.global_id.to_s }
  let(:params_overrides) { { context_external_tool_id: tool_id } }
  let(:context) { cet.context }
  let(:eula_required) { true }
  let(:body_overrides) { { eulaRequired: eula_required } }

  describe "#update_tool_eula" do
    let(:action) { :update_tool_eula }
    let(:request_method) { :put }

    [true, false].each do |eula_value|
      context "when eulaRequired is #{eula_value}" do
        let(:eula_required) { eula_value }

        it "updates the tool's EULA requirement and returns the updated value" do
          send_request
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "eulaRequired" => eula_required })
          expect(cet.reload.asset_processor_eula_required).to eq(eula_required)
        end
      end

      context "when the request has extra fields" do
        let(:eula_required) { eula_value }
        let(:body_overrides) { { eulaRequired: eula_required, extraField: "Canvas should ignore this" } }

        it "updates the tool's EULA requirement and returns the updated value while ignore the extra field" do
          send_request
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "eulaRequired" => eula_required })
          expect(cet.reload.asset_processor_eula_required).to eq(eula_required)
        end
      end
    end

    context "when eulaRequired in the request body is null" do
      let(:body_overrides) { { eulaRequired: nil } }

      it "returns 400 bad request" do
        send_request
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when the tool is not found" do
      let(:tool_id) { "invalid_id" }

      it "returns 404 not found" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the tool is invalid" do
      before do
        allow_any_instance_of(ContextExternalTool).to receive(:developer_key_id).and_return("mismatched_id")
      end

      it "returns 400 bad request" do
        send_request
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "#require_feature_enabled" do
    let(:action) { :update_tool_eula }
    let(:request_method) { :put }

    context "when the feature is enabled" do
      it "proceeds with the request" do
        send_request
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the feature is disabled" do
      before { tool.root_account.disable_feature!(:lti_asset_processor) }

      it "returns 404 not found" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#create_acceptance" do
    let(:action) { :create_acceptance }
    let(:request_method) { :post }
    let(:user) { user_model(root_account_ids: [context.root_account.id]) }
    let(:user_id) { user.lti_id }
    let(:timestamp) { Time.zone.now.iso8601 }
    let(:accepted) { true }
    let(:body_overrides) { { userId: user_id, accepted:, timestamp: } }

    [true, false].each do |acc|
      let(:accepted) { acc }
      context "when the acceptance is successfully created and accepted is #{acc}" do
        it "creates a new EULA acceptance and returns 201 created" do
          send_request
          expect(response).to have_http_status(:created)
          expect(response.parsed_body).to eq({
                                               "userId" => user_id,
                                               "accepted" => accepted,
                                               "timestamp" => timestamp
                                             })
          expect(user.lti_asset_processor_eula_acceptances.count).to eq(1)
          expect(user.lti_asset_processor_eula_acceptances.first.accepted).to eq(accepted)
        end
      end

      context "when the request has extra fields and accepted is #{acc}" do
        let(:body_overrides) { { userId: user_id, accepted:, timestamp:, extraField: "Canvas should ignore this" } }

        it "creates a new EULA acceptance and returns 201 created while ignoring the extra field" do
          send_request
          expect(response).to have_http_status(:created)
          expect(response.parsed_body).to eq({
                                               "userId" => user_id,
                                               "accepted" => accepted,
                                               "timestamp" => timestamp
                                             })
          expect(user.lti_asset_processor_eula_acceptances.count).to eq(1)
          expect(user.lti_asset_processor_eula_acceptances.first.accepted).to eq(accepted)
        end
      end
    end

    context "when the timestamp is older than the latest acceptance" do
      before do
        user.lti_asset_processor_eula_acceptances.create!(
          context_external_tool_id: cet.id,
          timestamp:,
          accepted: true
        )
      end

      it "returns 409 conflict" do
        send_request
        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body).to eq({ "error" => "timestamp older than latest" })
      end
    end

    context "when the user is from cross shard" do
      let(:user) { user_model(root_account_ids: [context.root_account.global_id]) }

      it "creates a new EULA acceptance and returns 201 created" do
        send_request
        expect(response).to have_http_status(:created)
      end
    end

    context "when the timestamp is invalid" do
      let(:timestamp) { "invalid_timestamp" }

      it "returns 400 bad request" do
        send_request
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ "errors" => {
                                             "message" => "A valid ISO8601 timestamp must be provided",
                                             "type" => "bad_request"
                                           } })
      end
    end

    context "when the user is not found" do
      let(:user_id) { "invalid_user_id" }

      it "returns 404 not found" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the tool is not found" do
      let(:tool_id) { "invalid_id" }

      it "returns 404 not found" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the tool is invalid" do
      before do
        allow_any_instance_of(ContextExternalTool).to receive(:developer_key_id).and_return("mismatched_id")
      end

      it "returns 400 bad request" do
        send_request
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "#delete_acceptances" do
    let(:action) { :delete_acceptances }
    let(:request_method) { :delete }
    let(:user) { user_model(root_account_ids: [context.root_account.id]) }
    let(:user2) { user_model(root_account_ids: [context.root_account.id]) }
    let(:cet2) do
      ContextExternalTool.create!(
        context: tool_context,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key:,
        lti_version: "1.3",
        workflow_state: "public"
      )
    end

    context "when the acceptances are successfully deleted" do
      before do
        user.lti_asset_processor_eula_acceptances.create!(
          context_external_tool_id: cet.id,
          timestamp: Time.zone.now,
          accepted: true
        )
        user2.lti_asset_processor_eula_acceptances.create!(
          context_external_tool_id: cet.id,
          timestamp: Time.zone.now,
          accepted: true
        )
        user2.lti_asset_processor_eula_acceptances.create!(
          context_external_tool_id: cet2.id,
          timestamp: Time.zone.now,
          accepted: true
        )
      end

      it "deletes the user's EULA acceptances and returns 204 no content" do
        send_request
        expect(response).to have_http_status(:no_content)
        expect(Lti::AssetProcessorEulaAcceptance.active.count).to eq(1)
        expect(Lti::AssetProcessorEulaAcceptance.active.first.context_external_tool_id).to eq(cet2.id)
      end
    end

    context "when the user has no acceptances" do
      it "returns 204 no content" do
        send_request
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when the tool is not found" do
      let(:tool_id) { "invalid_id" }

      it "returns 404 not found" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the tool is invalid" do
      before do
        allow_any_instance_of(ContextExternalTool).to receive(:developer_key_id).and_return("mismatched_id")
      end

      it "returns 400 bad request" do
        send_request
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
