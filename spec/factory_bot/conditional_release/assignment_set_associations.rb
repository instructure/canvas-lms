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
  factory :assignment_set_association, class: ConditionalRelease::AssignmentSetAssociation do
    association :assignment_set
    root_account_id { Account.default.id }

    before(:create) do |assmt_set_assoc, _evaluator|
      assmt_set_assoc.assignment ||= assmt_set_assoc.assignment_set.scoring_range.rule.course.assignments.create!
    end
  end
end
