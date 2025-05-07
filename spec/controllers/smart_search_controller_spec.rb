# frozen_string_literal: true

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

describe SmartSearchController do
  before do
    allow(SmartSearch).to receive(:bedrock_client).and_return(double)
    course_with_student_logged_in
  end

  describe "show" do
    context "when feature is disabled" do
      it "returns unauthorized" do
        get "show", params: { course_id: @course.id }
        expect(response).to be_unauthorized
      end
    end

    context "when feature is enabled" do
      before do
        @course.enable_feature!(:smart_search)
      end

      context "when tab is enabled" do
        it "renders smart search page" do
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("smart_search/show")
        end
      end

      context "when tab is disabled" do
        before do
          @course.update!(tab_configuration: [{ id: Course::TAB_SEARCH, hidden: true }])
        end

        it "redirects to course page" do
          get "show", params: { course_id: @course.id }
          expect(response).to redirect_to(@course)
        end
      end
    end
  end

  describe "search" do
    before :once do
      @user = user_factory
      @course = course_factory
      @course.enable_feature!(:smart_search)

      @page = @course.wiki_pages.create! title: "panda pages", body: "foo " * 400

      @module = @course.context_modules.create!(name: "module1")
      @assignment = @course.assignments.create! name: "panda assignment", description: "...", due_at: 1.day.from_now
      @module.add_item(id: @assignment.id, type: "assignment")

      @topic = @course.discussion_topics.create! title: "panda topic", message: "...", assignment: @assignment, workflow_state: "unpublished"
    end

    before do
      skip "not available" unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")

      allow(SmartSearch).to receive(:bedrock_client).and_return(double)
      allow(SmartSearch).to receive(:generate_embedding) { |input| input.chars.map(&:ord).fill(0, input.size...1024).slice(0...1024) }
    end

    # mock the distance method + perform_search
    # both require embeddings to be generated, but we want to test include params
    it "returns search results" do
      allow(@page).to receive(:distance).and_return(0.123)
      allow(SmartSearch).to receive(:perform_search)
        .with(@course, @user, "panda", [])
        .and_return([@page])
      course_with_teacher_logged_in(course: @course, user: @user, active_all: true)

      get "search", params: { course_id: @course.id, q: "panda" }
      expect(response).to be_successful
      json = response.parsed_body
      result = json["results"][0]
      expect(result["modules"]).to be_nil
      expect(result["published"]).to be_nil
      expect(result["due_date"]).to be_nil
    end

    it "returns search result with modules" do
      allow(@assignment).to receive(:distance).and_return(0.123)
      allow(SmartSearch).to receive(:perform_search)
        .with(@course, @user, "panda", [])
        .and_return([@assignment])
      course_with_teacher_logged_in(course: @course, user: @user, active_all: true)

      get "search", params: { course_id: @course.id, q: "panda", include: ["modules"] }
      expect(response).to be_successful
      json = response.parsed_body
      result = json["results"][0]
      expect(result["modules"].first["id"]).to eq(@module.id)
      expect(result["published"]).to be_nil
      expect(result["due_date"]).to be_nil
    end

    it "returns search results with status" do
      allow(@topic).to receive(:distance).and_return(0.123)
      allow(SmartSearch).to receive(:perform_search)
        .with(@course, @user, "panda", [])
        .and_return([@topic])
      course_with_teacher_logged_in(course: @course, user: @user, active_all: true)

      get "search", params: { course_id: @course.id, q: "panda", include: ["status"] }
      expect(response).to be_successful
      json = response.parsed_body
      result = json["results"][0]
      expect(result["modules"]).to be_nil
      expect(result["published"]).to be false
      expect(result["due_date"]).to eq(@assignment.due_at.iso8601)
    end
  end
end
