#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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
    include_url = includes.include?('html_url')
    include_description = includes.include?('public_description')

    base_attributes = %w(id name course_code account_id start_at default_view)
    methods = ['end_at']
    methods << 'hide_final_grades' if includes.include?(:hide_final_grades)
    allowed_attributes = includes.is_a?(Array) ? base_attributes + includes : base_attributes
    hash = api_json(course, user, session, :only => allowed_attributes, :methods => methods)
    hash['sis_course_id'] = course.sis_source_id if course.root_account.grants_rights?(user, :read_sis, :manage_sis).values.any?
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
    if include_grading && enrollments && enrollments.any? { |e| e.participating_instructor? }
      hash['needs_grading_count'] = course.assignments.active.to_a.sum{|a| a.needs_grading_count_for_user(user)}
    end
    if include_syllabus
      hash['syllabus_body'] = course.syllabus_body
    end
    if include_description
      hash['public_description'] = course.public_description
    end
    hash['hide_final_grades'] = (course.hide_final_grades.to_s == 'true')
    request = self.respond_to?(:request) ? self.request : nil
    hash['html_url'] = course_url(course, :host => HostUrl.context_host(course, request.try(:host_with_port))) if include_url
    hash
  end

  def copy_status_json(import, course, user, session)
    hash = api_json(import, user, session, :only => %w(id progress created_at workflow_state))

    # the type of object for course copy changed but we don't want the api to change
    # so map the workflow states to the old ones
    if hash['workflow_state'] == 'imported'
      hash['workflow_state'] = 'completed'
    elsif !['created', 'failed'].member?(hash['workflow_state'])
      hash['workflow_state'] = 'started'
    end

    hash[:status_url] = api_v1_course_copy_status_url(course, import)
    hash
  end
end
