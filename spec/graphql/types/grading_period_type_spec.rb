#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::GradingPeriodType do
  let_once(:grading_period) {
    GradingPeriod.create! start_date: Date.yesterday,
      end_date: Date.tomorrow,
      title: "asdf",
      grading_period_group: GradingPeriodGroup.create!(course: course_factory)
  }

  let(:grading_period_type) {
    GraphQLTypeTester.new(Types::GradingPeriodType, grading_period)
  }

  it "works" do
    expect(grading_period_type._id).to eq grading_period.id
    expect(grading_period_type.title).to eq grading_period.title
    expect(grading_period_type.startDate).to eq grading_period.start_date
    expect(grading_period_type.endDate).to eq grading_period.end_date
  end
end
