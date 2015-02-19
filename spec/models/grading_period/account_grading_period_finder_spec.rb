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

require 'spec_helper'

describe GradingPeriod::AccountGradingPeriodFinder do
  describe "#grading_periods" do
    let(:grading_period_params) { { weight: 0, start_date: Time.now, end_date: 2.days.from_now } }
    let(:root_account) { Account.create! }
    let(:sub_account) { root_account.sub_accounts.create! }
    let!(:root_account_grading_period) { root_account.grading_period_groups.create!
                                                  .grading_periods.create!(grading_period_params) }
    let!(:sub_account_grading_period) { sub_account.grading_period_groups.create!
                                                  .grading_periods.create!(grading_period_params) }

    context "when context is an account" do
      subject { GradingPeriod::AccountGradingPeriodFinder.new(sub_account).grading_periods }
      it "finds grading periods for the account, and all associated accounts" do

        is_expected.to eq [root_account_grading_period, sub_account_grading_period]
      end
    end
  end
end
