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

# Manually stubbing the actual API request
describe LearnPlatform::Api do
  let(:api) { LearnPlatform::Api.new(@account) }

  before do
    account_model
    default_settings = api.learnplatform.default_settings
    default_settings["base_url"] = "http://www.example.com"
    default_settings["token"] = "ABCDEFG1234567"
    PluginSetting.create!(name: api.learnplatform.id, settings: default_settings)
  end

  it "finds the learnplatform plugin" do
    expect(api.learnplatform).not_to be_nil
    expect(api.learnplatform).to eq Canvas::Plugin.find(:learnplatform)
    expect(api.learnplatform).to be_enabled
    expect(api.learnplatform.settings["base_url"]).not_to be_empty
  end

  describe "#products" do
    let(:response) do
      response = double
      allow(response).to receive(:body).and_return(
        {
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
        }.to_json
      )
      response
    end

    it "gets a list of products" do
      allow(CanvasHttp).to receive(:get).and_return(response)
      apps = api.products["tools"]
      expect(apps).to be_a Array
      expect(apps.size).to eq 2
    end
  end

  describe "#products_by_category" do
    let(:response) do
      response = double
      allow(response).to receive(:body).and_return(
        {
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
      )
      response
    end

    it "gets a list of products by category" do
      allow(CanvasHttp).to receive(:get).and_return(response)
      categories = api.products_by_category["categories"]
      expect(categories).to be_a Array
      expect(categories.size).to eq 1
      expect(categories[0]).to be_a Hash
      expect(categories[0]["tools"].size).to eq 2
    end
  end

  describe "#product" do
    let(:response) do
      response = double
      allow(response).to receive(:body).and_return(
        {
          id: 1,
          name: "First Tool",
        }.to_json
      )
      response
    end

    it "gets a single product" do
      allow(CanvasHttp).to receive(:get).and_return(response)
      product = api.product(1)
      expect(product).to be_a Hash
      expect(product["id"]).to eq 1
      expect(product["name"]).to eq "First Tool"
    end
  end

  describe "#product_filters" do
    let(:response) do
      response = double
      allow(response).to receive(:body).and_return(
        {
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
      )
      response
    end

    it "gets a list of product filters" do
      allow(CanvasHttp).to receive(:get).and_return(response)
      filters = api.product_filters
      expect(filters).to be_a Hash
      expect(filters["companies"]).to be_a Array
      expect(filters["companies"].size).to eq 2
    end
  end
end
