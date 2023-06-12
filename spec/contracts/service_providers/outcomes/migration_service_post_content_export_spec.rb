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

require_relative "../api_pact_helper"

RSpec.describe "Outcomes Service - POST Content Export", :pact do
  describe "migration service" do
    let(:outcomes_secret) { "secret" }
    let(:outcomes_key) { "consumer key" }
    let(:outcomes_host) { "localhost:1234" }
    let(:export_post_payload) do
      {
        host: outcomes_host.split(":").first,
        consumer_key: outcomes_key,
        scope: "content_migration.export",
        exp: 100.years.from_now.to_i,
        context_type: "course",
        context_id: "100",
        id: "*"
      }
    end
    let(:export_post_token) { JSON::JWT.new(export_post_payload).sign(outcomes_secret, :HS512) }
    let(:export_post_headers) do
      {
        "Host" => outcomes_host,
        "Content-Type" => "application/json",
        "Authorization" => export_post_token.to_s
      }
    end
    let(:export_post_request_body) do
      {
        context_id: "100",
        context_type: "course",
        export_settings: {
          format: "canvas",
          artifacts: [
            {
              external_type: "canvas.page",
              external_id: [
                1,
                2,
                3
              ]
            }
          ]
        }
      }
    end
    let(:expected_export_post_response_body) do
      {
        id: Pact.like(2),
        context_type: "course",
        context_id: Pact.like("100"),
        state: "created",
        export_settings: {
          format: "canvas",
          artifacts: [
            {
              external_type: "canvas.page",
              external_id: Pact.each_like(1)
            }
          ]
        }
      }
    end
    let(:course) { course_factory(active_course: true) }
    let(:opts) { {} }

    before do
      # We need to create a wiki_page because the export won't begin without an existing artifact
      wiki_page_model(course:)
      outcomes.given("a provisioned outcomes service account with existing outcomes and artifacts")
              .upon_receiving("a request to create content exports")
              .with(
                method: :post,
                path: "/api/content_exports",
                headers: export_post_headers,
                body: export_post_request_body
              )
              .will_respond_with(
                status: 201,
                headers: { "Content-Type" => "application/json; charset=utf-8" },
                body: expected_export_post_response_body
              )
    end

    it "exports content" do
      # CanvasHttp performs several validations that don't make sense to stub before making
      #  the actual call to the desired service, so it's easier to just stub the whole method
      http_double = class_double(CanvasHttp).as_stubbed_const
      allow(http_double).to receive(:post).and_return(
        HTTParty.post(
          "http://#{outcomes_host}/api/content_exports",
          headers: export_post_headers,
          body: export_post_request_body.to_json
        )
      )
      expect(OutcomesService::MigrationService.begin_export(course, opts)).to be_truthy
    end
  end
end
