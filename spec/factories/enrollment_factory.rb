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

module Factories
  def enrollment_model(opts={})
    @enrollment = factory_with_protected_attributes(StudentEnrollment, valid_enrollment_attributes.merge(opts))
  end

  def valid_enrollment_attributes
    {
      :user => @user,
      :course => @course,
    }
  end

  def multiple_student_enrollment(user, section, opts={})
    course = opts[:course] || @course || course(opts)
    @enrollment = course.enroll_student(user,
                                         :enrollment_state => "active",
                                         :section => section,
                                         :allow_multiple_enrollments => true)
  end

  def create_enrollment_states(enrollment_ids, options)
    enrollment_ids = enrollment_ids.map(&:id) unless enrollment_ids.first.is_a? Fixnum
    create_records(EnrollmentState, enrollment_ids.map { |id| options.merge({ enrollment_id: id}) }, :nil)
  end

  # quickly create an enrollment, bypassing all that AR crap
  def create_enrollment(course, user, options = {})
    create_enrollments(course, [user], {return_type: :record}.merge(options))[0]
  end

  def create_enrollments(course, users, options = {})
    enrollment_state = options[:enrollment_state] || "active"
    sis_batch_id = options[:sis_batch_id]
    associated_user_id = options[:associated_user_id]
    limit_privileges_to_course_section = options[:limit_privileges_to_course_section] || false
    user_ids = users.first.is_a?(User) ?
      users.map(&:id) :
      users

    if options[:account_associations]
      create_records(UserAccountAssociation, user_ids.map{ |id| {account_id: course.account_id, user_id: id, depth: 0}})
    end

    section_id = options[:section_id] || options[:section].try(:id) || course.default_section.id
    type = options[:enrollment_type] || "StudentEnrollment"
    role_id = options[:role].try(:id) || Role.get_built_in_role(type).id
    result = create_records(Enrollment, user_ids.map { |id|
      {
        course_id: course.id,
        user_id: id,
        type: type,
        course_section_id: section_id,
        root_account_id: course.root_account.id,
        workflow_state: enrollment_state,
        role_id: role_id,
        sis_batch_id: sis_batch_id,
        associated_user_id: associated_user_id,
        limit_privileges_to_course_section: limit_privileges_to_course_section
      }
    }, options[:return_type])
    create_enrollment_states(result, {state: enrollment_state})
    result
  end
end
