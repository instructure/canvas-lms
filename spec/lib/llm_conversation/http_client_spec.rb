# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require "webmock/rspec"

describe LlmConversation::HttpClient do
  let_once(:account) { account_model }

  before do
    Setting.set("llm_conversation_base_url", "http://localhost:3001")
    account.enable_feature!(:ai_experiences_v2_auth)
    account.settings[:llm_conversation_service] = {
      api_jwt_token: "api-token",
      refresh_jwt_token: "refresh-token"
    }
    account.save!
    allow(LlmConversation::TokenCache).to receive(:get_api_token).with(account).and_return("api-token")
    allow(LlmConversation::TokenCache).to receive(:set_api_token)
  end

  describe "V2 auth 401 token refresh" do
    let(:client) { described_class.new(account:) }

    context "when the request returns 401 and refresh succeeds" do
      let(:refresh_response) do
        { "api_token" => "new-api-token", "refresh_token" => "new-refresh-token" }.to_json
      end

      before do
        stub_request(:get, "http://localhost:3001/conversations")
          .to_return(
            { status: 401, body: "Unauthorized" },
            { status: 200, body: { "data" => [] }.to_json, headers: { "Content-Type" => "application/json" } }
          )
        stub_request(:post, "http://localhost:3001/token/refresh")
          .with(headers: { "Authorization" => "Bearer refresh-token", "x-account-id" => account.uuid })
          .to_return(status: 200, body: refresh_response, headers: { "Content-Type" => "application/json" })
      end

      it "retries the original request and returns the result" do
        result = client.get("/conversations")
        expect(result).to eql({ "data" => [] })
      end

      it "persists the new tokens to account settings" do
        client.get("/conversations")
        account.reload
        expect(account.settings.dig(:llm_conversation_service, :api_jwt_token)).to eql("new-api-token")
        expect(account.settings.dig(:llm_conversation_service, :refresh_jwt_token)).to eql("new-refresh-token")
      end

      it "writes the new api token to the cache" do
        client.get("/conversations")
        expect(LlmConversation::TokenCache).to have_received(:set_api_token).with(account, "new-api-token")
      end
    end

    context "when the refresh token is missing from account settings" do
      before do
        account.settings[:llm_conversation_service] = { api_jwt_token: "api-token" }
        account.save!
        stub_request(:get, "http://localhost:3001/conversations").to_return(status: 401, body: "Unauthorized")
      end

      it "raises a ConversationError" do
        expect { client.get("/conversations") }
          .to raise_error(LlmConversation::Errors::ConversationError, /No refresh token available/)
      end
    end

    context "when the refresh endpoint itself fails" do
      before do
        stub_request(:get, "http://localhost:3001/conversations").to_return(status: 401, body: "Unauthorized")
        stub_request(:post, "http://localhost:3001/token/refresh").to_return(status: 500, body: "Error")
      end

      it "raises a ConversationError" do
        expect { client.get("/conversations") }
          .to raise_error(LlmConversation::Errors::ConversationError, /Token refresh failed/)
      end
    end

    context "when the account does not have V2 auth enabled" do
      let(:v1_account) { account_model }
      let(:v1_client) do
        allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return("v1-token")
        described_class.new
      end

      before do
        stub_request(:get, "http://localhost:3001/conversations").to_return(status: 401, body: "Unauthorized")
      end

      it "does not attempt a refresh and raises ConversationError" do
        expect { v1_client.get("/conversations") }
          .to raise_error(LlmConversation::Errors::ConversationError)
        expect(WebMock).not_to have_requested(:post, "http://localhost:3001/token/refresh")
      end
    end
  end
end
