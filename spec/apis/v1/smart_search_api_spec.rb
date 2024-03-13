# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe "Smart Search API", type: :request do
  before do
    skip "not available" unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")
  end

  def stub_smart_search
    allow(SmartSearch).to receive(:api_key).and_return("dummy")
    allow(SmartSearch).to receive(:generate_embedding) { |chunk| chunk[0...3].chars.map(&:ord) }
  end

  before :once do
    course_factory(active_all: true)
    @user = @teacher
    wiki_page_model(title: "foo", body: "...")
    wiki_page_model(title: "bar", body: "...")
    @path = "/api/v1/courses/#{@course.id}/smartsearch"
    @params = { controller: "smart_search", course_id: @course.to_param, action: "search", format: "json" }
  end

  describe "with feature disabled" do
    it "returns unauthorized" do
      api_call(:get, @path, @params, {}, {}, { expected_status: 401 })
    end
  end

  describe "with feature enabled" do
    before :once do
      @course.enable_feature!(:smart_search)
    end

    it "checks permissions on course" do
      user_factory
      api_call(:get, @path, @params, {}, {}, { expected_status: 401 })
    end

    it "returns results in order of relevance" do
      stub_smart_search
      SmartSearch.index_course(@course)
      expect(WikiPageEmbedding.count).to be >= 2

      response = api_call(:get, @path + "?q=foo", @params.merge(q: "foo"))
      results = response["results"].map { |row| [row["title"], row["readable_type"]] }
      expect(results).to eq(
        [["foo", "Page"],
         ["bar", "Page"]]
      )
      expect(response["results"][0]["title"]).to eq "foo"
      expect(response["results"][0]["readable_type"]).to eq "Page"
    end
  end
end
