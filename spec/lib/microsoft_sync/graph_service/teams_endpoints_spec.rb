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

describe MicrosoftSync::GraphService::TeamsEndpoints do
  include_context "microsoft_sync_graph_service_endpoints"

  describe "#team_exists?" do
    subject { endpoints.team_exists?("mygroupid") }

    let(:http_method) { :get }
    let(:url) { "https://graph.microsoft.com/v1.0/teams/mygroupid" }
    let(:url_variables) { ["mygroupid"] }
    let(:response_body) { { "foo" => "bar" } }

    it_behaves_like "a graph service endpoint", ignore_404: true

    context "when the team exists" do
      it { is_expected.to be(true) }
    end

    context "when the team doesn't exist" do
      let(:response) { json_response(404, error: { code: "NotFound", message: "Does not exist" }) }

      it { is_expected.to be(false) }

      it 'increments an "expected" statsd counter instead of an "notfound" one' do
        subject
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.expected",
                tags: hash_including(msft_endpoint: "get_teams"))
        expect(InstStatsd::Statsd).to_not have_received(:increment)
          .with("microsoft_sync.graph_service.notfound", anything)
      end
    end
  end

  describe "#create_for_education_class" do
    subject { endpoints.create_for_education_class("Evan's group id") }

    let(:http_method) { :post }
    let(:url) { "https://graph.microsoft.com/v1.0/teams" }
    let(:req_body) do
      {
        "template@odata.bind" =>
          "https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')",
        "group@odata.bind" => "https://graph.microsoft.com/v1.0/groups('Evan''s group id')"
      }
    end
    let(:with_params) { { body: req_body } }
    let(:response) { { status: 204, body: "" } }

    it { is_expected.to be_nil }

    it_behaves_like "a graph service endpoint"

    context 'when Microsoft returns a 400 saying "must have one or more owners"' do
      let(:response) do
        {
          status: 400,
          # this is an actual error from them (ids changed)
          body: "{\r\n  \"error\": {\r\n    \"code\": \"BadRequest\",\r\n    \"message\": \"Failed to execute Templates backend request CreateTeamFromGroupWithTemplateRequest. Request Url: https://teams.microsoft.com/fabric/amer/templates/api/groups/abcdef01-1212-1212-1212-121212121212/team, Request Method: PUT, Response Status Code: BadRequest, Response Headers: Strict-Transport-Security: max-age=2592000\\r\\nx-operationid: 23457812489473234789372498732493\\r\\nx-telemetryid: 00-31424324322423432143421433242344-4324324234123412-43\\r\\nX-MSEdge-Ref: Ref A: 34213432213432413243422134344322 Ref B: DM1EDGE1111 Ref C: 2021-04-01T20:11:11Z\\r\\nDate: Thu, 01 Apr 2021 20:11:11 GMT\\r\\n, ErrorMessage : {\\\"errors\\\":[{\\\"message\\\":\\\"Group abcdef01-1212-1212-1212-12121212121 must have one or more owners in order to create a Team.\\\",\\\"errorCode\\\":\\\"Unknown\\\"}],\\\"operationId\\\":\\\"23457812489473234789372498732493\\\"}\",\r\n    \"innerError\": {\r\n      \"date\": \"2021-04-01T20:11:11\",\r\n      \"request-id\": \"11111111-1111-1111-1111-111111111111\",\r\n      \"client-request-id\": \"11111111-1111-1111-1111-111111111111\"\r\n    }\r\n  }\r\n}"
        }
      end

      it 'raises a GroupHasNoOwners error and increments an "expected" counter' do
        expect { subject }.to raise_error(MicrosoftSync::Errors::GroupHasNoOwners)

        expect(InstStatsd::Statsd).to_not have_received(:increment)
          .with("microsoft_sync.graph_service.error", anything)
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.expected",
                tags: hash_including(msft_endpoint: "post_teams"))
      end
    end

    context 'when Microsoft returns a 409 saying "group is already provisioned"' do
      let(:response) do
        {
          status: 409,
          body: "{\r\n  \"error\": {\r\n    \"code\": \"Conflict\",\r\n    \"message\": \"Failed to execute Templates backend request CreateTeamFromGroupWithTemplateRequest. Request Url: https://teams.microsoft.com/fabric/amer/templates/api/groups/16786176-b111-1111-1111-111111111110/team, Request Method: PUT, Response Status Code: Conflict, Response Headers: Strict-Transport-Security: max-age=2592000\\r\\nx-operationid: 11111111111111111111111111111111\\r\\nx-telemetryid: 00-11111111111111111111111111111111-111111111111111b-00\\r\\nX-MSEdge-Ref: Ref A: 11111111111111111111111111111111 Ref B: BLUEDGE1111 Ref C: 2021-04-15T23:08:28Z\\r\\nDate: Thu, 15 Apr 2021 23:08:28 GMT\\r\\n, ErrorMessage : {\\\"errors\\\":[{\\\"message\\\":\\\"The group is already provisioned\\\",\\\"errorCode\\\":\\\"Unknown\\\"}],\\\"operationId\\\":\\\"11111111111111111111111111111111\\\"}\",\r\n    \"innerError\": {\r\n      \"date\": \"2021-04-15T23:08:28\",\r\n      \"request-id\": \"11111111-1111-1111-1111-111111111111\",\r\n      \"client-request-id\": \"11111111-1111-1111-1111-111111111111\"\r\n    }\r\n  }\r\n}"
        }
      end

      it 'raises a TeamAlreadyExists error and increments an "expected" counter' do
        expect { subject }.to raise_error(MicrosoftSync::Errors::TeamAlreadyExists)

        expect(InstStatsd::Statsd).to_not have_received(:increment)
          .with("microsoft_sync.graph_service.error", anything)
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.expected",
                tags: hash_including(msft_endpoint: "post_teams"))
      end
    end
  end
end
