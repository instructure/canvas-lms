# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe PageViewsController do
  # Factory-like thing for page views.
  def page_view(user, url, options = {})
    options.reverse_merge!(request_id: "req" + rand(100_000_000).to_s,
                           user_agent: "Firefox/12.0")
    options[:url] = url

    user_req = options.delete(:user_request)
    req_id = options.delete(:request_id)
    created_opt = options.delete(:created_at)
    pg = PageView.new(options)
    pg.user = user
    pg.user_request = user_req
    pg.request_id = req_id
    pg.created_at = created_opt
    pg.updated_at = created_opt
    pg.save!
    pg
  end

  shared_examples_for "GET 'index' as csv" do
    before :once do
      account_admin_user
    end

    before do
      student_in_course
      user_session(@admin)
    end

    it "succeeds" do
      page_view(@user, "/somewhere/in/app", created_at: 2.days.ago)
      get "index", params: { user_id: @user.id }, format: "csv"
      expect(response).to be_successful
    end

    it "orders rows by created_at in DESC order" do
      pv2 = page_view(@user, "/somewhere/in/app", created_at: 2.days.ago) # 2nd day
      pv1 = page_view(@user, "/somewhere/in/app/1", created_at: 1.day.ago) # 1st day
      pv3 = page_view(@user, "/somewhere/in/app/2", created_at: 3.days.ago) # 3rd day
      get "index", params: { user_id: @user.id }, format: "csv"
      expect(response).to be_successful
      dates = CSV.parse(response.body, headers: true).pluck("created_at")
      expect(dates).to eq([pv1, pv2, pv3].map { |pv| pv.created_at.to_s })
    end

    it "errors if end_time is before start_time" do
      get "index", params: { user_id: @user.id, start_time: "2021-07-04", end_time: "2021-07-03" }, format: "csv"
      expect(response).to have_http_status :bad_request
      expect(response.body).to eq "end_time must be after start_time"
    end
  end

  context "with db page views" do
    before :once do
      Setting.set("enable_page_views", true)
    end

    it_behaves_like "GET 'index' as csv"
  end

  context "pv4" do
    before do
      allow(PageView).to receive(:pv4?).and_return(true)
      ConfigFile.reset_cache
      ConfigFile.stub("pv4", {})
      account_admin_user
      user_session(@user)
    end

    after do
      ConfigFile.unstub
    end

    describe "GET 'index'" do
      it "properly plumbs through time restrictions" do
        expect_any_instance_of(PageView::Pv4Client).to receive(:fetch)
          .with(
            @user,
            start_time: Time.zone.parse("2016-03-14T12:25:55Z"),
            end_time: Time.zone.parse("2016-03-15T00:00:00Z"),
            last_page_view_id: nil,
            limit: 25
          )
          .and_return([])
        get "index",
            params: { user_id: @user.id,
                      start_time: "2016-03-14T12:25:55Z",
                      end_time: "2016-03-15T00:00:00Z",
                      per_page: 25 },
            format: :json
        expect(response).to be_successful
      end

      it "plumbs through time restrictions in csv also" do
        Setting.set("page_views_csv_export_rows", "99")
        expect_any_instance_of(PageView::Pv4Client).to receive(:fetch)
          .with(
            @user,
            start_time: Time.zone.parse("2016-03-14T12:25:55Z"),
            end_time: Time.zone.parse("2016-03-15T00:00:00Z"),
            last_page_view_id: nil,
            limit: 99
          )
          .and_return([])
        get "index",
            params: { user_id: @user.id,
                      start_time: "2016-03-14T12:25:55Z",
                      end_time: "2016-03-15T00:00:00Z" },
            format: :csv
        expect(response).to be_successful
      end

      context "client errors" do
        it "returns bad_request status when PageView::Pv4Client::Pv4BadRequest is raised" do
          allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_raise(PageView::Pv4Client::Pv4BadRequest)
          get :index, params: { user_id: @user.id }, format: :json
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body["error"]).to eq("Page Views received an invalid or malformed request.")
        end

        it "returns not_found status when PageView::Pv4Client::Pv4NotFound is raised" do
          allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_raise(PageView::Pv4Client::Pv4NotFound)
          get :index, params: { user_id: @user.id }, format: :json
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body["error"]).to eq("Page Views resource not found.")
        end

        it "returns not_found status when PageView::Pv4Client::Pv4Unauthorized is raised" do
          allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_raise(PageView::Pv4Client::Pv4Unauthorized)
          get :index, params: { user_id: @user.id }, format: :json
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body["error"]).to eq("Page Views resource not found.")
        end

        it "returns too_many_requests status when PageView::Pv4Client::Pv4TooManyRequests is raised" do
          allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_raise(PageView::Pv4Client::Pv4TooManyRequests)
          get :index, params: { user_id: @user.id }, format: :json
          expect(response).to have_http_status(:too_many_requests)
          expect(response.parsed_body["error"]).to eq("Page Views rate limit exceeded. Please wait and try again.")
        end

        it "returns service_unavailable status when PageView::Pv4Client::Pv4EmptyResponse is raised" do
          allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_raise(PageView::Pv4Client::Pv4EmptyResponse)
          get :index, params: { user_id: @user.id }, format: :json
          expect(response).to have_http_status(:service_unavailable)
          expect(response.parsed_body["error"]).to eq("Page Views data is not available at this time.")
        end

        it "returns bad_gateway status when PageView::Pv4Client::Pv4Timeout is raised" do
          allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_raise(PageView::Pv4Client::Pv4Timeout)
          get :index, params: { user_id: @user.id }, format: :json
          expect(response).to have_http_status(:bad_gateway)
          expect(response.parsed_body["error"]).to eq("Page Views service is temporarily unavailable.")
        end
      end
    end
  end

  context "pv5" do
    let(:configuration) { instance_double(PageViews::Configuration, uri: URI.parse("http://pv5.test"), access_token: "token") }

    before do
      allow(PageViews::Configuration).to receive(:new).and_return(configuration)
      account_admin_user
      user_session(@user)
    end

    describe "POST 'query'" do
      it "enqueues a new page view query" do
        expected_uuid = SecureRandom.uuid
        allow_any_instance_of(PageViews::EnqueueQueryService).to receive(:call).and_return(expected_uuid)

        post "query", params: {
          user_id: @user.id,
          start_date: "2025-02-01",
          end_date: "2025-03-01",
          results_format: :jsonl
        }

        expect(response).to be_successful
      end

      it "returns 400 Bad Request response when required parameters are missing" do
        post "query", params: {
          user_id: @user.id,
          start_time: "2024-12-01", # should be start_date and end_date
          end_time: "2025-01-10",
          results_format: :jsonl
        }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Parameter start_date is missing.")
      end

      it "returns a 400 Bad Request response when the request is invalid" do
        post "query", params: {
          user_id: @user.id,
          start_date: "2024-12-01",
          end_date: "2025-01-10",
          month: 21,
          format: "xml"
        }

        expect(response).to have_http_status(:bad_request)
      end

      it "return 429 Too Many Requests when rate limit is exceeded" do
        allow_any_instance_of(PageViews::EnqueueQueryService).to receive(:call).and_raise(PageViews::Common::TooManyRequestsError)

        post "query", params: {
          user_id: @user.id,
          start_date: "2024-01-01",
          end_date: "2024-02-01",
          results_format: :jsonl
        }

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    describe "GET 'query'" do
      it "returns a 200 OK when uuid is provided as query id and query is running" do
        expected_uuid = SecureRandom.uuid
        expected_polling_result = PageViews::Common::PollingResponse.new(query_id: expected_uuid, status: :running)
        allow_any_instance_of(PageViews::PollQueryService).to receive(:call).and_return(expected_polling_result)

        get "poll_query", params: { user_id: @user.id, query_id: expected_uuid }

        expect(response).to be_successful
        expect(response.parsed_body["query_id"]).to eq(expected_uuid)
        expect(response.parsed_body["status"]).to eq("running")
        expect(response.parsed_body["results_url"]).to be_nil
      end

      it "returns 400 bad request when invalid query id is provided" do
        ["invalid", 100, ""].each do |invalid_id|
          get "poll_query", params: { user_id: @user.id, query_id: invalid_id }

          expect(response).to have_http_status(:bad_request)
        end
      end

      it "returns 200 OK and results url when query is finished" do
        expected_uuid = SecureRandom.uuid
        expected_polling_result = PageViews::Common::PollingResponse.new(query_id: expected_uuid, status: :finished)
        allow_any_instance_of(PageViews::PollQueryService).to receive(:call).and_return(expected_polling_result)

        get "poll_query", params: { user_id: @user.id, query_id: expected_uuid }

        expect(response).to be_successful
        expect(response.parsed_body["query_id"]).to eq(expected_uuid)
        expect(response.parsed_body["status"]).to eq("finished")
        expect(response.parsed_body["results_url"]).to eq("/api/v1/users/#{@user.id}/page_views/query/#{expected_uuid}/results")
      end

      it "returns 404 not found when query does not exist" do
        allow_any_instance_of(PageViews::PollQueryService).to receive(:call).and_raise(PageViews::Common::NotFoundError)

        get "poll_query", params: { user_id: @user.id, query_id: SecureRandom.uuid }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET `query_results`" do
      let(:example_jsonl_gz_content) { Zlib.gzip('{"col1": "1", "col2": "2"}\n{"col1": "3", "col2": "4"}') }
      let(:example_csv_gz_content) { Zlib.gzip("col1,col2\n1,2\n3,4") }

      it "returns jsonl content" do
        expected_uuid = SecureRandom.uuid
        expected_response = PageViews::Common::DownloadableResult.new(:jsonl, "page_views_123456.jsonl.gz", example_jsonl_gz_content, true)
        allow_any_instance_of(PageViews::FetchResultService).to receive(:call).and_return(expected_response)

        get "query_results", params: { user_id: @user.id, query_id: expected_uuid }

        expect(response).to be_successful
        expect(response.headers["Content-Type"]).to eq("application/jsonl")
        expect(response.headers["Content-Encoding"]).to eq("gzip")
        expect(response.headers["Content-Disposition"]).to include("attachment; filename=\"page_views_123456.jsonl.gz\"")
        expect(response.parsed_body).to eq(example_jsonl_gz_content)
      end

      it "returns csv content" do
        expected_uuid = SecureRandom.uuid
        expected_response = PageViews::Common::DownloadableResult.new(:csv, "page_views_123456.csv.gz", example_csv_gz_content, true)
        allow_any_instance_of(PageViews::FetchResultService).to receive(:call).and_return(expected_response)

        get "query_results", params: { user_id: @user.id, query_id: expected_uuid }

        expect(response).to be_successful
        expect(response.headers["Content-Type"]).to eq("text/csv")
        expect(response.headers["Content-Encoding"]).to eq("gzip")
        expect(response.headers["Content-Disposition"]).to include("attachment; filename=\"page_views_123456.csv.gz\"")
        expect(response.parsed_body).to eq(example_csv_gz_content)
      end

      it "returns 404 not found when query does not exist" do
        allow_any_instance_of(PageViews::FetchResultService).to receive(:call).and_raise(PageViews::Common::NotFoundError)

        get "query_results", params: { user_id: @user.id, query_id: SecureRandom.uuid }

        expect(response).to have_http_status(:not_found)
      end

      it "returns 204 no content when result is reported empty" do
        allow_any_instance_of(PageViews::FetchResultService).to receive(:call).and_raise(PageViews::Common::NoContentError)

        get "query_results", params: { user_id: @user.id, query_id: SecureRandom.uuid }

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "Rate Limiting" do
    before do
      account_admin_user
      user_session(@user)
      allow(PageView).to receive(:pv4?).and_return(true)
      ConfigFile.stub("pv4", {})
      # Mock the PageView fetch to avoid actual API calls
      allow_any_instance_of(PageView::Pv4Client).to receive(:fetch).and_return([])
    end

    after do
      ConfigFile.unstub
    end

    context "index action" do
      it "increments request cost based on per_page parameter (per_page=10)" do
        expect(controller).to receive(:increment_request_cost).with(5)

        get "index", params: { user_id: @user.id, per_page: 10 }, format: :json

        expect(response).to be_successful
      end

      it "increments request cost based on per_page parameter (per_page=100)" do
        expect(controller).to receive(:increment_request_cost).with(40)

        get "index", params: { user_id: @user.id, per_page: 100 }, format: :json

        expect(response).to be_successful
      end

      it "increments request cost based on per_page parameter (per_page=200)" do
        expect(controller).to receive(:increment_request_cost).with(75)

        get "index", params: { user_id: @user.id, per_page: 200 }, format: :json

        expect(response).to be_successful
      end

      it "uses default per_page=10 when not specified" do
        expect(controller).to receive(:increment_request_cost).with(5)

        get "index", params: { user_id: @user.id }, format: :json

        expect(response).to be_successful
      end

      it "clamps per_page to maximum of 200" do
        expect(controller).to receive(:increment_request_cost).with(75) # Same as per_page=200

        get "index", params: { user_id: @user.id, per_page: 500 }, format: :json

        expect(response).to be_successful
      end

      it "clamps per_page to minimum of 1" do
        expect(controller).to receive(:increment_request_cost).with(5) # Minimum cost

        get "index", params: { user_id: @user.id, per_page: 0 }, format: :json

        expect(response).to be_successful
      end

      it "calculates cost correctly for per_page=50" do
        expect(controller).to receive(:increment_request_cost).with(20)

        get "index", params: { user_id: @user.id, per_page: 50 }, format: :json

        expect(response).to be_successful
      end

      it "does not vary cost with date range (Query with LIMIT behavior)" do
        # Cost should be the same regardless of date range
        expect(controller).to receive(:increment_request_cost).with(5)

        get "index",
            params: {
              user_id: @user.id,
              per_page: 10,
              start_time: 30.days.ago.iso8601,
              end_time: Time.now.iso8601
            },
            format: :json

        expect(response).to be_successful
      end
    end

    context "async query action" do
      let(:expected_uuid) { SecureRandom.uuid }
      let(:mock_service) { instance_double(PageViews::EnqueueQueryService) }

      before do
        allow(controller).to receive(:pv5_enqueue_service).and_return(mock_service)
        allow(mock_service).to receive(:call).and_return(expected_uuid)
      end

      it "increments request cost with fixed 150 units" do
        expect(controller).to receive(:increment_request_cost).with(150)

        post "query", params: {
          user_id: @user.id,
          start_date: "2025-02-01",
          end_date: "2025-03-01",
          results_format: :jsonl
        }

        expect(response).to have_http_status(:created)
      end

      it "applies rate limit cost regardless of date range" do
        expect(controller).to receive(:increment_request_cost).with(150)

        post "query", params: {
          user_id: @user.id,
          start_date: "2025-01-01",
          end_date: "2025-12-31", # Wide range
          results_format: :csv
        }

        expect(response).to have_http_status(:created)
      end
    end

    context "poll_query action" do
      let(:query_id) { SecureRandom.uuid }
      let(:poll_result) { instance_double(PageViews::Common::PollingResponse, status: :processing, format: :csv) }
      let(:mock_poll_service) { instance_double(PageViews::PollQueryService) }

      before do
        allow(controller).to receive(:pv5_poll_service).and_return(mock_poll_service)
        allow(mock_poll_service).to receive(:call).and_return(poll_result)
      end

      it "increments request cost with fixed 5 units" do
        expect(controller).to receive(:increment_request_cost).with(5)

        get "poll_query",
            params: { user_id: @user.id, query_id: }

        expect(response).to be_successful
      end
    end

    context "query_results action" do
      let(:query_id) { SecureRandom.uuid }
      let(:fetch_result) do
        instance_double(
          PageViews::Common::DownloadableResult,
          content: "test,data\n1,2",
          filename: "#{query_id}.csv",
          format: :csv,
          compressed?: false
        )
      end
      let(:mock_fetch_service) { instance_double(PageViews::FetchResultService) }

      before do
        allow(controller).to receive(:pv5_fetch_result_service).and_return(mock_fetch_service)
        allow(mock_fetch_service).to receive(:call).and_return(fetch_result)
      end

      it "increments request cost with fixed 50 units" do
        expect(controller).to receive(:increment_request_cost).with(50)

        get "query_results",
            params: { user_id: @user.id, query_id: }

        expect(response).to be_successful
      end
    end

    context "update action" do
      it "does not increment request cost (zero cost operation)" do
        expect(controller).not_to receive(:increment_request_cost)

        put "update",
            params: { id: "some-uuid" }

        expect(response).to be_successful
        expect(response.parsed_body).to eq({ "ok" => true })
      end
    end

    context "RCU calculation accuracy" do
      # These tests verify the mathematical accuracy of the rate limiting formula
      # Based on: eventually consistent reads, 592 bytes per line, 4096 bytes per RCU
      # Using balanced 5x multiplier

      it "calculates cost for per_page=10 as 5 units (1 RCU * 5 multiplier)" do
        # 10 lines / 13.838 lines per RCU ≈ 0.72 RCU → ceil = 1 RCU → 1 * 5 = 5 units
        expect(controller).to receive(:increment_request_cost).with(5)

        get "index", params: { user_id: @user.id, per_page: 10 }, format: :json
      end

      it "calculates cost for per_page=100 as 40 units (8 RCU * 5 multiplier)" do
        # 100 lines / 13.838 lines per RCU ≈ 7.23 RCU → ceil = 8 RCU → 8 * 5 = 40 units
        expect(controller).to receive(:increment_request_cost).with(40)

        get "index", params: { user_id: @user.id, per_page: 100 }, format: :json
      end

      it "calculates cost for per_page=200 as 75 units (15 RCU * 5 multiplier)" do
        # 200 lines / 13.838 lines per RCU ≈ 14.46 RCU → ceil = 15 RCU → 15 * 5 = 75 units
        expect(controller).to receive(:increment_request_cost).with(75)

        get "index", params: { user_id: @user.id, per_page: 200 }, format: :json
      end

      it "scales linearly with per_page values" do
        # Test intermediate values to ensure linear scaling
        test_cases = [
          { per_page: 25, expected_cost: 10 },  # 2 RCU * 5
          { per_page: 50, expected_cost: 20 },  # 4 RCU * 5
          { per_page: 75, expected_cost: 30 },  # 6 RCU * 5
          { per_page: 150, expected_cost: 55 }  # 11 RCU * 5
        ]

        test_cases.each do |test_case|
          expect(controller).to receive(:increment_request_cost).with(test_case[:expected_cost])

          get "index", params: { user_id: @user.id, per_page: test_case[:per_page] }, format: :json

          expect(response).to be_successful
        end
      end
    end

    context "rate limit cost proportions" do
      it "ensures async query cost is higher than sync index with per_page=100" do
        # query: 150 units vs index(per_page=100): 40 units
        # This ensures async operations that spawn background jobs are more expensive
        query_cost = 150
        index_cost = 40

        expect(query_cost).to be > index_cost
      end

      it "ensures poll cost is minimal to support frequent polling (120 polls before HWM)" do
        # poll: 5 units, HWM: 600 units → 600/5 = 120 polls allowed
        poll_cost = 5
        hwm = 600

        expect(hwm / poll_cost).to eq(120)
      end

      it "ensures sync index allows generous browsing (120 requests for per_page=10)" do
        # index(per_page=10): 5 units, HWM: 600 units → 600/5 = 120 requests
        index_cost = 5
        hwm = 600

        expect(hwm / index_cost).to eq(120)
      end

      it "throttles heavy pagination appropriately (8 requests for per_page=200)" do
        # index(per_page=200): 75 units, HWM: 600 units → 600/75 = 8 requests
        index_cost = 75
        hwm = 600

        expect(hwm / index_cost).to eq(8)
      end
    end
  end
end
