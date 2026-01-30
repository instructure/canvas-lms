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

describe PageViews::EnqueueQueryService do
  let(:configuration) { instance_double(PageViews::Configuration, uri: URI.parse("http://pv5.instructure.com"), access_token: "token") }
  let(:account) { instance_double(Account, id: 1, uuid: "abc") }
  let(:admin) { instance_double(User, global_id: 1, shard: Shard.default, root_account_ids: [account.id]) }
  let(:user) { instance_double(User, global_id: 2, shard: Shard.default, root_account_ids: [account.id]) }
  let(:service) { PageViews::EnqueueQueryService.new(configuration, requestor_user: admin) }

  before do
    allow(Account).to receive(:find_cached).with(1).and_return(account)
    allow(user).to receive(:is_a?).with(User).and_return(true)
  end

  it "returns query's job ID" do
    response = instance_double(Net::HTTPResponse, code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/query/123456" })
    allow(CanvasHttp).to receive(:post).and_yield(response)

    query = service.call("2025-03-01", "2025-06-01", user, "csv")

    expect(query).to eq("123456")
  end

  it "raises ArgumentError when query params are invalid" do
    allow(CanvasHttp).to receive(:post)

    [
      ["2025-03-01", "2025-02-01", user, "csv"],
      ["2025-03-01", "2025-03-10", user, "csv"],
      ["2025-03--", "2025-02-01", user, "csv"],
      ["2025-03-01", "", user, "csv"],
      ["2025-03-01", "2025-04-01", nil, "csv"],
      ["2025-03-01", "2025-04-01", user, "xml"],
      ["2025-03-01T10:30:45", "2025-04-01", user, "csv"],
      ["2025-03-01", "2025-04-01T15:20:30", user, "csv"]
    ].each do |start_date, end_date, user, format|
      expect do
        service.call(start_date, end_date, user, format)
        expect(CanvasHttp).not_to have_received(:post)
      end.to raise_error(ArgumentError)
    end
  end

  it "raises InvalidRequestError when PV5 API returns query parameters are invalid" do
    response = instance_double(Net::HTTPResponse, code: 400, body: '{"errors": ["invalid root account uuid"]}')
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", user, "jsonl")
    end.to raise_error(PageViews::Common::InvalidRequestError) do |error|
      expect(error.message).to eq("Invalid request: invalid root account uuid")
    end
  end

  it "raises NotFoundError when PV5 API returns not found" do
    response = instance_double(Net::HTTPResponse, code: 404)
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", user, "jsonl")
    end.to raise_error(PageViews::Common::NotFoundError) do |error|
      expect(error.message).to eq("Resource not found")
    end
  end

  it "raises TooManyRequestsError when PV5 API rate limit is exceeded" do
    response = instance_double(Net::HTTPResponse, code: 429)
    allow(CanvasHttp).to receive(:post).and_yield(response)
    expect do
      service.call("2024-12-01", "2025-01-01", user, "csv")
    end.to raise_error(PageViews::Common::TooManyRequestsError) do |error|
      expect(error.message).to eq("Rate limit exceeded")
    end
  end

  it "raises InternalServerError when PV5 API returns internal server error" do
    response = instance_double(Net::HTTPResponse, code: 500)
    allow(CanvasHttp).to receive(:post).and_yield(response)

    expect do
      service.call("2024-12-01", "2025-01-01", user, "csv")
    end.to raise_error(PageViews::Common::InternalServerError) do |error|
      expect(error.message).to eq("Internal server error")
    end
  end

  it "includes request id in headers" do
    expected_request_id = SecureRandom.uuid
    allow(RequestContext::Generator).to receive(:request_id).and_return(expected_request_id)
    allow(CanvasHttp).to receive(:post).and_yield(instance_double(Net::HTTPResponse, code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/query/123456" }))

    service.call("2025-03-01", "2025-06-01", user, "csv")

    expect(CanvasHttp).to have_received(:post).with(anything, hash_including("X-Request-Context-Id" => expected_request_id), anything)
  end

  it "includes requestor's global user ID in headers when provided" do
    allow(CanvasHttp).to receive(:post).and_yield(instance_double(Net::HTTPResponse, code: 201, header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/query/123456" }))

    service.call("2025-03-01", "2025-06-01", user, "csv")

    expect(CanvasHttp).to have_received(:post).with(anything, hash_including("X-Canvas-User-Id" => "1"), anything)
  end
end
