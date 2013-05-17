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

class ObserverEnrollment < Enrollment
  def observer?
    true
  end

  # returns a hash mapping students to arrays of enrollments
  def self.observed_students(context, current_user)
    context.shard.activate do
      observer_enrollments = context.observer_enrollments.where("user_id=? AND associated_user_id IS NOT NULL", current_user)
      observed_students = {}
      observer_enrollments.each do |e|
        student_enrollment = StudentEnrollment.active.find_by_user_id_and_course_id(e.associated_user_id, e.course_id)
        next unless student_enrollment
        student = student_enrollment.user
        observed_students[student] ||= []
        observed_students[student] << student_enrollment
      end
      observed_students
    end
  end
end
