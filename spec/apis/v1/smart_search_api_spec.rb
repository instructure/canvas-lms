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
    wiki_page_model(title: "foo", body: "...", course: @course)
    wiki_page_model(title: "bar", body: "...", course: @course)
    assignment_model(title: "goo", description: "...", course: @course)
    discussion_topic_model(title: "baz", message: "...", context: @course)
    discussion_topic_model(title: "hoo", message: "...", context: @course)
    announcement_model(title: "boo", message: "...", context: @course)
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
      expect(AssignmentEmbedding.count).to be >= 1
      expect(WikiPageEmbedding.count).to be >= 2
      expect(DiscussionTopicEmbedding.count).to be >= 2

      response = api_call(:get, @path + "?q=foo", @params.merge(q: "foo"))
      results = response["results"].map { |row| [row["title"], row["readable_type"]] }
      expect(results).to eq(
        [["foo", "Page"],
         ["goo", "Assignment"],
         ["hoo", "Discussion Topic"],
         ["boo", "Announcement"],
         ["bar", "Page"],
         ["baz", "Discussion Topic"]]
      )
      distances = response["results"].pluck("distance")
      expect(distances).to eq(distances.sort)
    end

    it "filters by type" do
      stub_smart_search
      SmartSearch.index_course(@course)

      response = api_call(:get, @path + "?q=foo&filter[]=announcements", @params.merge(q: "foo", filter: ["announcements"]))
      expect(response["results"].pluck("content_type")).to match_array %w[Announcement]

      response = api_call(:get, @path + "?q=foo&filter[]=discussion_topics&filter[]=pages", @params.merge(q: "foo", filter: ["discussion_topics", "pages"]))
      expect(response["results"].pluck("content_type")).to match_array %w[DiscussionTopic DiscussionTopic WikiPage WikiPage]

      response = api_call(:get, @path + "?q=foo&filter[]=discussion_topics&filter[]=announcements", @params.merge(q: "foo", filter: ["discussion_topics", "announcements"]))
      expect(response["results"].pluck("content_type")).to match_array %w[DiscussionTopic DiscussionTopic Announcement]

      response = api_call(:get, @path + "?q=foo&filter[]=assignments", @params.merge(q: "foo", filter: ["assignments"]))
      expect(response["results"].pluck("content_type")).to match_array %w[Assignment]
    end
  end
end
