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

require_relative "../spec_helper"

describe SmartSearch do
  describe "#index_course" do
    before do
      skip "not available" unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")
      allow(SmartSearch).to receive(:generate_embedding).and_return([1] * 1024)
    end

    before :once do
      course_factory
      @course.wiki_pages.create! title: "red pandas", body: "foo " * 400
      @course.assignments.create! name: "horse feathers", description: "..."
      @course.assignments.create! name: "hungry hippos", description: "..."
      @course.discussion_topics.create! title: "!!!", message: "..."
      @course.enable_feature! :smart_search
    end

    it "indexes a new course" do
      SmartSearch.index_course(@course)
      expect(WikiPageEmbedding.where(wiki_page_id: @course.wiki_pages.select(:id)).count).to eq 2
      expect(AssignmentEmbedding.where(assignment_id: @course.assignments.select(:id)).count).to eq 2
      expect(DiscussionTopicEmbedding.where(discussion_topic_id: @course.discussion_topics.select(:id)).count).to eq 1
    end

    it "indexes only missing items" do
      @course.assignments.first.generate_embeddings(synchronous: true)
      expect_any_instance_of(Assignment).to receive(:generate_embeddings).once.and_call_original
      SmartSearch.index_course(@course)
    end

    it "reindexes items with old embeddings" do
      SmartSearch.index_course(@course)
      @course.assignments.first.embeddings.update_all(version: 0)
      @course.search_embedding_version = 0
      @course.save!
      expect(SmartSearch).to receive(:generate_embedding).once.and_return([2] * 1536)
      SmartSearch.index_course(@course)
      expect(@course.assignments.first.embeddings.first.version).to eq SmartSearch::EMBEDDING_VERSION
    end
  end
end
