# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../api_pact_helper'

RSpec.describe 'Outcomes Service - GET Content Export', :pact do
  describe 'migration service' do
    let(:outcomes_secret) { 'secret' }
    let(:outcomes_key) { 'consumer key' }
    let(:outcomes_host) { 'localhost:1234' }
    let(:export_get_payload) do
      {
        host: outcomes_host.split(':').first,
        consumer_key: outcomes_key,
        scope: 'content_migration.export',
        exp: 100.years.from_now.to_i,
        context_type: 'course',
        context_id: '100',
        id: '*'
      }
    end
    let(:export_get_token) { JSON::JWT.new(export_get_payload).sign(outcomes_secret, :HS512) }
    let(:export_get_headers) do
      {
        'Host' => outcomes_host,
        'Content-Type' => 'application/json, application/x-www-form-urlencoded',
        'Authorization' => export_get_token.to_s
      }
    end
    let(:expected_export_get_response_body) do
    {
      "id": Pact.like(5),
      "context_type": "course",
      "context_id": Pact.like("100"),
      "state": "completed",
      "export_settings": {
        "format": "canvas",
        "artifacts": [
          {
            "external_id": Pact.each_like(1),
            "external_type": "canvas.page"
          }
        ]
      },
      "data": {
        "format": "canvas",
        "alignments": Pact.each_like({
          "artifact": Pact.like({
            "$canvas_wiki_page_id": "1"
          }),
          "outcomes": Pact.each_like({
            "$canvas_learning_outcome_id": "external-id-1"
          })
        })
      }
    }
    end
    let(:export_data) { { "export_id": "1" } }

    before do
      outcomes.given('artifacts and an export to retrieve').
        upon_receiving('a request to return exported content').
        with(
          method: :get,
          path: '/api/content_exports/1',
          headers: export_get_headers
        ).
        will_respond_with(
          status: 200,
          headers: { 'Content-Type' => 'application/json; charset=utf-8' },
          body: expected_export_get_response_body
        )
    end

    it 'gets exported content' do
      # CanvasHttp performs several validations that don't make sense to stub before making
      #  the actual call to the desired service, so it's easier to just stub the whole method
      http_double = class_double(CanvasHttp).as_stubbed_const
      allow(http_double).to receive(:get).
        and_return(
          HTTParty.get(
            "http://#{outcomes_host}/api/content_exports/1",
            headers: export_get_headers
          )
        )
      service_double = class_double(OutcomesService::Service).as_stubbed_const
      allow(service_double).to receive(:url).and_return(outcomes_host)
      allow(service_double).to receive(:jwt)
      expect(OutcomesService::MigrationService.retrieve_export(export_data)).to be_truthy
    end
  end
end
