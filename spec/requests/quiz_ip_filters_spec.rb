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
require_relative "../support/request_helper"

describe "Quiz IP Filters API" do
  before :once do
    account_admin_user(active_all: true)
    @account = Account.default
    @course = @account.courses.create!(name: "Test Course")
  end

  describe "GET /api/v1/accounts/:account_id/quiz_ip_filters" do
    def api_call_index(params = {})
      query_string = params.to_query
      url = "/api/v1/accounts/#{@account.id}/quiz_ip_filters"
      url += "?#{query_string}" if query_string.present?
      get url
      response
    end

    context "when user is authorized" do
      before do
        user_session(@admin)
      end

      it "returns an empty list when no filters exist" do
        api_call_index(course_uuid: @course.uuid)
        expect(response).to have_http_status(:ok)
        json = json_parse(response.body)
        expect(json["quiz_ip_filters"]).to be_empty
      end

      it "lists available IP filters" do
        @account.ip_filters = {
          "Filter 1" => "192.168.1.1/24",
          "Filter 2" => "10.0.0.0/8"
        }
        @account.save!

        api_call_index(course_uuid: @course.uuid)
        expect(response).to have_http_status(:ok)
        json = json_parse(response.body)
        expect(json["quiz_ip_filters"].length).to eq 2
      end

      describe "pagination" do
        before do
          account_filters = {}
          (1..40).each do |i|
            account_filters["Filter #{i}"] = "192.168.1.#{i}"
          end
          @account.ip_filters = account_filters
          @account.save!
        end

        it "paginates results" do
          api_call_index(per_page: 25, course_uuid: @course.uuid)
          json = json_parse(response.body)
          expect(json["quiz_ip_filters"].length).to eq 25

          api_call_index(page: 2, per_page: 25, course_uuid: @course.uuid)
          json = json_parse(response.body)
          expect(json["quiz_ip_filters"].length).to eq 15
        end

        it "returns an empty array with a cursor past the end" do
          api_call_index(page: 3, per_page: 25, course_uuid: @course.uuid)
          json = json_parse(response.body)
          expect(json["quiz_ip_filters"]).to be_empty
        end
      end

      describe "search functionality" do
        before do
          @account.ip_filters = { "Test Filter" => "192.168.1.1/24" }
          @account.save!
        end

        it "allows searching by filter name" do
          api_call_index(search_term: "Test", course_uuid: @course.uuid)
          json = json_parse(response.body)
          expect(json["quiz_ip_filters"].length).to eq 1

          api_call_index(search_term: "Nonexistent", course_uuid: @course.uuid)
          json = json_parse(response.body)
          expect(json["quiz_ip_filters"]).to be_empty
        end
      end

      it "renders IP filter objects correctly" do
        @account.ip_filters = { "Test Filter" => "192.168.1.1/24" }
        @account.save!

        api_call_index(course_uuid: @course.uuid)
        json = json_parse(response.body)
        filter = json["quiz_ip_filters"].first
        expect(filter["name"]).to eq "Test Filter"
        expect(filter["account"]).to eq @account.name
        expect(filter["filter"]).to eq "192.168.1.1/24"
      end
    end

    context "when user is unauthorized" do
      it "returns a 401 error" do
        user_model
        api_call_index(course_uuid: @course.uuid)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
