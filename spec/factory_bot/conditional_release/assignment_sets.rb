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
  factory :assignment_set, class: ConditionalRelease::AssignmentSet do
    scoring_range
    root_account_id { Account.default.id }

    factory :assignment_set_with_assignments do
      transient do
        assignment_count { 1 }
      end

      after(:create) do |assignment_set, evaluator|
        create_list(:assignment_set_association, evaluator.assignment_count, assignment_set:)
      end
    end
  end
end
