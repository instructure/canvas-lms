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

  let(:url_path_prefix_for_statsd) { URI.parse(url).path.split('/')[2] }

  shared_examples_for 'a graph service endpoint' do |opts={}|
    unless opts[:ignore_404]
      context 'with a 404 status code' do
        let(:response) { json_response(404, error: {message: 'uh-oh!'}) }

        it 'raises an HTTPNotFound error' do
          expect(InstStatsd::Statsd).to receive(:increment).with(
            'microsoft_sync.graph_service.notfound',
            tags: {msft_endpoint: "#{http_method}_#{url_path_prefix_for_statsd}"}
          )
          expect { subject }.to raise_error(
            MicrosoftSync::Errors::HTTPNotFound,
            /Graph service returned 404 for tenant mytenant.*uh-oh!/
          )
        end
      end
    end

    [400, 403, 409].each do |code|
      context "with a #{code} status code" do
        let(:response) { json_response(code, error: {message: 'uh-oh!'}) }

        it 'raises an HTTPInvalidStatus with the code and message' do
          expect(InstStatsd::Statsd).to receive(:increment).with(
            'microsoft_sync.graph_service.error',
            tags: {msft_endpoint: "#{http_method}_#{url_path_prefix_for_statsd}"}
          )
          expect { subject }.to raise_error(
            MicrosoftSync::Errors::HTTPInvalidStatus,
            /Graph service returned #{code} for tenant mytenant.*uh-oh!/
          )
        end
      end
    end

    it 'increments a success statsd metric on success' do
      expect(InstStatsd::Statsd).to receive(:increment).with(
        'microsoft_sync.graph_service.success',
        tags: {msft_endpoint: "#{http_method}_#{url_path_prefix_for_statsd}"}
      )
      subject
    end
  end

  shared_examples_for 'a paginated list endpoint' do
    subject { service.send(method_name, *method_args) }

    let(:http_method) { :get }
    let(:expected_first_page_results) { [{'id' => 'page_item1'}] }
    let(:response_body) { {'value' => expected_first_page_results } }

    it_behaves_like 'a graph service endpoint'

    context 'when no block is given' do
      it 'returns the first page of items' do
        expect(subject).to eq(expected_first_page_results)
      end

      context 'when a filter is used' do
        subject { service.send(method_name, *method_args, filter: {'abc' => "d'ef"}) }

        let(:with_params) { {query: {'$filter' => "abc eq 'd''ef'" }} }

        it { is_expected.to eq(expected_first_page_results) }
      end

      context 'when a filter and select are used' do
        subject do
          service.send(
            method_name, *method_args,
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

        it { is_expected.to eq(expected_first_page_results) }
      end
    end

    context 'when the first response includes a nextLink' do
      let(:response_body) do
        super().merge('@odata.nextLink' => 'https://graph.microsoft.com/continued1')
      end

      let(:all_pages) do
        [].tap do |pages|
          service.send(method_name, *method_args) do |page|
            pages << page
          end
        end
      end

      before do
        page2_response = {
          '@odata.nextLink' => 'https://graph.microsoft.com/continued2',
          'value' => [{'id' => 'page2_item'}]
        }
        page3_response = {'value' => [{'id' => 'page3_item'}]}
        WebMock.stub_request(:get, 'https://graph.microsoft.com/continued1').
          and_return(json_response(200, page2_response))
        WebMock.stub_request(:get, 'https://graph.microsoft.com/continued2').
          and_return(json_response(200, page3_response))
      end

      it 'calls the block for the results for each page' do
        expect(all_pages).to eq([
          expected_first_page_results, [{'id' => 'page2_item'}], [{'id' => 'page3_item'}]
        ])
      end

      context 'when a filter and select are used' do
        let(:method_args) { super() + [filter: {id: 'abc'}, select: %w[def ghi]] }
        let(:with_params) { {query: {'$filter' => "id eq 'abc'", '$select' => 'def,ghi'}} }

        it 'uses the filter and select in the first request' do
          expect(all_pages).to eq([
            expected_first_page_results, [{'id' => 'page2_item'}], [{'id' => 'page3_item'}]
          ])
        end
      end
    end
  end

  describe '#list_education_classes' do
    let(:method_name) { :list_education_classes }
    let(:method_args) { [] }
    let(:url) { 'https://graph.microsoft.com/v1.0/education/classes' }

    it_behaves_like 'a paginated list endpoint'
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

  describe '#add_users_to_group' do
    subject { service.add_users_to_group('msgroupid', members: members, owners: owners) }

    let(:members) { %w[m1 m2] }
    let(:owners) { %w[o1 o2] }

    let(:http_method) { :patch }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/msgroupid' }
    let(:with_params) { {body: req_body} }
    let(:req_body) do
      {
        'members@odata.bind' => %w[
          https://graph.microsoft.com/v1.0/directoryObjects/m1
          https://graph.microsoft.com/v1.0/directoryObjects/m2
        ],
        'owners@odata.bind' => %w[
          https://graph.microsoft.com/v1.0/directoryObjects/o1
          https://graph.microsoft.com/v1.0/directoryObjects/o2
        ]
      }
    end
    let(:response) { {status: 204, body: ''} }

    it { is_expected.to eq(nil) }

    context 'when members is not given' do
      subject { service.add_users_to_group('msgroupid', owners: owners) }

      let(:req_body) { super().slice('owners@odata.bind') }

      it { is_expected.to eq(nil) }
    end

    context 'when owners is not given' do
      subject { service.add_users_to_group('msgroupid', members: members) }

      let(:req_body) { super().slice('members@odata.bind') }

      it { is_expected.to eq(nil) }
    end

    context 'when members and owners are not given' do
      it 'raises an ArgumentError' do
        expect { service.add_users_to_group('msgroupid') }.to \
          raise_error(ArgumentError, 'Missing users to add to group')
      end
    end

    context 'when 20 users are given' do
      subject { service.add_users_to_group('msgroupid', members: (1..20).map(&:to_s)) }

      let(:req_body) do
        {
          'members@odata.bind' =>
            (1..20).map{|i| "https://graph.microsoft.com/v1.0/directoryObjects/#{i}"}
        }
      end

      it { is_expected.to eq(nil) }
    end

    context 'when more than 20 users are given' do
      it 'raises an ArgumentError' do
        expect {
          service.add_users_to_group('msgroupid', members: ['x'] * 10, owners: ['y'] * 11)
        }.to raise_error(
          ArgumentError, "Only 20 users can be added at once. Got 21."
        )
      end
    end

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

  describe '#list_group_members' do
    let(:method_name) { :list_group_members }
    let(:method_args) { ['mygroup'] }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/mygroup/members' }

    it_behaves_like 'a paginated list endpoint'
  end

  describe '#list_group_owners' do
    let(:method_name) { :list_group_owners }
    let(:method_args) { ['mygroup'] }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/mygroup/owners' }

    it_behaves_like 'a paginated list endpoint'
  end

  describe '#remove_group_member' do
    subject { service.remove_group_member('mygroup', 'myuser') }

    let(:http_method) { :delete }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/mygroup/members/myuser/$ref' }
    let(:response) { {status: 204, body: ''} }

    it { is_expected.to eq(nil) }

    it_behaves_like 'a graph service endpoint'
  end

  describe '#remove_group_owner' do
    subject { service.remove_group_owner('mygroup', 'myuser') }

    let(:http_method) { :delete }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/mygroup/owners/myuser/$ref' }
    let(:response) { {status: 204, body: ''} }

    it { is_expected.to eq(nil) }

    it_behaves_like 'a graph service endpoint'
  end

  describe '#get_team' do
    subject { service.get_team('mygroupid') }

    let(:http_method) { :get }
    let(:url) { 'https://graph.microsoft.com/v1.0/teams/mygroupid' }
    let(:response_body) { {'foo' => 'bar'} }

    it { is_expected.to eq('foo' => 'bar') }

    it_behaves_like 'a graph service endpoint'
  end

  describe '#team_exists?' do
    subject { service.team_exists?('mygroupid') }

    let(:http_method) { :get }
    let(:url) { 'https://graph.microsoft.com/v1.0/teams/mygroupid' }
    let(:response_body) { {'foo' => 'bar'} }

    it_behaves_like 'a graph service endpoint', ignore_404: true

    context 'when the team exists' do
      it { is_expected.to eq(true) }
    end

    context "when the team doesn't exist" do
      let(:response) { json_response(404, error: {code: 'NotFound', message: 'Does not exist'}) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#create_education_class_team' do
    subject { service.create_education_class_team("Evan's group id") }

    let(:http_method) { :post }
    let(:url) { 'https://graph.microsoft.com/v1.0/teams' }
    let(:req_body) do
      {
        "template@odata.bind" =>
          "https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')",
        "group@odata.bind" => "https://graph.microsoft.com/v1.0/groups('Evan''s group id')"
      }
    end
    let(:with_params) { {body: req_body} }
    let(:response) { {status: 204, body: ''} }

    it { is_expected.to eq(nil) }

    it_behaves_like 'a graph service endpoint'

    context 'when Microsoft returns a 400 saying "must have one or more owners"' do
      let(:response) do
        {
          status: 400,
          # this is an actual error from them (ids changed)
          body: "{\r\n  \"error\": {\r\n    \"code\": \"BadRequest\",\r\n    \"message\": \"Failed to execute Templates backend request CreateTeamFromGroupWithTemplateRequest. Request Url: https://teams.microsoft.com/fabric/amer/templates/api/groups/abcdef01-1212-1212-1212-121212121212/team, Request Method: PUT, Response Status Code: BadRequest, Response Headers: Strict-Transport-Security: max-age=2592000\\r\\nx-operationid: 23457812489473234789372498732493\\r\\nx-telemetryid: 00-31424324322423432143421433242344-4324324234123412-43\\r\\nX-MSEdge-Ref: Ref A: 34213432213432413243422134344322 Ref B: DM1EDGE1111 Ref C: 2021-04-01T20:11:11Z\\r\\nDate: Thu, 01 Apr 2021 20:11:11 GMT\\r\\n, ErrorMessage : {\\\"errors\\\":[{\\\"message\\\":\\\"Group abcdef01-1212-1212-1212-12121212121 must have one or more owners in order to create a Team.\\\",\\\"errorCode\\\":\\\"Unknown\\\"}],\\\"operationId\\\":\\\"23457812489473234789372498732493\\\"}\",\r\n    \"innerError\": {\r\n      \"date\": \"2021-04-01T20:11:11\",\r\n      \"request-id\": \"11111111-1111-1111-1111-111111111111\",\r\n      \"client-request-id\": \"11111111-1111-1111-1111-111111111111\"\r\n    }\r\n  }\r\n}"
        }
      end

      it 'raises a GroupHasNoOwners error' do
        expect { subject }.to raise_error(MicrosoftSync::Errors::GroupHasNoOwners)
      end
    end

    context 'when Microsoft returns a 409 saying "group is already provisioned"' do
      let(:response) do
        {
          status: 409,
          body: "{\r\n  \"error\": {\r\n    \"code\": \"Conflict\",\r\n    \"message\": \"Failed to execute Templates backend request CreateTeamFromGroupWithTemplateRequest. Request Url: https://teams.microsoft.com/fabric/amer/templates/api/groups/16786176-b111-1111-1111-111111111110/team, Request Method: PUT, Response Status Code: Conflict, Response Headers: Strict-Transport-Security: max-age=2592000\\r\\nx-operationid: 11111111111111111111111111111111\\r\\nx-telemetryid: 00-11111111111111111111111111111111-111111111111111b-00\\r\\nX-MSEdge-Ref: Ref A: 11111111111111111111111111111111 Ref B: BLUEDGE1111 Ref C: 2021-04-15T23:08:28Z\\r\\nDate: Thu, 15 Apr 2021 23:08:28 GMT\\r\\n, ErrorMessage : {\\\"errors\\\":[{\\\"message\\\":\\\"The group is already provisioned\\\",\\\"errorCode\\\":\\\"Unknown\\\"}],\\\"operationId\\\":\\\"11111111111111111111111111111111\\\"}\",\r\n    \"innerError\": {\r\n      \"date\": \"2021-04-15T23:08:28\",\r\n      \"request-id\": \"11111111-1111-1111-1111-111111111111\",\r\n      \"client-request-id\": \"11111111-1111-1111-1111-111111111111\"\r\n    }\r\n  }\r\n}"
        }
      end

      it 'raises a TeamAlreadyExists error' do
        expect { subject }.to raise_error(MicrosoftSync::Errors::TeamAlreadyExists)
      end
    end
  end

  describe '#list_users' do
    let(:http_method) { :get }
    let(:url) { 'https://graph.microsoft.com/v1.0/users' }
    let(:method_name) { :list_users }
    let(:method_args) { [] }

    it_behaves_like 'a paginated list endpoint'
  end
end
