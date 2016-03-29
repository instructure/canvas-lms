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

def create_enrollments(course, users, options = {})
  user_ids = users.first.is_a?(User) ?
    users.map(&:id) :
    users

  if options[:account_associations]
    create_records(UserAccountAssociation, user_ids.map{ |id| {account_id: course.account_id, user_id: id, depth: 0}})
  end

  section_id = options[:section_id] || course.default_section.id
  type = options[:enrollment_type] || "StudentEnrollment"
  create_records(Enrollment, user_ids.map{ |id| {course_id: course.id, user_id: id, type: type, course_section_id: section_id, root_account_id: course.account.id, workflow_state: 'active', :role_id => Role.get_built_in_role(type).id}}, options[:return_type])
end
