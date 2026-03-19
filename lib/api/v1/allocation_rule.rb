# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module Api::V1::AllocationRule
  include Api::V1::Json

  def allocation_rule_json(allocation_rule, user, session)
    json_attributes = %w[id must_review review_permitted applies_to_assessor assessor_id assessee_id]
    api_json(allocation_rule, user, session, only: json_attributes)
  end

  def allocation_rules_json(allocation_rules, user, session)
    allocation_rules.map { |allocation_rule| allocation_rule_json(allocation_rule, user, session) }
  end
end
