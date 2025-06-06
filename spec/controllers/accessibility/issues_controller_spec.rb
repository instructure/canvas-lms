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
    allow_any_instance_of(described_class).to receive(:require_context).and_return(true)
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:authorized_action).and_return(true)
    allow_any_instance_of(described_class).to receive(:tab_enabled?).with(Course::TAB_ACCESSIBILITY).and_return(true)
    allow_any_instance_of(described_class).to receive(:t).and_return("Accessibility")
    allow_any_instance_of(described_class).to receive(:add_crumb)
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
  end

  describe "PUT #update" do
    it "updates the wiki page body with the fixed content" do
      wiki_page = course.wiki_pages.create!(title: "Test Page", body: "<div>old content</div>")
      context_double = double("Context")
      wiki_pages_double = double("WikiPages")
      allow(context_double).to receive_messages(id: course.id, wiki_pages: wiki_pages_double)
      allow(wiki_pages_double).to receive(:find_by).and_return(wiki_page)
      controller.instance_variable_set(:@context, context_double)

      allow_any_instance_of(Accessibility::Issue::HtmlFixer).to receive(:fix_content).and_return("<div>fixed content</div>")

      put :update,
          params: { course_id: course.id },
          body: {
            rule: "adjacent-links",
            content_type: "Page",
            content_id: wiki_page.id,
            path: "/div",
            value: "new value"
          }.to_json,
          as: :json

      json = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json["success"]).to be(true)
      wiki_page.reload
      expect(wiki_page.body).to eq("<div>fixed content</div>")
    end
  end
end
