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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper')

require 'csv'

describe PageViewsController do

  # Factory-like thing for page views.
  def page_view(user, url, options={})
    options.reverse_merge!(:request_id => 'req' + rand(100000000).to_s,
                           :user_agent => 'Firefox/12.0')
    options.merge!(:url => url)

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

    before :each do
      student_in_course
      user_session(@admin)
    end

    it "should succeed" do
      page_view(@user, '/somewhere/in/app', :created_at => 2.days.ago)
      get 'index', params: {:user_id => @user.id}, format: 'csv'
      expect(response).to be_successful
    end

    it "should order rows by created_at in DESC order" do
      pv2 = page_view(@user, '/somewhere/in/app', :created_at => 2.days.ago)    # 2nd day
      pv1 = page_view(@user, '/somewhere/in/app/1', :created_at => 1.day.ago)  # 1st day
      pv3 = page_view(@user, '/somewhere/in/app/2', :created_at => 3.days.ago)  # 3rd day
      get 'index', params: {:user_id => @user.id}, format: 'csv'
      expect(response).to be_successful
      dates = CSV.parse(response.body, :headers => true).map { |row| row['created_at'] }
      expect(dates).to eq [pv1, pv2, pv3].map(&:created_at).map(&:to_s)
    end
  end

  context "with db page views" do
    before :once do
      Setting.set('enable_page_views', true)
    end
    include_examples "GET 'index' as csv"
  end

  context "with cassandra page views" do
    include_examples 'cassandra page views'
    include_examples "GET 'index' as csv"

    context "POST 'update'" do
      it "catches a cassandra error" do
        allow(PageView).to receive(:find_for_update).and_raise(CassandraCQL::Error::InvalidRequestException)
        pv = page_view(@student, '/somewhere/in/app/1', :created_at => 1.day.ago)

        user_session(@student)
        put 'update', params: {id: pv.token, interaction_seconds: '5', page_view_token: pv.token}, xhr: true
        expect(response.status).to eq 200
      end
    end
  end

  context "pv4" do
    before do
      allow(PageView).to receive(:pv4?).and_return(true)
      ConfigFile.stub('pv4', {})
    end

    describe "GET 'index'" do
      it "properly plumbs through time restrictions" do
        account_admin_user
        user_session(@user)

        expect_any_instance_of(PageView::Pv4Client).to receive(:fetch).
          with(
            @user.global_id,
            start_time: Time.zone.parse("2016-03-14T12:25:55Z"),
            end_time: Time.zone.parse("2016-03-15T00:00:00Z"),
            last_page_view_id: nil,
            limit: 25).
          and_return([])
        get 'index', params: {user_id: @user.id, start_time: "2016-03-14T12:25:55Z",
            end_time: "2016-03-15T00:00:00Z", per_page: 25}, format: :json
        expect(response).to be_successful
      end
    end
  end
end
