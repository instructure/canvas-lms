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
  context "A grading period is associated with an account." do
    before :once do
      @account = Account.default
      @account.enable_feature!(:multiple_grading_periods)
      account_admin_user(account: @account)
      user_session(@admin)
      grading_periods count: 3, context: @account
      @account.grading_periods.active.last.destroy
    end

    context "multiple grading periods feature flag turned on" do
      describe 'POST create' do
        let(:weight) { 99 }
        let(:start_date) { 5.months.since(now) }
        let(:end_date) { 8.months.since(now) }
        let(:now) { Time.zone.now.change(usec: 0) }

        def post_create(params, raw=false)
          helper = method(raw ? :raw_api_call : :api_call)
          helper.call(:post,
                      "/api/v1/accounts/#{@account.id}/grading_periods",
                      { controller: 'grading_periods', action: 'create', format: 'json',
                        account_id: @account.id },
                      { grading_periods: [params] }, {}, {})
        end

        context "creates a grading period successfully" do
          subject(:account_grading_periods) { @account.grading_periods }
          before do
            post_create(title: 'a title', weight: weight, start_date: start_date, end_date: end_date)
          end

          it { expect(account_grading_periods.count).to eql 4 }
          it { expect(account_grading_periods.last.weight).to eq weight }
          it { expect(account_grading_periods.last.start_date).to eq start_date }
          it { expect(account_grading_periods.last.end_date).to eq end_date }
        end
      end

      describe 'PUT update' do
        before :once do
          @grading_period = @account.grading_periods.find { |g| g.workflow_state == "active" }
        end

        def put_update(params, raw=false)
          helper = method(raw ? :raw_api_call : :api_call)

          helper.call(:put,
                      "/api/v1/accounts/#{@account.id}/grading_periods/#{@grading_period.id}",
          { controller: 'grading_periods', action: 'update', format: 'json',
            account_id: @account.id,
            id: @grading_period.id },
            { grading_periods: [params] }, {}, {})

        end

        it "updates a grading period successfully" do
          expect(@grading_period.weight).to_not eq(80)
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
          @grading_period = @account.grading_periods.find { |g| g.workflow_state == "active" }
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

    context "multiple grading periods feature flag turned off" do
      before :once do
        @account.disable_feature! :multiple_grading_periods
      end

      it "index should return 404" do
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/grading_periods",
        { controller: 'grading_periods', action: 'index', format: 'json', account_id: @account.id },
        {}, {}, expected_status: 404)
        expect(json["message"]).to eq('Page not found')
      end
    end
  end

  context "A grading period is associated with a course." do
    before :once do
      course_with_teacher active_all: true
      grading_periods count: 3, context: @course
      @course.grading_periods.active.last.destroy
    end
    context "multiple grading periods feature flag turned on" do

      describe 'GET show' do
        before :once do
          @grading_period = @course.grading_periods.active.first
        end

        def get_show(raw = false, data = {})
          helper = method(raw ? :raw_api_call : :api_call)
          helper.call(:get,
                      "/api/v1/courses/#{@course.id}/grading_periods/#{@grading_period.id}",
          { controller: 'grading_periods', action: 'show', format: 'json',
            course_id: @course.id,
            id: @grading_period.id,
          }, data)
        end

        it "retrieves the grading period specified" do
          json = get_show
          period = json['grading_periods'].first
          expect(period['id']).to eq(@grading_period.id.to_s)
          expect(period['weight']).to eq(@grading_period.weight)
          expect(period['title']).to eq(@grading_period.title)
          expect(period['permissions']).to eq("read" => true, "manage" => true)
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
                      "/api/v1/courses/#{@course.id}/grading_periods",
                      { controller: 'grading_periods', action: 'create', format: 'json',
                        course_id: @course.id },
                      { grading_periods: [params] }, {}, {})
        end

        it "creates a grading period successfully" do
          now = Time.zone.now
          post_create(
            title: 'an period',
            weight: 99,
            start_date: 10.month.since(now),
            end_date: 12.month.since(now)
          )
          expect(@course.grading_periods.active.last.weight).to eq(99)
        end
      end

      describe 'PUT update' do
        before :once do
          @grading_period = @course.grading_periods.find { |g| g.workflow_state == "active" }
        end

        def put_update(params, raw=false)
          helper = method(raw ? :raw_api_call : :api_call)

          helper.call(:put,
                      "/api/v1/courses/#{@course.id}/grading_periods/#{@grading_period.id}",
          { controller: 'grading_periods', action: 'update', format: 'json',
            course_id: @course.id,
            id: @grading_period.id },
            { grading_periods: [params] }, {}, {})

        end

        it "updates a grading period successfully" do
          expect(@grading_period.weight).to_not eq(80)
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
          @grading_period = @course.grading_periods.find { |g| g.workflow_state == "active" }
        end

        def delete_destroy
          raw_api_call(:delete,
                       "/api/v1/courses/#{@course.id}/grading_periods/#{@grading_period.id}",
          { controller: 'grading_periods', action: 'destroy', format: 'json',
            course_id: @course.id,
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

    context "multiple grading periods feature flag turned off" do
      before :once do
        @course.root_account.disable_feature! :multiple_grading_periods
      end

      it "index should return 404" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/grading_periods",
        { controller: 'grading_periods', action: 'index', format: 'json', course_id: @course.id },
        {}, {}, expected_status: 404)
        expect(json["message"]).to eq('Page not found')
      end
    end
  end
end
