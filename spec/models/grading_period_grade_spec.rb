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

require_relative '../spec_helper'

describe GradingPeriodGrade do
  context "Soft deletion" do
    let(:student) { User.create.student_enrollments.create! course: course }

    let(:account) { Account.create }
    let(:group) { Factories::GradingPeriodGroupHelper.new.create_for_account(account) }
    let(:period) do
      group.grading_periods.create!(
        title: 'a period',
        start_date: 1.week.ago,
        end_date: 2.weeks.from_now,
      )
    end

    let(:creation_arguments) { { grading_period_id: period.id } }
    subject { student.grading_period_grades }
    include_examples "soft deletion"
  end
end
