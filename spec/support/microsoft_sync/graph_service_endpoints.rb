# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

RSpec.shared_context "microsoft_sync_graph_service_endpoints" do
  include WebMock::API

  def json_response(status, body, extra_headers = {})
    {
      status:,
      body: body.to_json,
      headers: extra_headers.merge("Content-type" => "application/json")
    }
  end

  before do
    @url_logger = MicrosoftSync::GraphService::SpecHelper::UrlLogger.new

    WebMock.after_request do |request, response|
      @url_logger.log(request, response)
    end
  end

  after do
    @url_logger.verify_responses
    # Uncomment below when mock responses are actually valid. I plan to do those
    # in a later commit.
    # raise "Schema mismatch on the following: \n #{@url_logger.errors.to_yaml}" if @url_logger.errors.any?
  end

  before do
    WebMock.disable_net_connect!

    allow(MicrosoftSync::LoginService).to receive(:token).with("mytenant").and_return("mytoken")
    if url
      @url_logger.stub_request(http_method, url, response, url_variables, with_params)
    end

    allow(InstStatsd::Statsd).to receive(:increment).and_call_original
    allow(InstStatsd::Statsd).to receive(:count).and_call_original

    # Test retry on intermittent errors without internal retry
    stub_const("MicrosoftSync::GraphService::Http::DEFAULT_N_INTERMITTENT_RETRIES", 0)
  end

  after { WebMock.enable_net_connect! }

  let(:http) { MicrosoftSync::GraphService::Http.new("mytenant", extra_tag: "abc") }
  let(:endpoints) { described_class.new(http) }
  let(:url) { nil }
  let(:url_variables) { [] }

  let(:response) { json_response(200, response_body) }
  let(:with_params) { {} }

  # http_method, url, with_params, and reponse_body will be defined with let()s below

  let(:url_path_prefix_for_statsd) { URI.parse(url).path.split("/")[2] }

  shared_examples_for "a graph service endpoint" do |opts = {}|
    let(:statsd_tags) do
      {
        msft_endpoint: "#{http_method}_#{url_path_prefix_for_statsd}",
        status_code: response[:status].to_s,
        extra_tag: "abc",
      }
    end

    unless opts[:ignore_404]
      context "with a 404 status code" do
        let(:response) { json_response(404, error: { message: "uh-oh!" }) }

        it "raises an HTTPNotFound error" do
          expect { subject }.to raise_error(
            MicrosoftSync::Errors::HTTPNotFound,
            /Graph service returned 404 for tenant mytenant.*uh-oh!/
          )
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with("microsoft_sync.graph_service.notfound", tags: statsd_tags)
        end
      end
    end

    [400, 403, 409].each do |code|
      context "with a #{code} status code" do
        let(:response) { json_response(code, error: { message: "uh-oh!" }) }

        it "raises an HTTPInvalidStatus with the code and message" do
          expect { subject }.to raise_error(
            MicrosoftSync::Errors::HTTPInvalidStatus,
            /Graph service returned #{code} for tenant mytenant.*uh-oh!/
          )
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with("microsoft_sync.graph_service.error", tags: statsd_tags)
        end
      end
    end

    context "with a 429 status code" do
      let(:response) do
        json_response(429, { error: { message: "uh-oh!" } }, "Retry-After" => "2.128")
      end

      it 'raises an HTTPTooManyRequests error and increments a "throttled" counter' do
        expect { subject }.to raise_error(
          MicrosoftSync::Errors::HTTPTooManyRequests,
          /Graph service returned 429 for tenant mytenant.*uh-oh!/
        )
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.throttled", tags: statsd_tags)
      end

      it "includes the retry-after time in the error" do
        expect { subject }.to raise_error do |err|
          expect(err.retry_after_seconds).to eq(2.128)
        end
      end
    end

    context "with a Timeout::Error" do
      it 'increments an "intermittent" counter and bubbles up the error' do
        error = Timeout::Error.new
        expect(HTTParty).to receive(http_method.to_sym).and_raise error
        expect { subject }.to raise_error(error)
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "microsoft_sync.graph_service.intermittent",
          tags: statsd_tags.merge(status_code: "Timeout__Error")
        )
      end
    end

    context "with a 401 tenant unauthorized error" do
      let(:response) do
        json_response(401, error: {
                        code: "Authorization_IdentityNotFound",
                        message: "The identity of the calling application could not be established."
                      })
      end

      it "raises an ApplicationNotAuthorizedForTenant error" do
        klass = MicrosoftSync::GraphService::Http::ApplicationNotAuthorizedForTenant
        message = /make sure your admin has granted access/

        expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, message)

        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.error", tags: statsd_tags)
      end
    end

    context "with a 403 tenant unauthorized error" do
      let(:response) do
        json_response(403, error: {
                        code: "AccessDenied",
                        message: "Required roles claim values are not provided."
                      })
      end

      it "raises an ApplicationNotAuthorizedForTenant error" do
        expect { subject }.to raise_error do |e|
          expect(e).to be_a(MicrosoftSync::GraphService::Http::ApplicationNotAuthorizedForTenant)
          expect(e).to be_a(MicrosoftSync::Errors::GracefulCancelError)
        end
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.error", tags: statsd_tags)
      end
    end

    it "increments a success statsd metric on success" do
      subject
      expect(InstStatsd::Statsd).to have_received(:increment).with(
        "microsoft_sync.graph_service.success", tags: {
          msft_endpoint: "#{http_method}_#{url_path_prefix_for_statsd}",
          extra_tag: "abc",
          status_code: /^20.$/,
        }
      )
    end

    it "records time with a statsd time metric" do
      expect(InstStatsd::Statsd).to receive(:time).with(
        "microsoft_sync.graph_service.time",
        tags: {
          msft_endpoint: "#{http_method}_#{url_path_prefix_for_statsd}",
          extra_tag: "abc",
        }
      ).and_call_original
      subject
    end
  end

  shared_examples_for "a paginated list endpoint" do
    subject { endpoints.send(method_name, *method_args) }

    let(:http_method) { :get }
    let(:expected_first_page_results) { [{ "id" => "page_item1" }] }
    let(:response_body) { { "value" => expected_first_page_results } }

    it_behaves_like "a graph service endpoint"

    context "when no block is given" do
      it "returns the first page of items" do
        expect(subject).to eq(expected_first_page_results)
      end

      context "when a filter is used" do
        subject { endpoints.send(method_name, *method_args, filter: { "abc" => "d'ef" }) }

        let(:with_params) { { query: { "$filter" => "abc eq 'd''ef'" } } }

        it { is_expected.to eq(expected_first_page_results) }
      end

      context "when a filter and select are used" do
        subject do
          endpoints.send(
            method_name,
            *method_args,
            filter: { userPrincipalName: %w[user1@domain.com user2@domain.com] },
            select: %w[id userPrincipalName]
          )
        end

        let(:with_params) do
          {
            query: {
              "$filter" => "userPrincipalName in ('user1@domain.com', 'user2@domain.com')",
              "$select" => "id,userPrincipalName"
            }
          }
        end

        it { is_expected.to eq(expected_first_page_results) }
      end
    end

    context "when the first response includes a nextLink" do
      let(:response_body) do
        super().merge("@odata.nextLink" => "https://graph.microsoft.com/continued1")
      end

      let(:all_pages) do
        [].tap do |pages|
          endpoints.send(method_name, *method_args) do |page|
            pages << page
          end
        end
      end

      before do
        page2_response = {
          "@odata.nextLink" => "https://graph.microsoft.com/continued2",
          "value" => [{ "id" => "page2_item" }]
        }
        page3_response = { "value" => [{ "id" => "page3_item" }] }
        WebMock.stub_request(:get, "https://graph.microsoft.com/continued1")
               .and_return(json_response(200, page2_response))
        WebMock.stub_request(:get, "https://graph.microsoft.com/continued2")
               .and_return(json_response(200, page3_response))
      end

      it "calls the block for the results for each page" do
        expect(all_pages).to eq([
                                  expected_first_page_results, [{ "id" => "page2_item" }], [{ "id" => "page3_item" }]
                                ])
      end

      context "when a filter and select are used" do
        let(:method_args) { super() + [filter: { id: "abc" }, select: %w[def ghi]] }
        let(:with_params) { { query: { "$filter" => "id eq 'abc'", "$select" => "def,ghi" } } }

        it "uses the filter and select in the first request" do
          expect(all_pages).to eq([
                                    expected_first_page_results, [{ "id" => "page2_item" }], [{ "id" => "page3_item" }]
                                  ])
        end
      end

      context "when top is used" do
        let(:method_args) { super() + [top: 999] }
        let(:with_params) { { query: { "$top" => 999 } } }

        it "uses the $top parameter in the first request" do
          expect(all_pages).to eq([
                                    expected_first_page_results, [{ "id" => "page2_item" }], [{ "id" => "page3_item" }]
                                  ])
        end
      end
    end
  end

  shared_examples_for "an endpoint that uses up quota" do |read_and_write_points_array|
    it "sends the quota to GraphService::Http#request" do
      expect(endpoints.http).to receive(:request)
        .with(anything, anything, hash_including(quota: read_and_write_points_array))
        .and_call_original
      subject
    end
  end
end
