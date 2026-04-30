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

module Api::V1::AccessibilityCourseStatistic
  include Api::V1::Json

  ALLOWED_INCLUDES = %w[closed_issue_count course_details].freeze

  def accessibility_course_statistic_json(statistic, user, session, includes: [])
    return nil unless statistic

    fields = %w[id course_id active_issue_count resolved_issue_count workflow_state created_at updated_at]
    fields << "closed_issue_count" if includes.include?("closed_issue_count")
    json = api_json(statistic, user, session, only: fields)
    if includes.include?("course_details")
      json["course_name"] = statistic.course.name
      json["course_code"] = statistic.course.course_code
      json["published"] = statistic.course.published?
    end
    json
  end
end
