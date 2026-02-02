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

describe PageViews::EnqueueBatchQueryService do
  let(:configuration) { instance_double(PageViews::Configuration, uri: URI.parse("http://pv5.instructure.com"), access_token: "token") }
  let(:account) { instance_double(Account, id: 1, uuid: "abc") }
  let(:admin) { instance_double(User, global_id: 1, shard: Shard.default, root_account_ids: [account.id]) }
  let(:user1) { instance_double(User, id: 2, global_id: 2, shard: Shard.default, root_account_ids: [account.id]) }
  let(:user2) { instance_double(User, id: 3, global_id: 3, shard: Shard.default, root_account_ids: [account.id]) }
  let(:service) { PageViews::EnqueueBatchQueryService.new(configuration, requestor_user: admin) }

  before do
    allow(Account).to receive(:find_cached).with(1).and_return(account)
    allow(user1).to receive(:is_a?).with(User).and_return(true)
    allow(user2).to receive(:is_a?).with(User).and_return(true)
  end

  it "returns query ID from API response" do
    expected_uuid = SecureRandom.uuid
    response = double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/#{expected_uuid}" })
    allow(CanvasHttp).to receive(:post).and_yield(response)

    query_id = service.call("2025-03-01", "2025-06-01", [user1, user2], "csv")

    expect(query_id).to eq(expected_uuid)
  end

  it "sends batch query request to correct endpoint with user_ids array" do
    response = double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/123" })
    allow(CanvasHttp).to receive(:post).and_yield(response)

    service.call("2025-03-01", "2025-06-01", [user1, user2], "csv")

    expect(CanvasHttp).to have_received(:post) do |uri, _headers, options|
      expect(uri).to eq("http://pv5.instructure.com/api/v5/pageviews/batch-query")
      expect(options[:content_type]).to eq("application/json")

      body = JSON.parse(options[:body])
      expect(body["user_ids"]).to be_an(Array)
      expect(body["user_ids"].length).to eq(2)
      expect(body["start_date"]).to eq("2025-03-01")
      expect(body["end_date"]).to eq("2025-06-01")
      expect(body["format"]).to eq("csv")
    end
  end

  it "raises ArgumentError when users is not an array" do
    allow(user1).to receive(:is_a?).with(Array).and_return(false)

    expect do
      service.call("2025-03-01", "2025-04-01", user1, "csv")
    end.to raise_error(ArgumentError, "users must be an array")
  end

  it "raises ArgumentError when users array is empty" do
    expect do
      service.call("2025-03-01", "2025-04-01", [], "csv")
    end.to raise_error(ArgumentError, "users cannot be empty")
  end

  it "raises ArgumentError when not all elements are User objects" do
    expect do
      service.call("2025-03-01", "2025-04-01", [user1, "not a user"], "csv")
    end.to raise_error(ArgumentError, "all elements must be User objects")
  end

  it "raises ArgumentError when start_date is invalid" do
    expect do
      service.call("", "2025-04-01", [user1], "csv")
    end.to raise_error(ArgumentError, "Date must be in YYYY-MM-DD format")
  end

  it "raises ArgumentError when end_date is invalid" do
    expect do
      service.call("2025-03-01", "", [user1], "csv")
    end.to raise_error(ArgumentError, "Date must be in YYYY-MM-DD format")
  end

  it "raises ArgumentError when format is invalid" do
    expect do
      service.call("2025-03-01", "2025-04-01", [user1], "xml")
    end.to raise_error(ArgumentError, "Format must be one of csv, jsonl")
  end

  it "accepts valid csv format" do
    response = double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/123" })
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2025-03-01", "2025-04-01", [user1], "csv")
    end.not_to raise_error
  end

  it "accepts valid jsonl format" do
    response = double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/123" })
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2025-03-01", "2025-04-01", [user1], "jsonl")
    end.not_to raise_error
  end

  it "raises InvalidRequestError when PV5 API returns query parameters are invalid" do
    response = double(code: 400, body: '{"errors": ["invalid root account uuid"]}')
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", [user1, user2], "jsonl")
    end.to raise_error(PageViews::Common::InvalidRequestError) do |error|
      expect(error.message).to eq("Invalid request: invalid root account uuid")
    end
  end

  it "raises NotFoundError when PV5 API returns not found" do
    response = double(code: 404)
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", [user1, user2], "jsonl")
    end.to raise_error(PageViews::Common::NotFoundError) do |error|
      expect(error.message).to eq("Resource not found")
    end
  end

  it "raises TooManyRequestsError when PV5 API rate limit is exceeded" do
    response = double(code: 429)
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", [user1, user2], "csv")
    end.to raise_error(PageViews::Common::TooManyRequestsError) do |error|
      expect(error.message).to eq("Rate limit exceeded")
    end
  end

  it "raises InternalServerError when PV5 API returns internal server error" do
    response = double(code: 500)
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", [user1, user2], "csv")
    end.to raise_error(PageViews::Common::InternalServerError) do |error|
      expect(error.message).to eq("Internal server error")
    end
  end

  it "includes request id in headers" do
    expected_request_id = SecureRandom.uuid
    allow(RequestContext::Generator).to receive(:request_id).and_return(expected_request_id)
    allow(CanvasHttp).to receive(:post).and_yield(double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/123456" }))

    service.call("2025-03-01", "2025-06-01", [user1, user2], "csv")

    expect(CanvasHttp).to have_received(:post).with(anything, hash_including("X-Request-Context-Id" => expected_request_id), anything)
  end

  it "includes requestor's global user ID in headers when provided" do
    allow(CanvasHttp).to receive(:post).and_yield(double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/123456" }))

    service.call("2025-03-01", "2025-06-01", [user1, user2], "csv")

    expect(CanvasHttp).to have_received(:post).with(anything, hash_including("X-Canvas-User-Id" => "1"), anything)
  end

  it "collects all unique root account UUIDs when users have multiple root accounts" do
    account2 = instance_double(Account, id: 2, uuid: "def")
    account3 = instance_double(Account, id: 3, uuid: "ghi")

    user_multi_accounts = instance_double(User, id: 4, global_id: 4, shard: Shard.default, root_account_ids: [1, 2])
    user_shared_account = instance_double(User, id: 5, global_id: 5, shard: Shard.default, root_account_ids: [2, 3])

    allow(user_multi_accounts).to receive(:is_a?).with(User).and_return(true)
    allow(user_shared_account).to receive(:is_a?).with(User).and_return(true)
    allow(Account).to receive(:find_cached).with(2).and_return(account2)
    allow(Account).to receive(:find_cached).with(3).and_return(account3)

    response = double(code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/batch-query/123" })
    allow(CanvasHttp).to receive(:post).and_yield(response)

    service.call("2025-03-01", "2025-06-01", [user_multi_accounts, user_shared_account], "csv")

    expect(CanvasHttp).to have_received(:post) do |_uri, _headers, options|
      body = JSON.parse(options[:body])
      expect(body["root_account_uuids"]).to be_an(Array)
      expect(body["root_account_uuids"].length).to eq(3)
      expect(body["root_account_uuids"]).to contain_exactly("abc", "def", "ghi")
    end
  end
end
