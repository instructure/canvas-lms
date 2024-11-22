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

require_relative "concerns/advantage_services_shared_context"
require_relative "concerns/advantage_services_shared_examples"
require_relative "concerns/lti_services_shared_examples"

describe Lti::IMS::NoticeHandlersController do
  include_context "advantage services context"
  let(:scope_to_remove) { "https://purl.imsglobal.org/spec/lti/scope/noticehandlers" }
  let(:expected_mime_type) { "application/json" }

  let(:cet) { developer_key.context_external_tools.first }
  let(:tool_id) { cet.global_id.to_s }
  let(:body_overrides) { "{}" }
  let(:params_overrides) { { context_external_tool_id: tool_id }.merge(JSON.parse(body_overrides)) }
  let(:client_id) { developer_key.global_id }
  let(:lti_context_id) { Account.default.lti_context_id }
  let(:deployment_id) { cet.id.to_s + ":" + lti_context_id }
  let(:handlers) { [{ "notice_type" => "notice_type", "handler" => "https://example.com" }] }

  describe "#index" do
    let(:action) { :index }

    before do
      allow(Lti::PlatformNotificationService).to receive(:list_handlers).with(tool: cet).and_return(handlers)
    end

    it "returns the correct JSON response" do
      send_request
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
                                           "client_id" => client_id,
                                           "deployment_id" => deployment_id,
                                           "notice_handlers" => handlers
                                         })
    end
  end

  describe "#update" do
    let(:action) { :update }
    let(:request_method) { :put }
    let(:notice_type) { "notice_type" }
    let(:handler_url) { "https://valid.url" }

    describe "with a valid handler url" do
      let(:handler_object) { { notice_type:, handler: handler_url } }
      let(:body_overrides) { handler_object.to_json }

      before do
        allow(Lti::PlatformNotificationService).to receive(:list_handlers).with(tool: cet).and_return(handlers)
        allow(Lti::PlatformNotificationService).to receive(:subscribe_tool_for_notice)
          .with(tool: cet, notice_type:, handler_url:)
          .and_return(handler_object)
      end

      it "subscribes the tool for given notice and returns the created handler" do
        send_request
        expect(response).to have_http_status(:ok)
        expect(Lti::PlatformNotificationService).to have_received(:subscribe_tool_for_notice).with(tool: cet, notice_type:, handler_url:)
        expect(response.parsed_body).to eq(JSON.parse(handler_object.to_json))
      end
    end

    describe "with empty handler url" do
      let(:body_overrides) { { notice_type:, handler: handler_url }.to_json }
      let(:handler_url) { "" }

      before do
        allow(Lti::PlatformNotificationService).to receive(:list_handlers).with(tool: cet).and_return(handlers)
        allow(Lti::PlatformNotificationService).to receive(:unsubscribe_tool_for_notice)
          .with(tool: cet, notice_type:)
          .and_return({ notice_type:, handler: "" })
      end

      it "unsubscribes the tool for given notice and returns an empty handler JSON response" do
        send_request
        expect(response).to have_http_status(:ok)
        expect(Lti::PlatformNotificationService).to have_received(:unsubscribe_tool_for_notice).with(tool: cet, notice_type:)
        expect(response.parsed_body).to eq({ "handler" => "", "notice_type" => notice_type })
      end
    end

    describe "with a tool_id not related to devkey" do
      let(:body_overrides) { { notice_type:, handler: handler_url }.to_json }
      let(:tool_id) do
        ContextExternalTool.create!(
          context: tool_context,
          consumer_key: "key",
          shared_secret: "secret",
          name: "test tool",
          url: "http://www.tool.com/launch",
          developer_key: DeveloperKey.create!,
          lti_version: "1.3",
          workflow_state: "public"
        ).id.to_s
      end

      it "rejected with 403" do
        send_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "with a tool_id not in db" do
      let(:body_overrides) { { notice_type:, handler: handler_url }.to_json }
      let(:tool_id) { "11223344" }

      it "rejected with 404" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "with devkey turned off" do
      let(:handler_object) { { notice_type:, handler: handler_url } }
      let(:body_overrides) { handler_object.to_json }

      before do
        developer_key.account_binding_for(Account.default).update!(workflow_state: "off")
      end

      it "it throws 401" do
        send_request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
