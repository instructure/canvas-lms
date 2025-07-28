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
require_relative "concerns/lti_services_shared_examples"

describe Lti::IMS::NoticeHandlersController do
  include_context "advantage services context"

  let(:cet) { developer_key.context_external_tools.first }
  let(:tool_id) { cet.global_id.to_s }
  let(:body_overrides) { {} }
  let(:params_overrides) { { context_external_tool_id: tool_id } }
  let(:client_id) { developer_key.global_id }
  let(:lti_context_id) { Account.default.lti_context_id }
  let(:deployment_id) { cet.id.to_s + ":" + lti_context_id }
  let(:handlers) { [{ "notice_type" => "notice_type", "handler" => "https://example.com" }] }

  # For shard lti services specs. Note that most of the "advantage services" shared specs don't
  # apply to this controller because this controller takes a tool_id and finds a context from it
  # (instead of the other way around), or have an account context
  let(:expected_mime_type) { "application/json" }
  let(:scope_to_remove) { "https://purl.imsglobal.org/spec/lti/scope/noticehandlers" }
  let(:context) { cet.context }

  describe "#index" do
    let(:action) { :index }

    before do
      allow(Lti::PlatformNotificationService).to receive(:list_handlers).with(tool: cet).and_return(handlers)
    end

    it_behaves_like "lti services", skip_mime_type_checks_on_error: true

    it "returns the correct JSON response" do
      send_request
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({
                                           "client_id" => client_id,
                                           "deployment_id" => deployment_id,
                                           "notice_handlers" => handlers
                                         })
    end

    context "with unbound developer key" do
      it "returns 401 unauthorized and complains about missing developer key" do
        developer_key.developer_key_account_bindings.first.update! workflow_state: "off"
        send_request
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Invalid Developer Key")
      end
    end

    context "with deleted tool" do
      it "returns 404 not found" do
        tool.destroy!
        send_request
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#update" do
    let(:action) { :update }
    let(:request_method) { :put }
    let(:notice_type) { "notice_type" }
    let(:handler_url) { "https://valid.url" }

    describe "with a valid handler url" do
      let(:body_overrides) { handler_object }
      let(:handler_object) { { notice_type:, handler: handler_url } }

      it_behaves_like "lti services", skip_mime_type_checks_on_error: true

      before do
        allow(Lti::PlatformNotificationService).to receive(:list_handlers).with(tool: cet).and_return(handlers)
        allow(Lti::PlatformNotificationService).to \
          receive(:subscribe_tool_for_notice)
          .and_return(handler_object)
      end

      it "subscribes the tool for given notice and returns the created handler" do
        send_request
        expect(response.parsed_body).to eq(JSON.parse(handler_object.to_json))
        expect(response).to have_http_status(:ok)
        expect(Lti::PlatformNotificationService).to have_received(:subscribe_tool_for_notice).with(tool: cet, notice_type:, handler_url:, max_batch_size: nil)
      end

      context "when the request has extra fields" do
        let(:body_overrides) { { notice_type:, handler: handler_url, extraField: "Canvas should ignore this" } }

        it "subscribes the tool for given notice and returns the created handler while ignoring the extra field" do
          send_request
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq(JSON.parse(handler_object.to_json))
          expect(Lti::PlatformNotificationService).to have_received(:subscribe_tool_for_notice).with(tool: cet, notice_type:, handler_url:, max_batch_size: nil)
        end
      end

      context "with max_batch_size" do
        let(:handler_object) { { notice_type:, handler: handler_url, max_batch_size: "20" } }

        it "subscribes the tool for given notice and returns the created handler with max_batch_size" do
          send_request
          expect(response).to have_http_status(:ok)

          expect(response.parsed_body).to eq(JSON.parse(handler_object.to_json))
          expect(Lti::PlatformNotificationService).to have_received(:subscribe_tool_for_notice).with(tool: cet, notice_type:, handler_url:, max_batch_size: "20")
        end
      end
    end

    describe "with empty handler url" do
      let(:body_overrides) { { notice_type:, handler: handler_url } }
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

    describe "with a missing handler url" do
      let(:body_overrides) { { notice_type: } }

      it "returns a 400" do
        send_request
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ "errors" => { "message" => "handler must be a valid URL or an empty string", "type" => "bad_request" } })
      end
    end

    describe "with a tool_id not related to devkey" do
      let(:body_overrides) { { notice_type:, handler: handler_url } }
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
      let(:body_overrides) { { notice_type:, handler: handler_url } }
      let(:tool_id) { "11223344" }

      it "rejected with 404" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "with devkey turned off" do
      let(:handler_object) { { notice_type:, handler: handler_url } }
      let(:body_overrides) { handler_object }

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
