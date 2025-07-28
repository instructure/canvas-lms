# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe PageView::Pv4Client do
  let(:pv4_object) do
    { "Z" => "canvas",
      "action" => "show",
      "agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.7",
      "app_server" => "app1234",
      "bytes" => "11441",
      "canvas_context_id" => "120000000000002",
      "canvas_context_type" => "Account",
      "client_ip" => "192.168.0.1",
      "controller" => "users",
      "e" => "1135368",
      "http_method" => "GET",
      "http_request" => "/accounts/2/users/1",
      "http_status" => "200",
      "interaction_seconds" => "5",
      "microseconds" => "6367549",
      "participated" => false,
      "request_id" => "2c2955f3-d114-4ac0-8101-b7e0138a1685",
      "root_account_id" => "120000000000002",
      "sessionid" => "c73d248f3e4cec530261c95232ba63fg",
      "timestamp" => "2015-11-05T17:01:20.306Z",
      "user_id" => "31410000000000028",
      "vhost" => "canvas.instructure.com" }.freeze
  end
  let(:client) { PageView::Pv4Client.new("http://pv4/", "token") }
  let(:account) { instance_double(Account, id: 1, uuid: "abc") }
  let(:user) { instance_double(User, global_id: 1, shard: Shard.default, root_account_ids: [account.id]) }

  before do
    allow(Account).to receive(:find_cached).with(1).and_return(account)
  end

  def stub_http_request(response)
    double = double(body: response.to_json, code: 200)
    allow(CanvasHttp).to receive(:get).and_return(double)
  end

  describe "#fetch" do
    it "returns page view objects" do
      stub_http_request("page_views" => [pv4_object])

      response = client.fetch(user)
      expect(response.length).to eq 1
      expect(response.first).to be_a PageView
      pv = response.first
      expect(pv.url).to eq "http://canvas.instructure.com/accounts/2/users/1"
      expect(pv.created_at).to eq Time.zone.parse("2015-11-05T17:01:20.306Z")
      expect(pv.session_id).to eq "c73d248f3e4cec530261c95232ba63fg"
      expect(pv.context_id).to eq 120_000_000_000_002
      expect(pv.context_type).to eq "Account"
      expect(pv.user_agent).to include("Safari")
      expect(pv.account_id).to eq 120_000_000_000_002
      expect(pv.user_id).to eq 31_410_000_000_000_028
      expect(pv.remote_ip).to eq "192.168.0.1"
      expect(pv.render_time).to eq 6.367549
    end

    it "formats url params correctly" do
      t = Time.zone.parse("2016-04-27")
      Timecop.freeze(t) do
        zone = ActiveSupport::TimeZone.new("America/Denver")
        start_time = Time.now.in_time_zone(zone)
        end_time = 5.minutes.from_now.in_time_zone(zone)

        expect_params = "?start_time=2016-04-27T00:00:00.000Z&end_time=2016-04-27T00:05:00.000Z&root_account_uuids=abc"
        expect_url = "http://pv4/users/1/page_views#{expect_params}"
        expect_header = { "Authorization" => "Bearer token" }

        res = double(body: { "page_views" => [pv4_object] }.to_json, code: 200)
        expect(CanvasHttp).to receive(:get).with(expect_url, expect_header).and_return(res)
        client.fetch(user, start_time:, end_time:)
      end
    end

    it "raises Pv4BadRequest when response code is 400" do
      response = double(body: "", code: 400)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4BadRequest, "invalid request"
      )
    end

    it "raises Pv4Unauthorized when response code is 401" do
      response = double(body: "", code: 401)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4Unauthorized, "unauthorized request"
      )
    end

    it "raises Pv4NotFound when response code is 404" do
      response = double(body: "", code: 404)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4NotFound, "resource not found"
      )
    end

    it "raises Pv4TooManyRequests when response code is 429" do
      response = double(body: "", code: 429)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4TooManyRequests, "rate limit exceeded"
      )
    end

    it "parses the JSON response when the body is valid JSON with page_views" do
      response = double(body: { "page_views" => [pv4_object] }.to_json, code: 200)
      allow(CanvasHttp).to receive(:get).and_return(response)

      result = client.fetch(user)
      expect(result.length).to eq 1
      expect(result.first).to be_a PageView
    end

    it "raises Pv4EmptyResponse when response body is empty" do
      response = double(body: "", code: 200)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4EmptyResponse, "the response is empty or does not contain expected keys"
      )
    end

    it "raises Pv4EmptyResponse when response body is invalid JSON" do
      response = double(body: "invalid json", code: 200)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4EmptyResponse, "the response is empty or does not contain expected keys"
      )
    end

    it "raises Pv4EmptyResponse when response body does not contain page_views" do
      response = double(body: { "other_key" => [pv4_object] }.to_json, code: 200)
      allow(CanvasHttp).to receive(:get).and_return(response)

      expect { client.fetch(user) }.to raise_error(
        PageView::Pv4Client::Pv4EmptyResponse, "the response is empty or does not contain expected keys"
      )
    end
  end

  describe "#for_user" do
    it "returns a paginatable object" do
      stub_http_request("page_views" => [pv4_object])

      result = client.for_user(user).paginate(per_page: 10)
      expect(result).to be_a(Array)
      expect(result.length).to eq 1
    end

    it "sends last_page_view_id when paginating" do
      stub_http_request("page_views" => [pv4_object])

      now = Time.now.utc
      result = client.for_user(user).paginate(per_page: 10)

      double = double(body: '{ "page_views": [] }', code: 200)
      expect(CanvasHttp).to receive(:get).with(
        "http://pv4/users/1/page_views?start_time=#{now.iso8601(PageView::Pv4Client::PRECISION)}&end_time=#{pv4_object["timestamp"]}&root_account_uuids=abc&last_page_view_id=#{pv4_object["request_id"]}&limit=10",
        { "Authorization" => "Bearer token" }
      ).and_return(double)
      client.for_user(user, oldest: now, newest: now)
            .paginate(page: result.next_page, per_page: 10)
    end
  end
end
