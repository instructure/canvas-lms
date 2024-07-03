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

describe InstLLMHelper do
  describe ".client" do
    model_id = "model123"
    before do
      InstLLMHelper.instance_variable_set(:@clients, nil)

      aws_credential_provider = double
      allow(aws_credential_provider).to receive(:credentials).and_return(double(
                                                                           access_key_id: "access_key_id",
                                                                           secret_access_key: "secret_access_key",
                                                                           session_token: "session_token"
                                                                         ))
      allow(Canvas::AwsCredentialProvider).to receive(:new).with("bedrock_creds", nil).and_return(aws_credential_provider)
    end

    it "creates a client for the given model_id" do
      expect(InstLLM::Client).to receive(:new).with(
        model_id,
        region: "us-west-2",
        access_key_id: "access_key_id",
        secret_access_key: "secret_access_key",
        session_token: "session_token"
      )
      InstLLMHelper.client(model_id)
    end

    it "caches the client" do
      model_id = "model123"
      client = double
      allow(InstLLM::Client).to receive(:new).and_return(client)
      expect(InstLLMHelper.client(model_id)).to eq(client)
      expect(InstLLMHelper.client(model_id)).to eq(client)
    end
  end

  describe ".with_rate_limit" do
    let(:user) { double(uuid: "user123") }
    let(:llm_config) { double(rate_limit: { limit: 10, period: "day" }, name: "test") }

    it "yields if rate limit is not set" do
      llm_config = double(rate_limit: nil)
      expect { |b| InstLLMHelper.with_rate_limit(user:, llm_config:, &b) }.to yield_control
    end

    it "raises an error if Redis is not enabled" do
      allow(Canvas).to receive(:redis_enabled?).and_return(false)
      expect do
        InstLLMHelper.with_rate_limit(user:, llm_config:) do
          true
        end
      end.to raise_error("InstLLMHelper rate limiting requires Redis to be enabled for the Canvas instance. You may remove the 'rate_limit' option from the LLMConfig to disable rate limiting.")
    end

    it "raises an error if period is not 'day'" do
      llm_config = double(rate_limit: { limit: 10, period: "hour" })
      expect do
        InstLLMHelper.with_rate_limit(user:, llm_config:) do
          true
        end
      end.to raise_error(NotImplementedError, "Only 'day' is supported as a rate limit period.")
    end

    it "raises an error if rate limit is exceeded" do
      cache_key = [
        "inst_llm_helper",
        "rate_limit",
        user.uuid,
        llm_config.name,
        Time.now.utc.strftime("%Y%m%d")
      ].cache_key
      allow(Canvas.redis).to receive(:get).with(cache_key).and_return("10")
      expect do
        InstLLMHelper.with_rate_limit(user:, llm_config:) do
          true
        end
      end.to raise_error(InstLLMHelper::RateLimitExceededError, "Rate limit exceeded: 10")
    end

    it "increments the cache key and yields control" do
      cache_key = [
        "inst_llm_helper",
        "rate_limit",
        user.uuid,
        llm_config.name,
        Time.now.utc.strftime("%Y%m%d")
      ].cache_key
      allow(Canvas.redis).to receive(:get).with(cache_key).and_return("5")
      expect { |b| InstLLMHelper.with_rate_limit(user:, llm_config:, &b) }.to yield_control
    end

    it "decrements the cache key if an error is raised" do
      cache_key = [
        "inst_llm_helper",
        "rate_limit",
        user.uuid,
        llm_config.name,
        Time.now.utc.strftime("%Y%m%d")
      ].cache_key
      allow(Canvas.redis).to receive(:get).with(cache_key).and_return("5")
      expect(Canvas.redis).to receive(:decr).with(cache_key)

      expect do
        InstLLMHelper.with_rate_limit(user:, llm_config:) do
          raise StandardError, "test error"
        end
      end.to raise_error(StandardError, "test error")
    end
  end
end
