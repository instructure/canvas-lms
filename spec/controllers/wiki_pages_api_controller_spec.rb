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

  describe "POST #create" do
    it "creates a new wiki page with attachments" do
      attachment, html = AttachmentAssociationsSpecHelper.create_attachments_and_html(@course.account, @course)
      response = create_wiki_page(@teacher, { title: "Pläcëhöldër", body: html }, expected_status: 200)
      page = WikiPage.find(response["page_id"])
      expect(AttachmentAssociation.find_by(context: page, attachment_id: attachment.id)).to be_present
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

    context "check creation of AA records for attachments" do
      it "creates the records" do
        attachment, html = AttachmentAssociationsSpecHelper.create_attachments_and_html(@course.account, @course)
        update_wiki_page(@teacher, @wiki_page, { body: html })
        expect(AttachmentAssociation.find_by(context: @wiki_page, attachment_id: attachment.id)).to be_present
      end
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
