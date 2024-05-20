# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../cassandra_spec_helper"

describe PageViewsController do
  # Factory-like thing for page views.
  def page_view(user, url, options = {})
    options.reverse_merge!(request_id: "req" + rand(100_000_000).to_s,
                           user_agent: "Firefox/12.0")
    options[:url] = url

    user_req = options.delete(:user_request)
    req_id = options.delete(:request_id)
    created_opt = options.delete(:created_at)
    pg = PageView.new(options)
    pg.user = user
    pg.user_request = user_req
    pg.request_id = req_id
    pg.created_at = created_opt
    pg.updated_at = created_opt
    pg.save!
    pg
  end

  shared_examples_for "GET 'index' as csv" do
    before :once do
      account_admin_user
    end

    before do
      student_in_course
      user_session(@admin)
    end

    it "succeeds" do
      page_view(@user, "/somewhere/in/app", created_at: 2.days.ago)
      get "index", params: { user_id: @user.id }, format: "csv"
      expect(response).to be_successful
    end

    it "orders rows by created_at in DESC order" do
      pv2 = page_view(@user, "/somewhere/in/app", created_at: 2.days.ago) # 2nd day
      pv1 = page_view(@user, "/somewhere/in/app/1", created_at: 1.day.ago) # 1st day
      pv3 = page_view(@user, "/somewhere/in/app/2", created_at: 3.days.ago) # 3rd day
      get "index", params: { user_id: @user.id }, format: "csv"
      expect(response).to be_successful
      dates = CSV.parse(response.body, headers: true).pluck("created_at")
      expect(dates).to eq([pv1, pv2, pv3].map { |pv| pv.created_at.to_s })
    end

    it "errors if end_time is before start_time" do
      get "index", params: { user_id: @user.id, start_time: "2021-07-04", end_time: "2021-07-03" }, format: "csv"
      expect(response).to have_http_status :bad_request
      expect(response.body).to eq "end_time must be after start_time"
    end
  end

  context "with db page views" do
    before :once do
      Setting.set("enable_page_views", true)
    end

    include_examples "GET 'index' as csv"
  end

  context "with cassandra page views" do
    include_examples "cassandra page views"
    include_examples "GET 'index' as csv"

    context "POST 'update'" do
      it "catches a cassandra error" do
        allow(PageView).to receive(:find_for_update).and_raise(CassandraCQL::Error::InvalidRequestException)
        pv = page_view(@student, "/somewhere/in/app/1", created_at: 1.day.ago)

        user_session(@student)
        put "update", params: { id: pv.token, interaction_seconds: "5", page_view_token: pv.token }, xhr: true
        expect(response).to have_http_status :ok
      end
    end
  end

  context "pv4" do
    before do
      allow(PageView).to receive(:pv4?).and_return(true)
      ConfigFile.stub("pv4", {})
    end

    after do
      ConfigFile.unstub
    end

    describe "GET 'index'" do
      it "properly plumbs through time restrictions" do
        account_admin_user
        user_session(@user)

        expect_any_instance_of(PageView::Pv4Client).to receive(:fetch)
          .with(
            @user.global_id,
            start_time: Time.zone.parse("2016-03-14T12:25:55Z"),
            end_time: Time.zone.parse("2016-03-15T00:00:00Z"),
            last_page_view_id: nil,
            limit: 25
          )
          .and_return([])
        get "index",
            params: { user_id: @user.id,
                      start_time: "2016-03-14T12:25:55Z",
                      end_time: "2016-03-15T00:00:00Z",
                      per_page: 25 },
            format: :json
        expect(response).to be_successful
      end

      it "plumbs through time restrictions in csv also" do
        account_admin_user
        user_session(@user)
        Setting.set("page_views_csv_export_rows", "99")
        expect_any_instance_of(PageView::Pv4Client).to receive(:fetch)
          .with(
            @user.global_id,
            start_time: Time.zone.parse("2016-03-14T12:25:55Z"),
            end_time: Time.zone.parse("2016-03-15T00:00:00Z"),
            last_page_view_id: nil,
            limit: 99
          )
          .and_return([])
        get "index",
            params: { user_id: @user.id,
                      start_time: "2016-03-14T12:25:55Z",
                      end_time: "2016-03-15T00:00:00Z" },
            format: :csv
        expect(response).to be_successful
      end
    end
  end
end
