#
# Copyright (C) 2014-2016 Instructure, Inc.
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

require 'apis/api_spec_helper'

describe GradingPeriodsController, type: :request do
  let(:now) { Time.zone.now.change(usec: 0) }

  context "A grading period is associated with a course." do
    before :once do
      course_with_teacher active_all: true
      Account.default.set_feature_flag! :multiple_grading_periods, 'on'
      grading_period_group =
        @course.grading_period_groups.create!(title: 'A Group')
      @grading_period = grading_period_group.grading_periods.create! do |period|
        period.title = 'A Period'
        period.start_date = 1.month.from_now(now)
        period.end_date   = 2.months.from_now(now)
        period.weight     = 33.33
      end
    end

    context "multiple grading periods feature flag turned on" do
      describe 'GET show' do
        def get_show(raw = false)
          helper = method(raw ? :raw_api_call : :api_call)
          helper.call(
            :get,
            "/api/v1/courses/#{@course.id}/grading_periods/#{@grading_period.id}",
            {
              controller: 'grading_periods',
              action: 'show',
              format: 'json',
              course_id: @course.id,
              id: @grading_period.id,
            },
            {}
          )
        end

        it "retrieves the grading period specified" do
          json = get_show
          period = json['grading_periods'].first
          expect(period['id']).to eq(@grading_period.id.to_s)
          expect(period['weight']).to eq(@grading_period.weight)
          expect(period['title']).to eq(@grading_period.title)
          expect(period['permissions']).to include(
            "read"   => true,
            "create" => false,
            "delete" => true,
            "update" => true
          )
        end

        it "doesn't return deleted grading periods" do
          @grading_period.destroy
          get_show(true)
          expect(response.status).to eq 404
        end
      end

      describe 'PUT update' do
        def put_update(params, raw=false)
          helper = method(raw ? :raw_api_call : :api_call)

          helper.call(
            :put,
            "/api/v1/courses/#{@course.id}/grading_periods/#{@grading_period.id}",
            {
              controller: 'grading_periods',
              action: 'update',
              format: 'json',
              course_id: @course.id,
              id: @grading_period.id
            },
            { grading_periods: [params] }
          )
        end

        it "updates a grading period successfully" do
          new_weight = @grading_period.weight + 11.11
          put_update(weight: new_weight)
          expect(@grading_period.reload.weight).to eql(new_weight)
        end

        it "doesn't update deleted grading periods" do
          @grading_period.destroy
          put_update({weight: 80}, true)
          expect(response.status).to eq 404
        end
      end

      describe 'DELETE destroy' do
        def delete_destroy
          raw_api_call(
            :delete,
            "/api/v1/courses/#{@course.id}/grading_periods/#{@grading_period.id}",
            {
              controller: 'grading_periods',
              action: 'destroy',
              format: 'json',
              course_id: @course.id,
              id: @grading_period.id.to_s
            },
          )
        end

        it "deletes a grading period successfully" do
          delete_destroy

          expect(response.code).to eq '204'
          expect(@grading_period.reload).to be_deleted
        end
      end
    end

    context "multiple grading periods feature flag turned off" do
      before :once do
        @course.root_account.disable_feature! :multiple_grading_periods
      end

      it "index should return 404" do
        json = api_call(
          :get,
          "/api/v1/courses/#{@course.id}/grading_periods",
          {
            controller: 'grading_periods',
            action: 'index',
            format: 'json',
            course_id: @course.id
          }, {}, {}, expected_status: 404
        )
        expect(json["message"]).to eq('Page not found')
      end
    end
  end
end
