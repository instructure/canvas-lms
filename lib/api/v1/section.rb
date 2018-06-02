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

  def section_json(section, user, session, includes, options = {})
    res = section.as_json(:include_root => false,
                          :only => %w(id name course_id nonxlist_course_id start_at end_at restrict_enrollments_to_section_dates))
    if options[:allow_sis_ids] || section.course.grants_any_right?(user, :read_sis, :manage_sis)
      res['sis_section_id'] = section.sis_source_id
      res['sis_course_id'] = section.course.sis_source_id
      res['integration_id'] = section.integration_id
    end
    res['sis_import_id'] = section.sis_batch_id if section.course.grants_right?(user, session, :manage_sis)
    if includes.include?('students')
      proxy = section.enrollments.preload(:root_account, :sis_pseudonym, user: :pseudonyms)
      include_enrollments = includes.include?('enrollments')
      res['students'] = []
      proxy.where(:type => 'StudentEnrollment').find_each do |e|
        enrollments = include_enrollments ? [e] : nil
        res['students'] << user_json(e.user, user, session, includes, @context, enrollments, [], e)
      end
      res['students'] = nil if res['students'].empty?
    end
    res['total_students'] = section.students.not_fake_student.count if includes.include?('total_students')

    if includes.include?('passback_status')
      res['passback_status'] = post_grades_status_json(section)
    end

    if includes.include?('user_count')
      res['user_count'] = section.enrollments.not_fake.active_or_pending_by_date_ignoring_access.count
    end

    res
  end

  def sections_json(sections, user, session, includes = [], options = {})
    sections.map { |s| section_json(s, user, session, includes, options) }
  end
end
