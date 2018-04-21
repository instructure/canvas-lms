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

class StudentEnrollment < Enrollment
  belongs_to :student, :foreign_key => :user_id, :class_name => 'User'
  after_save :evaluate_modules, if: Proc.new{ |e|
    # if enrollment switches sections or is created
    e.saved_change_to_course_section_id? || e.saved_change_to_course_id? ||
    # or if an enrollment is deleted and they are in another section of the course
    (e.saved_change_to_workflow_state? && e.workflow_state == 'deleted' &&
     e.user.enrollments.where('id != ?',e.id).active.where(course_id: e.course_id).exists?)
  }

  def student?
    true
  end

  def evaluate_modules
    ContextModuleProgression.for_user(self.user_id).
      joins(:context_module).
      readonly(false).
      where(:context_modules => { :context_type => 'Course', :context_id => self.course_id}).
      each do |prog|
        prog.mark_as_outdated!
      end
  end
end
