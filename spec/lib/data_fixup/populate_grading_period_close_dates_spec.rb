#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::PopulateGradingPeriodCloseDates do
  before(:each) do
    root_account = Account.create(name: 'new account')
    group = Factories::GradingPeriodGroupHelper.new.create_for_account(root_account)
    period_helper = Factories::GradingPeriodHelper.new
    @first_period = period_helper.create_presets_for_group(group, :past).first
    @first_period.close_date = nil
    @first_period.save!
    @second_period = period_helper.create_presets_for_group(group, :current).first
    @second_period.close_date = 3.days.from_now(@second_period.end_date)
    @second_period.save!
  end

  before(:each) do
    DataFixup::PopulateGradingPeriodCloseDates.run
  end

  it "does not alter already-set close dates" do
    @second_period.reload
    expect(@second_period.close_date).to eq 3.days.from_now(@second_period.end_date)
  end

  it "sets the close date to the end date for periods with nil close dates" do
    @first_period.reload
    expect(@first_period.close_date).to eq @first_period.end_date
  end
end
