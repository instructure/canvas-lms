# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class ConcludedGradingStandardSetter
  def self.preserve_grading_standard_inheritance
    ConcludedGradingStandardSetter.new.preserve_grading_standard_inheritance
  end

  def preserve_grading_standard_inheritance
    GuardRail.activate(:primary) do
      Course.transaction do
        recently_concluded_courses.find_each do |course|
          course.update_columns(
            grading_standard_id: course.account.default_grading_standard&.id,
            updated_at: Time.zone.now
          )
        end
      end
    end
  end

  private

  def recently_concluded_courses
    now = Time.zone.now
    one_day_ago = 1.day.ago(now)
    Course.left_joins(:enrollment_term)
          .where(
            "((courses.conclude_at BETWEEN :one_day_ago AND :now) AND courses.grading_standard_id IS NULL) OR " \
            "((enrollment_terms.end_at BETWEEN :one_day_ago AND :now) AND courses.grading_standard_id IS NULL AND " \
            "(courses.conclude_at IS NULL))",
            one_day_ago:,
            now:
          )
          .distinct
  end
end
