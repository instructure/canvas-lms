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

RSpec.describe 'Outcomes Service - POST Content Import', :pact do
  describe 'migration service' do
    let(:outcomes_secret) { 'secret' }
    let(:outcomes_key) { 'consumer key' }
    let(:outcomes_host) { 'localhost:1234' }

    let(:import_post_payload) do
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
    let(:import_post_token) { JSON::JWT.new(import_post_payload).sign(outcomes_secret, :HS512) }
    let(:import_post_headers) do
      {
        'Host' => outcomes_host,
        'Content-Type' => 'application/json, application/x-www-form-urlencoded',
        'Authorization' => import_post_token.to_s
      }
    end
    let(:import_post_request_body) do
    {
      "format": "canvas",
      "alignments": [
        {
          "artifact": {
            "$canvas_wiki_page_id": "100"
          },
          "outcomes": [
            {
              "$canvas_learning_outcome_id": "1"
            },
            {
              "$canvas_learning_outcome_id": "2"
            }
          ]
        }
      ],
      "outcomes": [
        {
          "$canvas_learning_outcome_id": "1000",
          "title": "outcome_title",
          "description": "outcome_description",
          "rubric_criterion": {
            "description": "scoring method description",
            "ratings": [
              {
                "description": "Exceeds Expectations",
                "points": 5
              },
              {
                "description": "Does Not Meet Expectations",
                "points": 0
              }
            ],
            "mastery_points": 1,
            "points_possible": 5
          }
        }
      ],
      "context_type": "course",
      "context_id": 100,
      "groups": [
        {
          "$canvas_learning_outcome_group_id": "1001",
          "title": "outcome_group_title",
          "description": "outcome_group_description"
        }
      ],
      "edges": [
        {
          "$canvas_learning_outcome_link_id": "1002",
          "$canvas_learning_outcome_id": "1000",
          "$canvas_learning_outcome_group_id": "1001"
        }
      ]
    }
    end
    let(:expected_import_post_response_body) do
    {
      "id": Pact.like(1),
      "context_type": "course",
      "context_id": Pact.like("100"),
      "state": "created"
    }
    end
    let!(:course) {course_factory(active_course: true)}
    let(:wiki_page) {wiki_page_model(course: course)}
    let!(:content_migration) { ContentMigration.new }
    let(:imported_content) do
    {
      "format"=>"canvas",
      "alignments"=>[
        {
          "artifact"=>{"$canvas_wiki_page_id"=>3},
          "outcomes"=>[
            {"$canvas_learning_outcome_id"=>40},
            {"$canvas_learning_outcome_id"=>47}
          ]
        }
      ]
    }
    end

    before do
      outcomes.given('a provisioned outcomes service account with existing outcomes').
        upon_receiving('a request to create content imports').
        with(
          method: :post,
          path: "/api/content_imports",
          headers: import_post_headers,
          body: import_post_request_body
        ).
        will_respond_with(
          status: 201,
          headers: { 'Content-Type' => 'application/json; charset=utf-8' },
          body: expected_import_post_response_body
        )
    end

    it 'imports content' do
      # CanvasHttp performs several validations that don't make sense to stub before making
      #  the actual call to the desired service, so it's easier to just stub the whole method
      http_double = class_double(CanvasHttp).as_stubbed_const
      allow(http_double).to receive(:post).and_return(
        HTTParty.post(
          "http://#{outcomes_host}/api/content_imports",
          headers: import_post_headers,
          body: import_post_request_body.to_json
        )
      )
      expect(OutcomesService::MigrationService.send_imported_content(course, content_migration, imported_content)).to be_truthy
    end
  end
end
