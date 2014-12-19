#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe GradingPeriodsController, type: :request do
  before :once do
    @account = Account.default
    @account.set_feature_flag!(:multiple_grading_periods, 'on')
    account_admin_user(account: @account)
    user_session(@admin)
  end

  describe 'GET index' do
    before :once do
      now = Time.zone.now
      gps = 3.times.map do |n|
        @account.grading_periods.create!(weight: 50, start_date: n.month.since(now), end_date: (n+1).month.since(now))
      end
      gps.last.destroy
    end

    def get_index(raw = false, data = {}, headers = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/accounts/#{@account.id}/grading_periods",
      { controller: 'grading_periods', action: 'index', format: 'json', account_id: @account.id },
        data,
        headers)
    end

    it "returns all existing grading periods" do
      json = get_index
      periods_json = json['grading_periods']
      expect(periods_json.size).to eq(2)

      periods_json.each do |period|
        expect(period).to have_key('id')
        expect(period).to have_key('account_id')
        expect(period).to have_key('course_id')
        expect(period).to have_key('weight')
        expect(period).to have_key('start_date')
        expect(period).to have_key('end_date')
        expect(period).to have_key('title')
      end
    end

    it "paginates to the jsonapi standard" do
      json = get_index(false, {}, 'Accept' => 'application/vnd.api+json')

      expect(json).to have_key('meta')
      expect(json['meta']).to have_key('pagination')
      expect(json['meta']['primaryCollection']).to eq 'grading_periods'
    end
  end

  describe 'GET show' do
    before :once do
      now = Time.zone.now
      @grading_period = @account.grading_periods.create!(weight: 50, start_date: 1.month.since(now), end_date: 2.month.since(now),
        title: "Grading Period Title")
    end

    def get_show(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
                  "/api/v1/accounts/#{@account.id}/grading_periods/#{@grading_period.id}",
      { controller: 'grading_periods', action: 'show', format: 'json',
        account_id: @account.id.to_s,
        id: @grading_period.id.to_s,
      }, data)
    end

    it "retrieves the grading period specified" do
      json = get_show
      period = json['grading_periods'].first
      expect(period['id']).to eq(@grading_period.id.to_s)
      expect(period['account_id']).to eq(@account.id.to_s)
      expect(period['weight']).to eq(@grading_period.weight)
      expect(period['title']).to eq(@grading_period.title)
    end

    it "doesn't return deleted grading periods" do
      @grading_period.destroy
      get_show(true)
      expect(response.status).to eq 404
    end
  end

  describe 'POST create' do
    def post_create(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:post,
                  "/api/v1/accounts/#{@account.id}/grading_periods",
                  { controller: 'grading_periods', action: 'create', format: 'json', account_id: @account.id },
                  { grading_periods: [params] }, {}, {})
    end

    it "creates a grading period successfully" do
      now = Time.zone.now
      post_create(weight: 99, start_date: 1.month.since(now), end_date: 2.month.since(now))
      expect(@account.grading_periods.first.weight).to eq(99)
    end
  end

  describe 'PUT update' do
    before :once do
      now = Time.zone.now
      @grading_period = @account.grading_periods.create!(weight: 50, start_date: 1.month.since(now), end_date: 2.month.since(now))
    end

    def put_update(params, raw=false)
      helper = method(raw ? :raw_api_call : :api_call)

      helper.call(:put,
                  "/api/v1/accounts/#{@account.id}/grading_periods/#{@grading_period.id}",
      { controller: 'grading_periods', action: 'update', format: 'json',
        account_id: @account.id.to_s,
        id: @grading_period.id.to_s },
        { grading_periods: [params] }, {}, {})

    end

    it "updates a grading period successfully" do
      put_update(weight: 80)
      expect(@grading_period.reload.weight).to eq(80)
    end

    it "doesn't update deleted grading periods" do
      @grading_period.destroy
      put_update({weight: 80}, true)
      expect(response.status).to eq 404
    end
  end

  describe 'DELETE destroy' do
    before :once do
      now = Time.zone.now
      @grading_period = @account.grading_periods.create!(weight: 50, start_date: 1.month.since(now), end_date: 2.month.since(now))
    end

    def delete_destroy
      raw_api_call(:delete,
                   "/api/v1/accounts/#{@account.id}/grading_periods/#{@grading_period.id}",
      { controller: 'grading_periods', action: 'destroy', format: 'json',
        account_id: @account.id,
        id: @grading_period.id.to_s },
        {}, {}, {})
    end

    it "deletes a grading period successfully" do
      delete_destroy

      expect(response.code).to eq '204'
      expect(GradingPeriod.where(id: @grading_period).first).to be_deleted
    end
  end
end
