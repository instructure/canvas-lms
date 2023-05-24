# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::PopulateRootAccountIdForEnrollmentDatesOverrides do
  let(:account) { account_model }

  describe(".run") do
    it "updates the root_account_id" do
      course_with_teacher(account: account, active_all: true)
      term = @course.enrollment_term
      override = term.enrollment_dates_overrides.create!(
        enrollment_type: "TeacherEnrollment",
        end_at: 1.week.from_now,
        context: account
      )
      # callbacks / validations skipped
      override.update_column(:root_account_id, nil)

      expect(override.reload.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdForEnrollmentDatesOverrides.run

      expect(override.reload.root_account_id).to eq account.id
    end
  end
end
