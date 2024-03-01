# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
FactoryBot.define do
  factory :scoring_range, aliases: [:scoring_range_with_bounds], class: ConditionalRelease::ScoringRange do
    rule
    lower_bound { 65 }
    upper_bound { 95 }
    root_account_id { Account.default.id }

    factory :scoring_range_with_assignments do
      transient do
        assignment_set_count { 1 }
        assignment_count { 2 }
      end

      after(:create) do |range, evaluator|
        create_list(:assignment_set_with_assignments,
                    evaluator.assignment_set_count,
                    scoring_range: range,
                    assignment_count: evaluator.assignment_count)
      end
    end
  end
end
