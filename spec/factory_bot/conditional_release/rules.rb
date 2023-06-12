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
  sequence(:user_id)    { |n| 10_000 + n }

  factory :rule, class: ConditionalRelease::Rule do
    root_account_id { Account.default.id }
    course factory: :course

    before(:create) do |rule, _evaluator|
      rule.trigger_assignment ||= rule.course.assignments.create!
    end

    factory :rule_with_scoring_ranges do
      transient do
        scoring_range_count { 2 }
        assignment_set_count { 1 }
        assignment_count { 2 }
      end

      after(:create) do |rule, evaluator|
        values = (0..evaluator.scoring_range_count).collect { |i| i * 1.0 / evaluator.scoring_range_count }
        create_list(
          :scoring_range_with_assignments,
          evaluator.scoring_range_count,
          rule:,
          assignment_set_count: evaluator.assignment_set_count,
          assignment_count: evaluator.assignment_count
        ) do |range|
          # give ascending bounds
          range.lower_bound = values.shift
          range.upper_bound = values[0]
          range.save!
        end
      end
    end
  end
end
