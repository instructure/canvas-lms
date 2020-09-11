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

RSpec.describe 'Outcomes Service - GET Content Import', :pact do
  describe 'migration service' do
    let(:outcomes_secret) { 'secret' }
    let(:outcomes_key) { 'consumer key' }
    let(:outcomes_host) { 'localhost:1234' }

    let(:import_get_payload) do
      {
        host: outcomes_host.split(':').first,
        consumer_key: outcomes_key,
        scope: 'content_migration.import',
        exp: 100.years.from_now.to_i,
        context_type: 'course',
        context_id: '100',
        id: '*'
      }
    end
    let(:import_get_token) { JSON::JWT.new(import_get_payload).sign(outcomes_secret, :HS512) }
    let(:import_get_headers) do
      {
        'Host' => outcomes_host,
        'Content-Type' => 'application/json, application/x-www-form-urlencoded',
        'Authorization' => import_get_token.to_s
      }
    end
    let(:expected_import_get_response_body) do
    {
      "state": "completed"
    }
    end
    let!(:course) { course_factory(active_course: true) }
    let(:import_data) { { course: course, import_id: 1 } }

    before do
      outcomes.given('a provisioned outcomes service account with a completed content import').
        upon_receiving('a request to return imported content').
        with(
          method: :get,
          path: '/api/content_imports/1',
          headers: import_get_headers
        ).
        will_respond_with(
          status: 200,
          headers: { 'Content-Type' => 'application/json; charset=utf-8' },
          body: expected_import_get_response_body
        )
    end

    it 'gets imported content' do
      # CanvasHttp performs several validations that don't make sense to stub before making
      #  the actual call to the desired service, so it's easier to just stub the whole method
      http_double = class_double(CanvasHttp).as_stubbed_const
      allow(http_double).to receive(:get).and_return(
        HTTParty.get(
          "http://#{outcomes_host}/api/content_imports/1",
          headers: import_get_headers
        )
      )
      service_double = class_double(OutcomesService::Service).as_stubbed_const
      allow(service_double).to receive(:url).and_return(outcomes_host)
      allow(service_double).to receive(:jwt)
      expect(OutcomesService::MigrationService).to be_import_completed(import_data)
    end
  end
end
