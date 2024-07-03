# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe LearnPlatformController do
  let(:api) { LearnPlatform::Api.new(@account) }

  before do
    account_model
    default_settings = api.learnplatform.default_settings
    default_settings["base_url"] = "http://www.example.com"
    default_settings["token"] = "ABCDEFG1234567"
    PluginSetting.create!(name: api.learnplatform.id, settings: default_settings)
  end

  include WebMock::API

  let(:account) { Account.create! }

  describe "index" do
    it "gets index with LearnPlatform as a source" do
      response_fixture = {
        tools:
          [
            {
              id: 1,
              name: "First Tool"
            }
          ],
        meta:
          {
            page: 1,
            per_page: 10,
            total_count: 1
          }
      }.to_json
      stub_request(:get, %r{api/v2/lti/tools})
        .to_return(body: response_fixture,
                   status: 200,
                   headers: {
                     "Content-Type" => "application/json",
                     "Content-Length" => response_fixture.size
                   })

      get :index, params: { account_id: account.id }
      expect(response).to have_http_status(:success)
      json = json_parse(response.body)
      expect(json["tools"]).to be_present

      tool = json["tools"].first
      expect(tool["name"]).to be_present
    end
  end

  describe "index_by_category" do
    it "gets index by categories with LearnPlatform as a source" do
      response_fixture = {
        categories: [
          {
            tag_group: {
              id: 1,
              name: "Category 1"
            },
            tools: [
              {
                id: 1,
                name: "First Tool",
              },
              {
                id: 2,
                name: "Second Tool",
              }
            ]
          }
        ]
      }.to_json
      stub_request(:get, %r{api/v2/lti/tools_by_display_group})
        .to_return(body: response_fixture,
                   status: 200,
                   headers: {
                     "Content-Type" => "application/json",
                     "Content-Length" => response_fixture.size
                   })

      get :index_by_category, params: { account_id: account.id }
      expect(response).to have_http_status(:success)

      json = json_parse(response.body)
      expect(json["categories"]).to be_present

      category = json["categories"].first
      expect(category["tag_group"]).to be_present
      expect(category["tools"]).to be_present
      expect(category["tools"].length).to eq(2)
    end
  end

  describe "show" do
    it "gets show with LearnPlatform as a source" do
      response_fixture = { id: 1, name: "First Tool" }.to_json
      stub_request(:get, %r{api/v2/lti/tools/1})
        .to_return(body: response_fixture,
                   status: 200,
                   headers: {
                     "Content-Type" => "application/json",
                     "Content-Length" => response_fixture.size
                   })

      get :show, params: { account_id: account.id, id: 1 }
      expect(response).to have_http_status(:success)

      json = json_parse(response.body)
      expect(json["id"]).to be_present
      expect(json["name"]).to be_present
    end
  end

  describe "filters" do
    it "gets filters with LearnPlatform as a source" do
      response_fixture = {
        companies: [
          {
            id: 100,
            name: "Praxis",
          },
          {
            id: 200,
            name: "Khan Academy"
          }
        ],
        versions: [
          {
            id: 9465,
            name: "LTI v1.1"
          },
          {
            id: 9494,
            name: "LTI v1.3"
          },
        ],
      }.to_json
      stub_request(:get, %r{api/v2/lti/filters})
        .to_return(body: response_fixture,
                   status: 200,
                   headers: {
                     "Content-Type" => "application/json",
                     "Content-Length" => response_fixture.size
                   })

      get :filters, params: { account_id: account.id }
      expect(response).to have_http_status(:success)

      json = json_parse(response.body)
      expect(json["companies"]).to be_present
      expect(json["versions"]).to be_present
    end
  end
end
