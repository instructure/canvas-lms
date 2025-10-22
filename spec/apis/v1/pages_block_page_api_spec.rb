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

require_relative "../api_spec_helper"
require_relative "../locked_examples"

describe "Pages API", type: :request do
  include Api::V1::User
  include AvatarHelper

  let(:block_page_data) do
    {
      time: Time.now.to_i,
      version: "1",
      blocks: '{"ROOT":{"type": ...}'
    }
  end

  context "with the block editor" do
    before :once do
      course_with_teacher(active_all: true)
      @course.account.enable_feature!(:block_editor)
      @block_page = @course.wiki_pages.create!(title: "Block editor page", block_editor_attributes: {
                                                 time: Time.now.to_i,
                                                 version: "1",
                                                 blocks: '{"ROOT":{"type": ...}'
                                               })
    end

    describe "index" do
      it("returns the block editor meta-data") do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param)
        expect(json.map { |entry| entry.slice(*%w[url title editor]) }).to eq(
          [{ "url" => @block_page.url, "title" => @block_page.title, "editor" => "block_editor" }]
        )
        expect(json[0].keys).not_to include("body")
        expect(json[0].keys).not_to include("block_editor_attributes")
      end

      it("returns the block editor data when include[]=body is specified") do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param,
                        include: ["body"])
        expect(json[0].keys).to include("body")
        expect(json[0].keys).to include("block_editor_attributes")
        returned_attributes = json[0]["block_editor_attributes"]
        expect(returned_attributes["version"]).to eq(block_page_data[:version])
        expect(returned_attributes["blocks"]).to eq(block_page_data[:blocks])
        returned_body = json[0]["body"]
        expect(returned_body).to include("<iframe class='block_editor_view' src='/block_editors/#{returned_attributes["id"]}' />")
      end
    end

    describe "show" do
      it "retrieves block editor page content and attributes" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@block_page.url}",
                        controller: "wiki_pages_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        url_or_id: @block_page.url)

        returned_attributes = json["block_editor_attributes"]
        expect(json["body"]).to include("<iframe class='block_editor_view' src='/block_editors/#{returned_attributes["id"]}' />")
        expect(json["editor"]).to eq("block_editor")

        expect(returned_attributes["version"]).to eq(block_page_data[:version])
        expect(returned_attributes["blocks"]).to eq(block_page_data[:blocks])
      end

      it "retrieves rce editor page content and attributes" do
        rce_page = @course.wiki_pages.create!(title: "RCE Page", body: "Body of RCE page")
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{rce_page.url}",
                        controller: "wiki_pages_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        url_or_id: rce_page.url)
        expect(json["body"]).to eq(rce_page.body)
        expect(json["editor"]).to eq("rce")
        expect(json["block_editor_attributes"]).to be_nil
      end
    end

    describe "create" do
      it "creates a new page", priority: "1" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Block Page!", block_editor_attributes: block_page_data } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.title).to eq "New Block Page!"
        expect(page.url).to eq "new-block-page"
        expect(page.body).to be_nil
        expect(page.block_editor["blocks"]).to eq block_page_data[:blocks]
        expect(page.block_editor["editor_version"]).to eq block_page_data[:version]
      end

      it "creates a front page using PUT", priority: "1" do
        front_page_url = "new-block-front-page"
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Block Front Page!", block_editor_attributes: block_page_data } })
        expect(json["url"]).to eq front_page_url
        page = @course.wiki_pages.where(url: front_page_url).first!

        expect(page.is_front_page?).to be_truthy
        expect(page.title).to eq "New Block Front Page!"
        expect(page.body).to be_nil
        expect(page.block_editor["blocks"]).to eq block_page_data[:blocks]
        expect(page.block_editor["editor_version"]).to eq block_page_data[:version]
      end
    end

    describe "update" do
      it "updates a page with block editor data" do
        new_block_data = {
          time: Time.now.to_i,
          version: "1",
          blocks: '{"ROOT":{"a_different_type": ...}'
        }
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@block_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @block_page.url },
                 { wiki_page: { block_editor_attributes: new_block_data } })
        @block_page.reload
        expect(@block_page.block_editor["blocks"]).to eq new_block_data[:blocks]
        expect(@block_page.body).to be_nil
      end
    end

    describe "destroy" do
      it "deletes a page", priority: "1" do
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/pages/#{@block_page.url}",
                 { controller: "wiki_pages_api",
                   action: "destroy",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @block_page.url })
        expect(@block_page.reload).to be_deleted
        expect(@block_page.block_editor).to be_nil
      end
    end
  end
end
