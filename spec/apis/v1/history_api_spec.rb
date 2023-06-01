# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe HistoryController, type: :request do
  include Api
  include Api::V1::HistoryEntry

  describe "#index" do
    before :once do
      account_admin_user
      @dates = [1.day.ago.beginning_of_hour, 2.days.ago.beginning_of_hour, 3.days.ago.beginning_of_hour, 4.days.ago.beginning_of_hour]
      course_with_student active_all: true, course_name: "Something 101", user: user_with_pseudonym
      assignment_model title: "Assign 1", context: @course
      group_model context: @course, name: "A Group"
      page_view_for url: "http://example.com/courses/X/assignments/Y",
                    context: @course,
                    created_at: @dates[2],
                    asset_category: "assignments",
                    asset_code: @assignment.asset_string
      page_view_for url: "http://example.com/courses/X/users",
                    created_at: @dates[0],
                    asset_category: "roster",
                    asset_code: "roster:#{@course.asset_string}"
      page_view_for url: "http://example.com/groups/Z/pages",
                    context: @group,
                    created_at: @dates[1],
                    asset_category: "pages",
                    asset_code: "pages:#{@group.asset_string}"
      @user = @student
    end

    context "history information" do
      it "returns information about assets and index pages in descending order by date" do
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")
        expect(json).to eq([{ "asset_code" => "roster:#{@course.asset_string}",
                              "context_id" => @course.id,
                              "context_type" => "Course",
                              "visited_at" => @dates[0].iso8601,
                              "visited_url" => "http://example.com/courses/X/users",
                              "interaction_seconds" => 5.0,
                              "asset_icon" => "icon-user",
                              "asset_readable_category" => "People",
                              "asset_name" => "Course People",
                              "context_name" => "Something 101" },
                            { "asset_code" => "pages:#{@group.asset_string}",
                              "context_id" => @group.id,
                              "context_type" => "Group",
                              "visited_at" => @dates[1].iso8601,
                              "visited_url" => "http://example.com/groups/Z/pages",
                              "interaction_seconds" => 5.0,
                              "asset_icon" => "icon-document",
                              "asset_readable_category" => "Page",
                              "asset_name" => "Group Pages",
                              "context_name" => "A Group" },
                            { "asset_code" => @assignment.asset_string,
                              "context_id" => @course.id,
                              "context_type" => "Course",
                              "visited_at" => @dates[2].iso8601,
                              "visited_url" => "http://example.com/courses/X/assignments/Y",
                              "interaction_seconds" => 5.0,
                              "asset_icon" => "icon-assignment",
                              "asset_readable_category" => "Assignment",
                              "asset_name" => "Assign 1",
                              "context_name" => "Something 101" }])
      end

      it "respects course nicknames" do
        @student.set_preference(:course_nicknames, @course.id, "Terribad")
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")
        expect(json[0]["context_name"]).to eq "Terribad"
      end

      it "deals with a missing asset_user_access" do
        AssetUserAccess.where(asset_code: "pages:#{@group.asset_string}").delete_all
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")
        expect(json.pluck("asset_name")).to eq(["Course People", "Assign 1"])
      end

      it "gracefully handles a pv4 timeout" do
        allow(Api).to receive(:paginate).and_raise(PageView::Pv4Client::Pv4Timeout)
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self",
                        expected_status: :bad_gateway)
        expect(json["error"]).to_not be_nil
      end

      it "removes verifier from file preview url" do
        page_view_for url: "http://example.com/courses/X/files/A/file_preview?annotate=B&verifier=C",
                      context: @course,
                      created_at: @dates[3],
                      asset_category: "files",
                      asset_code: "attachment_1"
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")
        expect(json[3]["visited_url"]).to eq "http://example.com/courses/X/files/A/file_preview?annotate=B"
      end
    end

    context "permissions" do
      it "requires a user to be logged in" do
        @user = nil
        api_call(:get,
                 "/api/v1/users/self/history",
                 { controller: "history", action: "index", format: "json", user_id: "self" },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "allows a user to view an observee's history" do
        observer = user_with_pseudonym
        api_call_as_user(observer,
                         :get,
                         "/api/v1/users/#{@student.id}/history",
                         { controller: "history", action: "index", format: "json", user_id: @student.to_param },
                         {},
                         {},
                         { expected_status: 401 })
        UserObservationLink.create_or_restore(observer:, student: @student, root_account: Account.default)
        api_call_as_user(observer,
                         :get,
                         "/api/v1/users/#{@student.id}/history",
                         { controller: "history", action: "index", format: "json", user_id: @student.to_param },
                         {},
                         {},
                         { expected_status: 200 })
      end

      it "allows an admin to view a user's history" do
        @student.set_preference(:course_nicknames, @course.id, "lol not applicable to you")
        json = api_call_as_user(@admin,
                                :get,
                                "/api/v1/users/#{@student.id}/history",
                                { controller: "history", action: "index", format: "json", user_id: @student.to_param },
                                {},
                                {},
                                { expected_status: 200 })
        expect(json[0]["context_name"]).to eq "Something 101"
      end

      it "does not allow a teacher to view a student's history" do
        api_call_as_user(@teacher,
                         :get,
                         "/api/v1/users/#{@student.id}/history",
                         { controller: "history", action: "index", format: "json", user_id: @student.to_param },
                         {},
                         {},
                         { expected_status: 401 })
      end
    end

    context "masquerading" do
      before :once do
        @a1 = @assignment
        @a2 = assignment_model title: "Assign 2", context: @course
        page_view_for url: "http://example.com/courses/X/assignments/Z",
                      context: @course,
                      created_at: @dates[0],
                      asset_category: "assignments",
                      asset_code: @a2.asset_string,
                      real_user: @admin
      end

      it "shows the masquerader the target user's history and not her own" do
        @user = @admin
        json = api_call(:get,
                        "/api/v1/users/self/history?as_user_id=#{@student.id}",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self",
                        as_user_id: @student.to_param)
        expect(json.pluck("asset_name")).to match_array(["Group Pages", "Course People", "Assign 1"])
      end

      it "does not show the target user the masquerader's actions" do
        @user = @student
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")
        expect(json.pluck("asset_name")).to match_array(["Group Pages", "Course People", "Assign 1"])
      end
    end

    context "page view filtering" do
      it "excludes file downloads" do
        a1 = attachment_model context: @course
        page_view_for url: "http://example.com/api/v1/courses/#{@course.id}/files/#{a1.id}/download",
                      context: @course,
                      created_at: @dates[2],
                      asset_category: "attachments",
                      asset_code: a1.asset_string
        a2 = attachment_model context: @course
        page_view_for url: "http://localhost:3000/courses/#{@course.id}/files/#{a2.id}/file_preview?annotate=0",
                      context: @course,
                      created_at: @dates[2],
                      asset_category: "attachments",
                      asset_code: a2.asset_string

        @user = @student
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")

        asset_codes = json.pluck("asset_code")
        expect(asset_codes).not_to include a1.asset_string
        expect(asset_codes).to include a2.asset_string
      end

      it "excludes API calls" do
        other_course = @course
        page_view_for url: "http://example.com/courses/#{other_course.id}/modules",
                      context: other_course,
                      created_at: @dates[1],
                      asset_category: "modules",
                      asset_code: "modules:#{other_course.asset_string}"
        course_with_student(user: @student)
        page_view_for url: "http://example.com/api/v1/courses/#{@course.id}/modules",
                      context: @course,
                      created_at: @dates[1],
                      asset_category: "modules",
                      asset_code: "modules:#{@course.asset_string}"

        @user = @student
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")

        asset_codes = json.pluck("asset_code")
        expect(asset_codes).not_to include "modules:#{@course.asset_string}"
        expect(asset_codes).to include "modules:#{other_course.asset_string}"
      end

      it "excludes unparseable URLs" do
        page1 = @course.wiki_pages.create! title: "test-page-1"
        page_view_for url: "this is not a url",
                      created_at: @dates[0],
                      asset_category: "wiki_pages",
                      asset_code: page1.asset_string

        page2 = @course.wiki_pages.create! title: "test-page-2"
        page_view_for url: "http://example.com/courses/#{@course.id}/pages/test-page-2",
                      created_at: @dates[0],
                      asset_category: "wiki_pages",
                      asset_code: page2.asset_string

        @user = @student
        json = api_call(:get,
                        "/api/v1/users/self/history",
                        controller: "history",
                        action: "index",
                        format: "json",
                        user_id: "self")

        asset_codes = json.pluck("asset_code")
        expect(asset_codes).not_to include page1.asset_string
        expect(asset_codes).to include page2.asset_string
      end
    end
  end
end
