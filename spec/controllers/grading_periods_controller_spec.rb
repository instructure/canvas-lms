#
# Copyright (C) 2015 Instructure, Inc.
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
require_relative '../spec_helper'

describe GradingPeriodsController do
  describe "GET index" do
    let(:root_account) { Account.default }
    let(:sub_account) { root_account.sub_accounts.create! }

    let(:create_grading_periods) { -> (context, start) {
        context.grading_period_groups.create!
               .grading_periods.create!(weight: 1,
                                        start_date: start,
                                        end_date: (Time.zone.now + 10.days))
      }
    }

    let(:remove_while) { -> (string) {
        string.sub(%r{^while\(1\);}, '')
      }
    }

    before do
      account_admin_user(account: sub_account)
      user_session(@admin)

      root_account.allow_feature!(:multiple_grading_periods)
      root_account.enable_feature!(:multiple_grading_periods)

      create_grading_periods.call(root_account, 3.days.ago)
      create_grading_periods.call(sub_account, Time.zone.now)
    end

    context "when context is a sub account" do
      before do
        get :index, {account_id: sub_account.id}
        @json = JSON.parse(remove_while.call(response.body))
      end

      it "contains two grading periods" do
        expect(@json['grading_periods'].count).to eql 2
      end

      it "paginates" do
        expect(@json).to have_key('meta')
        expect(@json['meta']).to have_key('pagination')
        expect(@json['meta']['primaryCollection']).to eq 'grading_periods'
      end

      it "is ordered by start_date" do
        expect(@json['grading_periods']).to be_sorted_by('start_date')
      end
    end

    context "when context is a course" do
      before do
        course = Course.create!(account: sub_account)

        create_grading_periods.call(course, 5.days.ago)

        get :index, {course_id: course.id}
        @json = JSON.parse(remove_while.call(response.body))
      end

      it "contains three grading periods" do
        expect(@json['grading_periods'].count).to eql 3
      end
    end
  end
end

