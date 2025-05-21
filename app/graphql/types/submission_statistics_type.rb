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

module Types
  class SubmissionStatisticsType < ApplicationObjectType
    graphql_name "SubmissionStatistics"

    alias_method :course, :object

    field :submissions_due_this_week_count, Integer, null: false
    def submissions_due_this_week_count
      return 0 unless current_user

      one_week_from_now = Time.zone.now.advance(days: 7)
      Loaders::CourseSubmissionDataLoader.for(
        :submissions_due_this_week_count,
        {
          start_date: Time.zone.now,
          end_date: one_week_from_now,
          current_user:
        }
      ).load(course.id)
    end

    field :missing_submissions_count, Integer, null: false
    def missing_submissions_count
      return 0 unless current_user

      Loaders::CourseSubmissionDataLoader.for(
        :missing_submissions_count,
        { current_user: }
      ).load(course.id)
    end
  end
end
