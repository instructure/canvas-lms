#
# Copyright (C) 2014 - present Instructure, Inc.
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

module DataFixup::LinkMissingSisObserverEnrollments
  def self.run
    UserObservationLink.preload(:student, :observer).find_each do |uo|
      uo.student.student_enrollments.active_or_pending.where("sis_batch_id IS NOT NULL").each do |enrollment|
        if enrollment.linked_enrollment_for(uo.observer).nil? && uo.observer.can_be_enrolled_in_course?(enrollment.course)
          new_enrollment = uo.observer.observer_enrollments.build
          new_enrollment.associated_user_id = enrollment.user_id

          new_enrollment.course_id = enrollment.course_id
          new_enrollment.workflow_state = enrollment.workflow_state
          new_enrollment.start_at = enrollment.start_at
          new_enrollment.end_at = enrollment.end_at
          new_enrollment.course_section_id = enrollment.course_section_id
          new_enrollment.root_account_id = enrollment.root_account_id
          new_enrollment.save_without_broadcasting!

          uo.observer.touch
        end
      end
    end
  end
end
