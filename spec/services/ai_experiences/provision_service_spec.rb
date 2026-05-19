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

describe AiExperiences::ProvisionService do
  let_once(:account) { account_model }
  let(:http_client) { instance_double(LlmConversation::HttpClient) }
  let(:service) { described_class.new }
  let(:provision_response) do
    {
      "data" => {
        "api_token" => "test-api-token",
        "refresh_token" => "test-refresh-token"
      }
    }
  end

  before do
    allow(LlmConversation::HttpClient).to receive(:new)
      .with(account:, use_initial_token: true)
      .and_return(http_client)
  end

  describe "#provision" do
    before do
      allow(http_client).to receive(:post)
        .with("/provision", payload: { account_id: account.uuid, root_account_id: account.root_account.uuid })
        .and_return(provision_response)
    end

    it "saves the api_token and refresh_token to account settings" do
      service.provision(account)

      account.reload
      expect(account.settings[:llm_conversation_service]).to eql({
                                                                   api_jwt_token: "test-api-token",
                                                                   refresh_jwt_token: "test-refresh-token"
                                                                 })
    end

    it "handles a flat response without a data envelope" do
      flat_response = { "api_token" => "flat-token", "refresh_token" => "flat-refresh" }
      allow(http_client).to receive(:post).and_return(flat_response)

      service.provision(account)

      account.reload
      expect(account.settings.dig(:llm_conversation_service, :api_jwt_token)).to eql("flat-token")
    end

    it "uses the initial token http client" do
      service.provision(account)

      expect(LlmConversation::HttpClient).to have_received(:new).with(account:, use_initial_token: true)
    end

    it "writes the new api token to the cache" do
      allow(LlmConversation::TokenCache).to receive(:set_api_token)

      service.provision(account)

      expect(LlmConversation::TokenCache).to have_received(:set_api_token).with(account, "test-api-token")
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:post)
        .and_raise(LlmConversation::Errors::ConversationError, "Service unavailable")

      expect { service.provision(account) }
        .to raise_error(LlmConversation::Errors::ConversationError, "Service unavailable")
    end
  end
end
