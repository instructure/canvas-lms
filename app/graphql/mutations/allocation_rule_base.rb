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

module Mutations
  class AllocationRuleBase < BaseMutation
    argument :applies_to_assessor, Boolean, required: false, default_value: true
    argument :assessee_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
    argument :assessor_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
    argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
    argument :must_review, Boolean, required: false, default_value: true
    argument :reciprocal, Boolean, required: false, default_value: false
    argument :review_permitted, Boolean, required: false, default_value: true

    field :allocation_rules, [Types::AllocationRuleType], null: true
  end
end
