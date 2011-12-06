#
# Copyright (C) 2011 Instructure, Inc.
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

module Api::V1::Course
  include Api::V1::Json

  def course_json(course, user, session, includes, enrollments)
    include_grading = includes.include?('needs_grading_count')
    include_syllabus = includes.include?('syllabus_body')
    include_total_scores = includes.include?('total_scores') && !course.settings[:hide_final_grade]

    base_attributes = %w(id name course_code)
    allowed_attributes = includes.is_a?(Array) ? base_attributes + includes : base_attributes
    hash = api_json(course, user, session, :only => allowed_attributes)
    hash['sis_course_id'] = course.sis_source_id
    if enrollments
      hash['enrollments'] = enrollments.map do |e|
        h = { :type => e.readable_type.downcase }
        if include_total_scores && e.student?
          h.merge!(
            :computed_current_score => e.computed_current_score,
            :computed_final_score => e.computed_final_score,
            :computed_final_grade => e.computed_final_grade)
        end
        h
      end
    end
    hash['calendar'] = { 'ics' => "#{feeds_calendar_url(course.feed_code)}.ics" }
    if include_grading && enrollments && enrollments.any? { |e| e.participating_admin? }
      hash['needs_grading_count'] = course.assignments.active.sum('needs_grading_count')
    end
    if include_syllabus
      hash['syllabus_body'] = course.syllabus_body
    end
    hash
  end

  def copy_status_json(import, course, user, session)
    hash = api_json(import, user, session, :only => %w(id progress created_at workflow_state))
    hash[:status_url] = api_v1_course_copy_status_path(course, import)
    hash
  end
end

