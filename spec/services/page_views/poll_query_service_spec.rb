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

describe PageViews::PollQueryService do
  let(:configuration) { instance_double(PageViews::Configuration, uri: URI.parse("http://pv5.instructure.com"), access_token: "token") }
  let(:service) { PageViews::PollQueryService.new(configuration) }
  let(:account) { instance_double(Account, id: 1, uuid: "abc") }
  let(:user) { instance_double(User, global_id: 1, shard: Shard.default, root_account_ids: [account.id]) }

  before do
    allow(Account).to receive(:find_cached).with(1).and_return(account)
  end

  it "returns query is running" do
    expected_uuid = SecureRandom.uuid
    expected_json = '{"status": "RUNNING", "query_id": "' + expected_uuid + '"}'
    response = instance_double(Net::HTTPResponse, code: 202, body: expected_json)
    allow(CanvasHttp).to receive(:get).and_yield(response)

    result = service.call(expected_uuid)

    expect(result.status).to eq(:running)
    expect(result.query_id).to eq(expected_uuid)
  end

  it "returns an error" do
    expected_uuid = SecureRandom.uuid
    response = instance_double(Net::HTTPResponse,
                               code: 202,
                               body: '{"status": "FAILED", "query_id": "' + expected_uuid + '", "errorCode": "RESULT_SIZE_LIMIT_EXCEEDED"}')
    allow(CanvasHttp).to receive(:get).and_yield(response)

    result = service.call(expected_uuid)

    expect(result.status).to eq(:failed)
    expect(result.error_code).to eq("RESULT_SIZE_LIMIT_EXCEEDED")
  end

  it "passes through unknown error codes as-is" do
    expected_uuid = SecureRandom.uuid
    response = instance_double(Net::HTTPResponse,
                               code: 202,
                               body: '{"status": "FAILED", "query_id": "' + expected_uuid + '", "errorCode": "SOME_NEW_UNKNOWN_ERROR_CODE"}')
    allow(CanvasHttp).to receive(:get).and_yield(response)

    result = service.call(expected_uuid)

    expect(result.status).to eq(:failed)
    expect(result.error_code).to eq("SOME_NEW_UNKNOWN_ERROR_CODE")
  end

  it "returns nil when status is failed but no error code provided" do
    expected_uuid = SecureRandom.uuid
    response = instance_double(Net::HTTPResponse,
                               code: 202,
                               body: '{"status": "FAILED", "query_id": "' + expected_uuid + '"}')
    allow(CanvasHttp).to receive(:get).and_yield(response)

    result = service.call(expected_uuid)

    expect(result.status).to eq(:failed)
    expect(result.error_code).to be_nil
  end

  it "returns results when query is finished" do
    expected_uuid = SecureRandom.uuid
    response = instance_double(Net::HTTPResponse,
                               code: 200,
                               header: { "Location" => "http://pv5.instructure.com/api/v5/pageviews/query/#{expected_uuid}/results" },
                               body: '{"status": "FINISHED", "query_id": "' + expected_uuid + '"}')
    allow(CanvasHttp).to receive(:get).and_yield(response)

    result = service.call(expected_uuid)

    expect(result.status).to eq(:finished)
  end

  it "raises not found error when query id doesn't exist" do
    response = instance_double(Net::HTTPResponse, code: 404)
    allow(CanvasHttp).to receive(:get).and_yield(response)

    expect do
      service.call("non_existing_id")
    end.to raise_error(PageViews::Common::NotFoundError) do |error|
      expect(error.message).to eq("Resource not found")
    end
  end

  it "raises invalid request error when query id is invalid" do
    response = instance_double(Net::HTTPResponse, code: 400, body: '{"errors": ["could not parse parameter queryId"]}')
    allow(CanvasHttp).to receive(:get).and_yield(response)

    expect do
      service.call("invalid_id")
    end.to raise_error(PageViews::Common::InvalidRequestError) do |error|
      expect(error.message).to eq("Invalid request: could not parse parameter queryId")
    end
  end

  it "raises internal server error when PV5 API returns internal server error" do
    response = instance_double(Net::HTTPResponse, code: 500)
    allow(CanvasHttp).to receive(:get).and_yield(response)

    expect do
      service.call("123456")
    end.to raise_error(PageViews::Common::InternalServerError) do |error|
      expect(error.message).to eq("Internal server error")
    end
  end

  it "includes request id in headers" do
    expected_request_id = SecureRandom.uuid
    allow(CanvasHttp).to receive(:get).and_yield(instance_double(Net::HTTPResponse, code: 200, body: "{}"))
    allow(RequestContext::Generator).to receive(:request_id).and_return(expected_request_id)

    service.call("123456")

    expect(CanvasHttp).to have_received(:get).with(anything, hash_including("X-Request-Context-Id" => expected_request_id))
  end
end
