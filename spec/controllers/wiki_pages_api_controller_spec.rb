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

require_relative "../apis/api_spec_helper"

describe WikiPagesApiController, type: :request do
  include Api

  before :once do
    course_with_teacher(active_all: true)
  end

  def update_wiki_page(user, page, wiki_params = {}, expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages/#{page.url}"
    path = {
      controller: "wiki_pages_api",
      action: "update",
      format: "json",
      course_id: @course.id.to_s,
      url_or_id: page.url
    }
    params = { wiki_page: wiki_params }
    api_call_as_user(user, :put, url, path, params, {}, { expected_status: })
  end

  def revert_wiki_page(user, page, revision_id, expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions/#{revision_id}"
    path = {
      controller: "wiki_pages_api",
      action: "revert",
      format: "json",
      course_id: @course.id.to_s,
      url_or_id: page.url,
      revision_id:
    }
    api_call_as_user(user, :post, url, path, {}, {}, { expected_status: })
  end

  def revisions_of_wiki_page(user, page)
    url = "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions"
    path = {
      controller: "wiki_pages_api",
      action: "revisions",
      format: "json",
      course_id: @course.id.to_s,
      url_or_id: page.url
    }
    api_call_as_user(user, :get, url, path, {}, {}, { expected_status: 200 })
  end

  def create_wiki_page(user, wiki_params = {}, expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages"
    path = {
      controller: "wiki_pages_api",
      action: "create",
      format: "json",
      course_id: @course.id.to_s
    }
    params = { wiki_page: wiki_params }
    api_call_as_user(user, :post, url, path, params, {}, { expected_status: })
  end

  def get_wiki_pages(user, include_params = [], expected_status: 200)
    url = "/api/v1/courses/#{@course.id}/pages"
    path = {
      controller: "wiki_pages_api",
      action: "index",
      format: "json",
      course_id: @course.id.to_s
    }
    params = { include: include_params }
    api_call_as_user(user, :get, url, path, params, {}, { expected_status: })
  end

  describe "index" do
    before do
      @wiki_page = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: "Test" }, expected_status: 200)
    end

    context "block_content_editor feature is disabled" do
      before do
        @course.account.disable_feature!(:block_content_editor)
      end

      it "returns a list of wiki pages" do
        response = get_wiki_pages(@teacher, ["body"])
        expect(response).to be_an(Array)
        expect(response.pluck("id")).to include(@wiki_page["id"])
      end
    end

    context "block_content_editor feature is enabled" do
      before do
        @course.account.enable_feature!(:block_content_editor)
      end

      it "returns a list of wiki pages" do
        response = get_wiki_pages(@teacher, ["body"])
        expect(response).to be_an(Array)
        expect(response.pluck("id")).to include(@wiki_page["id"])
      end
    end
  end

  describe "attachment associations" do
    before do
      @aa_test_data = AttachmentAssociationsSpecHelper.new(@course.account, @course)
    end

    it "POST #create creates AAs" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      id_occurences, att_occurences = @aa_test_data.count_aa_records("WikiPage", wiki_response["page_id"])

      expect(id_occurences.keys).to match_array [wiki_response["page_id"]]
      expect(id_occurences.values).to all eq 1
      expect(att_occurences.keys).to match_array [@aa_test_data.attachment1.id]
      expect(att_occurences.values).to all eq 1
    end

    it "updates with new attachments" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      update_wiki_page(@teacher, @wiki_page, { body: @aa_test_data.added_html })

      id_occurences, att_occurences = @aa_test_data.count_aa_records("WikiPage", wiki_response["page_id"])

      expect(id_occurences.keys).to match_array [wiki_response["page_id"]]
      expect(id_occurences.values).to all eq 2
      expect(att_occurences.keys).to match_array [@aa_test_data.attachment1.id, @aa_test_data.attachment2.id]
      expect(att_occurences.values).to all eq 1
    end

    it "updates with removed attachments should keep the associations" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      update_wiki_page(@teacher, @wiki_page, { body: @aa_test_data.removed_html })
      id_occurences, att_occurences = @aa_test_data.count_aa_records("WikiPage", wiki_response["page_id"])

      expect(id_occurences.keys).to match_array [wiki_response["page_id"]]
      expect(id_occurences.values).to all eq 1
      expect(att_occurences.keys).to match_array [@aa_test_data.attachment1.id]
      expect(att_occurences.values).to all eq 1
    end

    it "reverts as expected" do
      wiki_response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: @aa_test_data.base_html }, expected_status: 200)
      @wiki_page = WikiPage.find(wiki_response["page_id"])
      update_wiki_page(@teacher, @wiki_page, { body: @aa_test_data.added_html })
      revisions = revisions_of_wiki_page(@teacher, @wiki_page)
      expect do
        revert_wiki_page(@teacher, @wiki_page, revisions.last["revision_id"])
      end.not_to raise_error
    end
  end

  describe "PUT #update with context_module touching" do
    before :once do
      wiki_page_model(title: "WikiPage Title")
      @wiki_page = @page

      @context_module = ContextModule.create!(
        context: @course,
        name: "Sample Module"
      )

      @context_module.add_item(
        id: @wiki_page.id,
        type: "wiki_page"
      )
    end

    context "when the wiki page is part of a context module" do
      before do
        @wiki_page.reload
        @context_module.reload
      end

      it "has exactly one ContentTag referencing the context module" do
        expect(@wiki_page.context_module_tags.size).to eq 1
        expect(@wiki_page.context_module_tags.first.context_module).to eq @context_module
      end

      it "touches each associated context_module on successful update" do
        original_updated_at = @context_module.updated_at

        update_wiki_page(@teacher, @wiki_page, { title: "Updated Wiki Title" })

        expect(@context_module.reload.updated_at).to be > original_updated_at
      end
    end

    context "when the wiki page has no context modules" do
      before do
        @wiki_page.reload
        @context_module.destroy!
      end

      it "does not raise an error" do
        expect do
          update_wiki_page(@teacher, @wiki_page, { title: "Another Title" })
        end.not_to raise_error
      end
    end
  end
end
