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

# Scaling path (Experimentation: live GROUP BY, single-shard, feature-flagged):
#   1. Pre-aggregate into accessibility_course_statistics via a sibling
#      calculator alongside ActiveIssueCalculator.
#   2. Cross-shard via Shard.with_each_shard
#   3. ETag caching on last scan time -- only after step 1.

# Caller is responsible for authorization; no access check here.
class Accessibility::CategoryBreakdownService
  def initialize(course_ids:)
    @course_ids = course_ids
  end

  # @return [Hash] { course_id => { category => { workflow_state => count } } }
  # Unknown rule_types are dropped.
  def call
    return {} if @course_ids.blank?

    rows = AccessibilityIssue
           .where(course_id: @course_ids)
           .group(:course_id, :rule_type, :workflow_state)
           .count

    result = {}
    rows.each do |(course_id, rule_type, workflow_state), count|
      category = Accessibility::Rule.category_for(rule_type)
      if category.nil?
        Rails.logger.warn(
          "[Accessibility::CategoryBreakdownService] dropping unknown rule_type=#{rule_type} count=#{count}"
        )
        next
      end

      result[course_id] ||= {}
      result[course_id][category] ||= {}
      result[course_id][category][workflow_state.to_sym] =
        (result[course_id][category][workflow_state.to_sym] || 0) + count
    end

    result
  end
end
