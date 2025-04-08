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
#

require_relative "../common"

describe "smart search" do
  include_context "in-process server selenium tests"

  before do
    skip "smart search is not available to test" unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")

    allow(SmartSearch).to receive(:generate_embedding) { |input| input.chars.map(&:ord).fill(0, input.size...1024).slice(0...1024) }
    allow(SmartSearch).to receive(:bedrock_client).and_return(double)
    admin_logged_in
  end

  before :once do
    course_factory
    @course.wiki_pages.create! title: "red pandas", body: "foo " * 400
    @course.assignments.create! name: "horse feathers", description: "..."
    @course.assignments.create! name: "hungry hippos", description: "..."
    @course.discussion_topics.create! title: "!!!", message: "..."
    @course.announcements.create! title: "hear ye", message: "..."
    @course.enable_feature! :smart_search

    Account.default.enable_feature!(:smart_search)
  end

  # Remove this when we sunset the old UI + remove FF
  [:enhanced, :normal].each do |view_type|
    describe "#{view_type}:" do
      before :once do
        if view_type == :enhanced
          Account.default.enable_feature!(:smart_search_enhanced_ui)
        else
          Account.default.disable_feature!(:smart_search_enhanced_ui)
        end
      end

      it "renders smart search page" do
        get "/courses/#{@course.id}/search"

        expect(f("[data-testid='smart-search-heading']")).to be_present
        expect(f("[data-testid='search-input']")).to be_present
      end

      it "renders indexing" do
        # we can't reasonably test result searching without mocking embeddings/waiting for indexing
        # so just check that the indexing progress is there
        get "/courses/#{@course.id}/search"

        expect(f("[data-testid='indexing_progress']")).to be_present
      end
    end
  end
end
