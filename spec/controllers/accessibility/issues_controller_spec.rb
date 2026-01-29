# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe Accessibility::IssuesController do
  let(:course) { Course.create!(name: "Test Course", id: 42) }

  before do
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:check_authorized_action).and_return(true)
  end

  describe "POST #create" do
    it "returns issues for pages" do
      allow_any_instance_of(Accessibility::Issue).to receive(:generate).and_return({
                                                                                     pages: { 1 => { title: "Page 1", published: true } },
                                                                                     assignments: {},
                                                                                     last_checked: "Apr 22, 2025"
                                                                                   })

      post :create, params: { course_id: course.id }, format: :json
      json = response.parsed_body

      expect(json["pages"]["1"]["title"]).to eq("Page 1")
      expect(json["pages"]["1"]["published"]).to be true
      expect(json["assignments"]).to eq({})
      expect(json["last_checked"]).to be_a(String)
    end

    it "returns issues for assignments" do
      allow_any_instance_of(Accessibility::Issue).to receive(:generate).and_return({
                                                                                     pages: {},
                                                                                     assignments: { 2 => { title: "Assignment 1", published: false } },
                                                                                     last_checked: "Apr 22, 2025"
                                                                                   })

      post :create, params: { course_id: course.id }, format: :json
      json = response.parsed_body

      expect(json["assignments"]["2"]["title"]).to eq("Assignment 1")
      expect(json["assignments"]["2"]["published"]).to be false
      expect(json["pages"]).to eq({})
      expect(json["last_checked"]).to be_a(String)
    end

    it "searches issues based on the search query" do
      search_query = "test"
      mock_result = { results: [{ id: 1, title: "Test Issue" }] }

      allow_any_instance_of(Accessibility::Issue).to receive(:search).with(search_query).and_return(mock_result)

      post :create, params: { course_id: course.id }, body: { search: search_query }.to_json, as: :json
      json = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json["results"].first["title"]).to eq("Test Issue")
    end
  end

  describe "PUT #update" do
    let(:course) { course_model }
    let(:resource) { wiki_page_model(course:, title: "Test Page", body: "<div><h1>Page Title</h1></div>") }

    it "updates the wiki page body with the fixed content" do
      put :update,
          params: { course_id: course.id },
          body: {
            rule: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            content_type: "Page",
            content_id: resource.id,
            path: ".//h1",
            value: "Change heading level to Heading 2"
          }.to_json,
          as: :json

      json = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json["success"]).to be(true)
      expect(resource.reload.body).to eq("<div><h2>Page Title</h2></div>")
    end
  end
end
