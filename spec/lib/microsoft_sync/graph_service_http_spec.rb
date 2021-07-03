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
      WebMock.disable_net_connect!
      WebMock.stub_request(:get, url)
      allow(InstStatsd::Statsd).to receive(:count).and_call_original
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
    end

    let(:url) { 'https://graph.microsoft.com/v1.0/foo/bar' }

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
              tags: {msft_endpoint: 'get_foo', extra_tag: 'abc'})
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
      http.get_paginated_list('some/list', quota: [2, 3]) { |result| results << result }
      results
    end

    let(:http) { described_class.new('mytenant', extra_tag: 'foo') }
    let(:initial_url) { 'https://graph.microsoft.com/v1.0/some/list' }
    let(:continue_url) { initial_url + '?cont=123' }
    let(:continue_response) { json_200_response(value: {a: 1}, '@odata.nextLink' => continue_url) }
    let(:finished_response) { json_200_response(value: {b: 2}) }

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

      it 'counts a statsd metric with error status=unknown' do
        expect { run_batch }.to raise_error(MicrosoftSync::Errors::HTTPInternalServerError)
        expect(InstStatsd::Statsd).to have_received(:count)
          .with("microsoft_sync.graph_service.batch.error", 2,
                tags: {msft_endpoint: 'wombat', extra_tag: 'abc', status: 'unknown'})
      end
    end
  end
end
