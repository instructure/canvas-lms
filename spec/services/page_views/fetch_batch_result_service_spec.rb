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

describe PageViews::FetchBatchResultService do
  let(:configuration) { instance_double(PageViews::Configuration, uri: URI.parse("http://pv5.instructure.com"), access_token: "token") }
  let(:service) { PageViews::FetchBatchResultService.new(configuration) }
  let(:account) { instance_double(Account, id: 1, uuid: "abc") }
  let(:user) { instance_double(User, global_id: 1, shard: Shard.default, root_account_ids: [account.id]) }

  let(:example_jsonl_gz_response) do
    instance_double(Net::HTTPResponse,
                    code: 200,
                    body: Zlib.gzip('{"col1": "1", "col2": "2"}'),
                    header: {
                      "Content-Type" => "application/jsonl;charset=utf-8",
                      "Content-Disposition" => 'attachment; filename="page_views_123456.jsonl.gz"',
                      "Content-Encoding" => "gzip"
                    },
                    "decode_content=": false)
  end

  let(:example_csv_gz_response) do
    instance_double(Net::HTTPResponse,
                    code: 200,
                    body: Zlib.gzip("col1,col2\n1,2\n3,4\n"),
                    header: {
                      "Content-Type" => "text/csv",
                      "Content-Disposition" => 'attachment; filename="page_views_123456.csv.gz"',
                      "Content-Encoding" => "gzip"
                    },
                    "decode_content=": false)
  end

  let(:example_csv_response) do
    instance_double(Net::HTTPResponse,
                    code: 200,
                    body: Zlib.gzip("col1,col2\n1,2\n3,4\n"),
                    header: {
                      "Content-Type" => "text/csv",
                      "Content-Disposition" => 'attachment; filename="page_views_123456.csv"'
                    },
                    "decode_content=": false)
  end

  let(:example_invalid_format_response) do
    instance_double(Net::HTTPResponse,
                    code: 200,
                    body: Zlib.gzip("col1,col2\n1,2\n3,4\n"),
                    header: {
                      "Content-Type" => "text/html",
                      "Content-Disposition" => 'attachment; filename="page_views_123456.txt.gz"'
                    },
                    "decode_content=": false)
  end

  before do
    allow(Account).to receive(:find_cached).with(1).and_return(account)
  end

  it "sends request to correct batch-query results endpoint" do
    expected_uuid = SecureRandom.uuid
    allow(CanvasHttp).to receive(:get).and_yield(example_csv_gz_response)

    service.call(expected_uuid)

    expect(CanvasHttp).to have_received(:get).with("http://pv5.instructure.com/api/v5/pageviews/batch-query/#{expected_uuid}/results", anything)
  end

  it "returns compressed jsonl result" do
    allow(CanvasHttp).to receive(:get).and_yield(example_jsonl_gz_response)

    result = service.call("123456")

    expect(result).to be_a(PageViews::Common::DownloadableResult)
    expect(result.format).to eq(:jsonl)
    expect(result.filename).to eq("page_views_123456.jsonl.gz")
    expect(result.content).to eq(example_jsonl_gz_response.body)
  end

  it "returns compressed csv result" do
    allow(CanvasHttp).to receive(:get).and_yield(example_csv_gz_response)

    result = service.call("123456")

    expect(result).to be_a(PageViews::Common::DownloadableResult)
    expect(result.format).to eq(:csv)
    expect(result.filename).to eq("page_views_123456.csv.gz")
    expect(result.content).to eq(example_csv_gz_response.body)
  end

  it "returns a csv result" do
    allow(CanvasHttp).to receive(:get).and_yield(example_csv_response)

    result = service.call("123456")

    expect(result).to be_a(PageViews::Common::DownloadableResult)
    expect(result.format).to eq(:csv)
    expect(result.filename).to eq("page_views_123456.csv")
    expect(result.content).to eq(example_csv_response.body)
  end

  it "raises error when invalid format is returned" do
    allow(CanvasHttp).to receive(:get).and_yield(example_invalid_format_response)

    expect { service.call("123456") }.to raise_error(PageViews::Common::InvalidResultError)
  end

  it "raises error when there is no content disposition header" do
    allow(CanvasHttp).to receive(:get).and_yield(
      instance_double(Net::HTTPResponse,
                      code: 200,
                      body: Zlib.gzip('{"col1": "1", "col2": "2"}'),
                      header: {
                        "Content-Type" => "application/octet-stream",
                      },
                      "decode_content=": false)
    )

    expect { service.call("123456") }.to raise_error(PageViews::Common::InvalidResultError)
  end

  it "raises error when query id does not exist" do
    allow(CanvasHttp).to receive(:get).and_yield(instance_double(Net::HTTPResponse, code: 404))

    expect { service.call("123456") }.to raise_error(PageViews::Common::NotFoundError)
  end

  it "raises no content error when no content is available yet" do
    allow(CanvasHttp).to receive(:get).and_yield(instance_double(Net::HTTPResponse, code: 204))
    expect { service.call("123456") }.to raise_error(PageViews::Common::NoContentError)
  end

  it "includes request id in headers" do
    expected_request_id = SecureRandom.uuid
    allow(RequestContext::Generator).to receive(:request_id).and_return(expected_request_id)
    allow(CanvasHttp).to receive(:get).and_yield(example_jsonl_gz_response)

    service.call("123456")

    expect(CanvasHttp).to have_received(:get).with(anything, hash_including("X-Request-Context-Id" => expected_request_id))
  end
end
