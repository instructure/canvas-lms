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

require_relative '../../spec_helper'

describe MicrosoftSync::GraphService do
  include WebMock::API

  def json_response(status, body)
    {status: status, body: body.to_json, headers: {'Content-type' => 'application/json'}}
  end

  before do
    WebMock.disable_net_connect!
    allow(MicrosoftSync::LoginService).to receive(:token).with('mytenant').and_return('mytoken')
    if with_params.empty?
      WebMock.stub_request(http_method, url).and_return(response)
    else
      WebMock.stub_request(http_method, url).with(with_params).and_return(response)
    end
  end

  after { WebMock.enable_net_connect! }

  let(:service) { described_class.new('mytenant') }

  let(:response) { json_response(200, response_body) }
  let(:with_params) { {} }

  # http_method, url, with_params, and reponse_body will be defined with let()s below

  shared_examples_for 'a graph service endpoint' do
    context 'with a non-200 status code' do
      let(:response) { json_response(403, error: {message: 'uh-oh!'}) }

      it 'raises an InvalidStatusCodewith the code and message' do
        expect { subject }.to raise_error(
          MicrosoftSync::Errors::InvalidStatusCode,
          /Graph service returned 403 for tenant mytenant.*uh-oh!/
        )
      end
    end
  end

  describe '#list_education_classes' do
    subject { service.list_education_classes }

    let(:http_method) { :get }
    let(:url) { 'https://graph.microsoft.com/v1.0/education/classes' }
    let(:response_body) { {'value' => [{'id' => 'class1'}] } }

    it { is_expected.to eq(response_body['value']) }

    it_behaves_like 'a graph service endpoint'

    context 'when a filter is used' do
      subject { service.list_education_classes(filter: {'abc' => "d'ef"}) }

      let(:with_params) { {query: {'$filter' => "abc eq 'd''ef'" }} }

      it { is_expected.to eq(response_body['value']) }
    end
  end

  describe '#create_education_class' do
    subject { service.create_education_class(abc: 123) }

    let(:http_method) { :post }
    let(:url) { 'https://graph.microsoft.com/v1.0/education/classes' }
    let(:with_params) { {body: {abc: 123}} }
    let(:response_body) { {'id' => 'newclass', 'val' => 'etc'} }

    it { is_expected.to eq(response_body) }

    it_behaves_like 'a graph service endpoint'
  end

  describe '#update_group' do
    subject { service.update_group('msgroupid', abc: {def: 'ghi'}) }

    let(:http_method) { :patch }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/msgroupid' }
    let(:with_params) { {body: {abc: {def: 'ghi'}}} }
    let(:response) { {status: 204, body: ''} }

    it { is_expected.to eq(nil) }

    it_behaves_like 'a graph service endpoint'
  end

  describe '#get_group' do
    subject { service.get_group('msgroupid') }

    let(:http_method) { :get }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/msgroupid' }
    let(:response_body) { {'abc' => 'def'} }

    it { is_expected.to eq(response_body) }

    it_behaves_like 'a graph service endpoint'

    context 'when certain fields are selected' do
      subject { service.get_group('msgroupid', select: %w[abc d e]) }

      let(:with_params) { {query: {'$select' => 'abc,d,e' }} }

      it { is_expected.to eq(response_body) }
    end
  end

  describe '#list_users' do
    subject { service.list_users }

    let(:http_method) { :get }
    let(:url) { 'https://graph.microsoft.com/v1.0/users' }
    let(:response_body) { {'value' => [{'id' => 'user1'}] } }

    it { is_expected.to eq(response_body['value']) }

    it_behaves_like 'a graph service endpoint'

    context 'when a filter and select are used' do
      subject do
        service.list_users(
          filter: {userPrincipalName: %w[user1@domain.com user2@domain.com]},
          select: %w[id userPrincipalName]
        )
      end

      let(:with_params) do
        {
          query: {
            '$filter' => "userPrincipalName in ('user1@domain.com', 'user2@domain.com')",
            '$select' => 'id,userPrincipalName'
          }
        }
      end

      it { is_expected.to eq(response_body['value']) }
    end
  end
end
