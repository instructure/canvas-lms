# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
module Factories
  def outcome_rollup_model(calculation_method:)
    root_account_id = Account.default.id
    course = Course.create!(name: "Sample Course", account_id: root_account_id)
    user = User.create!
    outcome = LearningOutcome.create!(title: "Sample Outcome", description: "This is a sample outcome.")

    outcome_rollup_attrs = {
      root_account_id:,
      course:,
      user:,
      outcome:,
      calculation_method:,
      aggregate_score: 4.0,
      last_calculated_at: Time.current,
    }

    OutcomeRollup.create!(outcome_rollup_attrs)
  end
end
