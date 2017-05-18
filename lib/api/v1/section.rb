#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Api::V1::Section
  include Api::V1::Json
  include Api::V1::PostGradesStatus

  def section_json(section, user, session, includes)
    res = section.as_json(:include_root => false,
                          :only => %w(id name course_id nonxlist_course_id start_at end_at))
    if section.course.grants_any_right?(user, :read_sis, :manage_sis)
      res['sis_section_id'] = section.sis_source_id
      res['sis_course_id'] = section.course.sis_source_id
      res['integration_id'] = section.integration_id
    end
    res['sis_import_id'] = section.sis_batch_id if section.course.grants_right?(user, session, :manage_sis)
    if includes.include?('students')
      proxy = section.enrollments
      if user_json_is_admin?
        proxy = proxy.preload(user: :pseudonyms)
      else
        proxy = proxy.preload(:user)
      end
      include_enrollments = includes.include?('enrollments')
      res['students'] = proxy.where(:type => 'StudentEnrollment').
        map { |e|
          enrollments = include_enrollments ? [e] : nil
          user_json(e.user, user, session, includes, @context, enrollments)
        }
    end
    res['total_students'] = section.students.count if includes.include?('total_students')

    if includes.include?('passback_status')
      res['passback_status'] = post_grades_status_json(section)
    end

    res
  end

  def sections_json(sections, user, session, includes = [])
    sections.map { |s| section_json(s, user, session, includes) }
  end
end
