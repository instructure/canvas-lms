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
#

require 'spec_helper'

# GraphServiceHttp is meant to be used only through GraphService. Some things
# are tested here but more are tested in the spec for GraphService (partially
# for historical reasons since GraphServiceHttp was once part of GraphService).
describe MicrosoftSync::GraphServiceHttp do
  include WebMock::API

  subject { described_class.new('mytenant', extra_tag: 'abc') }

  before do
    allow(MicrosoftSync::LoginService).to receive(:token).with('mytenant').and_return('mytoken')
  end

  describe '#request' do
    before do
      responses = statuses.map do |stat|
        {
          status: stat,
          body: {foo: 'bar'}.to_json,
          headers: {'Content-type' => 'application/json'},
        }
      end
      WebMock.disable_net_connect!
      WebMock.stub_request(:get, url).and_return(responses)

      allow(InstStatsd::Statsd).to receive(:count).and_call_original
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
    end

    let(:url) { 'https://graph.microsoft.com/v1.0/foo/bar' }
    let(:statuses) { [status] }
    let(:status) { 200 }

    after { WebMock.enable_net_connect! }

    describe 'quota option' do
      def expect_quota_counted(read_or_write, num)
        expect(InstStatsd::Statsd).to have_received(:count)
          .with("microsoft_sync.graph_service.quota_#{read_or_write}", num,
                tags: {msft_endpoint: 'get_foo', extra_tag: 'abc'})
      end

      def expect_quota_not_counted(read_or_write)
        expect(InstStatsd::Statsd).to_not have_received(:count)
          .with("microsoft_sync.graph_service.quota_#{read_or_write}", anything, anything)
      end

      def expect_quotas_counted(read, write)
        read ? expect_quota_counted(:read, read) : expect_quota_not_counted(:read)
        write ? expect_quota_counted(:write, write) : expect_quota_not_counted(:write)
      end

      it 'counts statsd metric for read and write quotas' do
        subject.request(:get, 'foo/bar', quota: [3, 2])
        expect_quotas_counted(3, 2)
      end

      it "doesn't count quotas if nil quota is passed in" do
        subject.request(:get, 'foo/bar', quota: nil)
        expect_quotas_counted(nil, nil)
      end

      it "doesn't count quotas if no quota is passed in" do
        subject.request(:get, 'foo/bar')
        expect_quotas_counted(nil, nil)
      end

      [0, nil].each do |read_quota|
        it "doesn't count read quota when it is #{read_quota.inspect}" do
          subject.request(:get, 'foo/bar', quota: [read_quota, 2])
          expect_quotas_counted(nil, 2)
        end
      end

      [0, nil].each do |write_quota|
        it "doesn't count write quota when it is #{write_quota.inspect}" do
          subject.request(:get, 'foo/bar', quota: [3, write_quota])
          expect_quotas_counted(3, nil)
        end
      end

      context 'when the select option is used' do
        let(:url) { 'https://graph.microsoft.com/v1.0/foo/bar?$select=foo' }

        it 'decreases the read quota points by 1' do
          subject.request(:get, 'foo/bar', quota: [2, 3], query: {'$select' => 'foo'})
          expect_quotas_counted(1, 3)
        end

        it "doesn't decrease read quota if it is already 1" do
          subject.request(:get, 'foo/bar', quota: [1, 3], query: {'$select' => 'foo'})
          expect_quotas_counted(1, 3)
        end
      end
    end

    it 'uses the correct msft_endpoint when passed in a url' do
      # pagination "next" links are complete URLs
      subject.request(:get, 'https://graph.microsoft.com/v1.0/foo/bar', quota: [1, 0])
      expect(InstStatsd::Statsd).to have_received(:count)
        .with("microsoft_sync.graph_service.quota_read", 1,
              tags: {msft_endpoint: 'get_foo', extra_tag: 'abc'})
      expect(InstStatsd::Statsd).to have_received(:increment)
        .with("microsoft_sync.graph_service.success",
              tags: {msft_endpoint: 'get_foo', extra_tag: 'abc', status_code: '200'})
    end

    context 'when a block is passed in' do
      let(:status) { 409 }

      context 'when the response is non-200 and the block returns truthy' do
        let(:result) do
          subject.request(:get, url) { |resp| resp.code == 409 && :foo }
        end

        it 'returns the value the block returned' do
          expect(result).to eq(:foo)
        end

        it 'increments an "expected" counter and not an "error" counter' do
          result
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with('microsoft_sync.graph_service.expected',
                  tags: {extra_tag: 'abc', msft_endpoint: 'get_foo', status_code: '409'})
          expect(InstStatsd::Statsd).to_not have_received(:increment)
            .with('microsoft_sync.graph_service.error', anything)
        end
      end

      context 'when the block returns a StandardError' do
        let(:err) { StandardError.new('hello') }
        let(:result) { subject.request(:get, url) { err } }

        it 'raises that exception and increments an "expected" counter, not an "error" counter' do
          expect { result }.to raise_error(err)
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with('microsoft_sync.graph_service.expected',
                  tags: {extra_tag: 'abc', msft_endpoint: 'get_foo', status_code: '409'})
          expect(InstStatsd::Statsd).to_not have_received(:increment)
            .with('microsoft_sync.graph_service.error', anything)
        end
      end

      context 'when the response is non-200 and the block returns falsey' do
        let(:result) do
          subject.request(:get, 'https://graph.microsoft.com/v1.0/foo/bar') do |resp|
            resp.code == 408 && :foo
          end
        end

        it 'raises an error and increments an "error" counter' do
          expect { result }.to raise_error(MicrosoftSync::Errors::HTTPConflict)
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with('microsoft_sync.graph_service.error',
                  tags: {extra_tag: 'abc', msft_endpoint: 'get_foo', status_code: '409'})
          expect(InstStatsd::Statsd).to_not have_received(:increment)
            .with('microsoft_sync.graph_service.expected', anything)
        end
      end
    end

    shared_examples_for 'retrying an intermittent error' do
      let(:requests) { [:bad] }

      context 'if the first response is an intermittent error' do
        before do
          allow(subject).to receive(:request_without_metrics).and_call_original
        end

        let(:requests) { [:bad, :good] }

        it 'tries again immediately' do
          expect(subject.request(:get, 'foo/bar')).to eq('foo' => 'bar')
          expect(subject).to have_received(:request_without_metrics).exactly(2).times
            .with(:get, 'foo/bar', anything)
        end

        it 'increments a "retried" statsd counter' do
          subject.request(:get, 'foo/bar')
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with("microsoft_sync.graph_service.retried",
                  tags: {msft_endpoint: 'get_foo', extra_tag: 'abc',
                         status_code: status_code_statsd_tag})
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with("microsoft_sync.graph_service.success",
                  tags: {msft_endpoint: 'get_foo', extra_tag: 'abc', status_code: '200'})
        end

        it 'logs the outcome of each request' do
          allow(Rails.logger).to receive(:info).and_call_original
          subject.request(:get, 'foo/bar')
          expect(Rails.logger).to have_received(:info).with(
            "MicrosoftSync::GraphServiceHttp: get foo/bar -- #{status_code_statsd_tag}, retried"
          )
          expect(Rails.logger).to have_received(:info).with(
            'MicrosoftSync::GraphServiceHttp: get foo/bar -- 200, success'
          )
        end
      end

      context 'if two intermittent errors are encountered' do
        let(:requests) { [:bad, :bad] }

        it 'fails and increments "retried" and "error" statsd counters' do
          expect { subject.request(:get, 'foo/bar') }.to raise_error(error_class)
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with("microsoft_sync.graph_service.retried",
                  tags: {msft_endpoint: 'get_foo', extra_tag: 'abc',
                         status_code: status_code_statsd_tag})
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with("microsoft_sync.graph_service.intermittent",
                  tags: {msft_endpoint: 'get_foo', extra_tag: 'abc',
                         status_code: status_code_statsd_tag})
        end

        it 'logs the outcome of each request' do
          allow(Rails.logger).to receive(:info).and_call_original
          expect { subject.request(:get, 'foo/bar') }.to raise_error(error_class)
          expect(Rails.logger).to have_received(:info).with(
            "MicrosoftSync::GraphServiceHttp: get foo/bar -- #{status_code_statsd_tag}, retried"
          )
          expect(Rails.logger).to have_received(:info).with(
            "MicrosoftSync::GraphServiceHttp: get foo/bar -- #{status_code_statsd_tag}, intermittent"
          )
        end
      end

      it 'fails immediately if DEFAULT_N_INTERMITTENT_RETRIES is 0' do
        stub_const('MicrosoftSync::GraphServiceHttp::DEFAULT_N_INTERMITTENT_RETRIES', 0)
        expect { subject.request(:get, 'foo/bar') }.to raise_error(error_class)
      end

      it 'fails immediately if retries: 0 is passed in' do
        expect { subject.request(:get, 'foo/bar', retries: 0) }.to raise_error(error_class)
      end
    end

    [EOFError, Errno::ECONNRESET, Timeout::Error].each do |klass|
      context "when the error is an #{klass}" do
        before do
          # prepare requests, e.g. if `requests` (in shared examples) if [:bad,
          # :good], raise an error the second time called
          requests.each do |bad_or_good|
            if bad_or_good == :good
              expect(HTTParty).to receive(:get).exactly(:once).and_call_original
            else
              expect(HTTParty).to receive(:get).exactly(:once).and_raise(klass)
            end
          end
        end

        let(:error_class) { klass }
        let(:status_code_statsd_tag) { klass.name.tr(':', '_') }

        it_behaves_like 'retrying an intermittent error'
      end
    end

    context "when the error is 502 Bad Gateway" do
      let(:error_class) { MicrosoftSync::Errors::HTTPBadGateway }
      let(:status_code_statsd_tag) { '502' }
      let(:statuses) { requests.map{|bad_or_good| {bad: 502, good: 200}[bad_or_good] } }

      it_behaves_like 'retrying an intermittent error'
    end

    {
      400 => MicrosoftSync::Errors::HTTPBadRequest,
      429 => MicrosoftSync::Errors::HTTPTooManyRequests,
    }.each do |status_code, error_class|
      context "when the error is a #{status_code}" do
        let(:status) { status_code }

        it 'raises the error immediately and does not retried' do
          expect { subject.request(:get, 'foo/bar') }.to raise_error(error_class)
        end
      end
    end
  end

  describe '#expand_options' do
    it 'expands select into $select' do
      expect(subject.expand_options(select: ['a'])).to eq('$select' => 'a')
    end
  end

  describe '#get_paginated_list' do
    subject do
      results = []
      http.get_paginated_list('some/list', quota: [2, 3], **extra_opts) do |result|
        results << result
      end
      results
    end

    let(:http) { described_class.new('mytenant', extra_tag: 'foo') }
    let(:initial_url) { 'https://graph.microsoft.com/v1.0/some/list' }
    let(:continue_url) { initial_url + '?cont=123' }
    let(:continue_response) { json_200_response(value: {a: 1}, '@odata.nextLink' => continue_url) }
    let(:finished_response) { json_200_response(value: {b: 2}) }
    let(:extra_opts) { {} }

    def json_200_response(body)
      {status: 200, body: body.to_json, headers: {'Content-type' => 'application/json'}}
    end

    before do
      WebMock.disable_net_connect!
      WebMock.stub_request(:get, initial_url).and_return(continue_response)
      WebMock.stub_request(:get, continue_url).and_return(finished_response)
      allow(http).to receive(:request).and_call_original
    end

    after { WebMock.enable_net_connect! }

    it 'runs the block with the "value" from each response' do
      expect(subject).to eq([{'a' => 1}, {'b' => 2}])
    end

    it 'passes in path and quota to the first request' do
      subject
      expect(http).to have_received(:request).with(:get, 'some/list', hash_including(quota: [2, 3]))
    end

    it 'passes in a url and quota to subsequent requests' do
      subject
      expect(http).to \
        have_received(:request).with(:get, continue_url, hash_including(quota: [2, 3]))
    end

    context 'when passed an expected_error_block' do
      let(:extra_opts) { {expected_error_block: block} }

      context 'when the block returns false' do
        let(:block) { lambda { |resp| resp.code == 400 } }

        it 'returns results as usual' do
          expect(subject).to eq([{'a' => 1}, {'b' => 2}])
        end
      end

      context 'when the block returns an error' do
        let(:err) { StandardError.new }
        let(:block) { lambda { |resp| resp.code == 200 && err } }

        it 'raises that error' do
          expect { subject }.to raise_error(err)
        end
      end
    end
  end

  describe '#run_batch' do
    before do
      WebMock.disable_net_connect!
      WebMock.stub_request(:post, 'https://graph.microsoft.com/v1.0/$batch')
        .with(body: {requests: requests})
        .and_return(
          status: status_code, body: {responses:[]}.to_json,
          headers: {'Content-type' => 'application/json'}
        )
      allow(InstStatsd::Statsd).to receive(:count).and_call_original
    end

    after { WebMock.enable_net_connect! }

    let(:requests) do
      [
        {id: 'a', method: 'GET', url: '/foo'},
        {id: 'a', method: 'GET', url: '/bar'},
      ]
    end
    let(:status_code) { 200 }
    let(:run_batch) { subject.run_batch('wombat', requests, quota: [3, 4]) }

    it 'counts statsd metrics with the quota' do
      run_batch
      expect(InstStatsd::Statsd).to have_received(:count)
        .with("microsoft_sync.graph_service.quota_read", 3,
              tags: {msft_endpoint: 'batch_wombat', extra_tag: 'abc'})
      expect(InstStatsd::Statsd).to have_received(:count)
        .with("microsoft_sync.graph_service.quota_write", 4,
              tags: {msft_endpoint: 'batch_wombat', extra_tag: 'abc'})
    end

    context 'when the batch request itself fails' do
      let(:status_code) { 500 }

      before { stub_const('MicrosoftSync::GraphServiceHttp::DEFAULT_N_INTERMITTENT_RETRIES', 0) }

      it 'counts a statsd metric with error status=unknown' do
        expect { run_batch }.to raise_error(MicrosoftSync::Errors::HTTPInternalServerError)
        expect(InstStatsd::Statsd).to have_received(:count)
          .with("microsoft_sync.graph_service.batch.error", 2,
                tags: {msft_endpoint: 'wombat', extra_tag: 'abc', status: 'unknown'})
      end
    end
  end
end
