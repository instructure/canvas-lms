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

describe LlmConversation::TokenCache do
  let_once(:account) { account_model }
  let(:cache_key) { "llm_conversation_service:auth:#{account.global_id}:api_token" }
  let(:redis) { instance_double(Redis) }

  before do
    allow(Canvas).to receive_messages(redis_enabled?: true, redis:)
  end

  describe ".get_api_token" do
    context "when Redis is enabled and the token is cached" do
      before { allow(redis).to receive(:get).with(cache_key).and_return("cached-token") }

      it "returns the cached token" do
        expect(described_class.get_api_token(account)).to eql("cached-token")
      end

      it "does not read from account settings" do
        expect(account).not_to receive(:settings)
        described_class.get_api_token(account)
      end

      it "does not write to Redis" do
        expect(redis).not_to receive(:setex)
        described_class.get_api_token(account)
      end
    end

    context "when Redis is enabled and the token is not cached" do
      before do
        allow(redis).to receive(:get).with(cache_key).and_return(nil)
        allow(redis).to receive(:setex)
        account.settings[:llm_conversation_service] = { api_jwt_token: "db-token" }
        account.save!
      end

      it "returns the token from account settings" do
        expect(described_class.get_api_token(account)).to eql("db-token")
      end

      it "writes the token to Redis with the correct key and TTL" do
        described_class.get_api_token(account)
        expect(redis).to have_received(:setex).with(cache_key, LlmConversation::TokenCache::TTL, "db-token")
      end
    end

    context "when Redis is enabled and no token exists in settings" do
      before do
        allow(redis).to receive(:get).with(cache_key).and_return(nil)
      end

      it "returns nil" do
        expect(described_class.get_api_token(account)).to be_nil
      end

      it "does not write to Redis" do
        expect(redis).not_to receive(:setex)
        described_class.get_api_token(account)
      end
    end

    context "when Redis is disabled" do
      before do
        allow(Canvas).to receive(:redis_enabled?).and_return(false)
        account.settings[:llm_conversation_service] = { api_jwt_token: "db-token" }
        account.save!
      end

      it "returns the token from account settings" do
        expect(described_class.get_api_token(account)).to eql("db-token")
      end

      it "does not interact with Redis" do
        expect(Canvas).not_to receive(:redis)
        described_class.get_api_token(account)
      end
    end
  end

  describe ".set_api_token" do
    context "when Redis is enabled and token is present" do
      before { allow(redis).to receive(:setex) }

      it "writes the token with the correct key and TTL" do
        described_class.set_api_token(account, "new-token")
        expect(redis).to have_received(:setex).with(cache_key, LlmConversation::TokenCache::TTL, "new-token")
      end
    end

    context "when Redis is disabled" do
      before { allow(Canvas).to receive(:redis_enabled?).and_return(false) }

      it "does not interact with Redis" do
        expect(Canvas).not_to receive(:redis)
        described_class.set_api_token(account, "new-token")
      end
    end

    context "when token is blank" do
      before { allow(redis).to receive(:setex) }

      it "does not write to Redis" do
        described_class.set_api_token(account, nil)
        expect(redis).not_to have_received(:setex)
      end
    end
  end

  describe ".invalidate" do
    context "when Redis is enabled" do
      before { allow(redis).to receive(:del) }

      it "deletes the cache key" do
        described_class.invalidate(account)
        expect(redis).to have_received(:del).with(cache_key)
      end
    end

    context "when Redis is disabled" do
      before { allow(Canvas).to receive(:redis_enabled?).and_return(false) }

      it "does not interact with Redis" do
        expect(Canvas).not_to receive(:redis)
        described_class.invalidate(account)
      end
    end
  end
end
