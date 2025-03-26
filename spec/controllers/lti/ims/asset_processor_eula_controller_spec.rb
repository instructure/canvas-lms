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
end
