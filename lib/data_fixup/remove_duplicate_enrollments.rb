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

module DataFixup::RemoveDuplicateEnrollments
  def self.run
    recalulate_grades_for = Set.new
    Enrollment.
      select("user_id, type, role_name AS role_name_unhidden, course_section_id, associated_user_id").
      group("user_id, type, role_name, course_section_id, associated_user_id").
      having("COUNT(*) > 1").find_each do |e|
      scope = Enrollment.
        where(user_id: e.user_id,
              type: e.type,
              role_name: e.role_name_unhidden,
              course_section_id: e.course_section_id,
              associated_user_id: e.associated_user_id)

      # prefer active enrollments to have no impact to the end user.
      # then prefer enrollments that were created by sis imports
      # then just keep the newest one.
      keeper = scope.order(Arel.sql("CASE WHEN workflow_state='active' THEN 1
                                     WHEN workflow_state='invited' THEN 2
                                     WHEN workflow_state='creation_pending' THEN 3
                                     WHEN sis_batch_id IS NOT NULL THEN 4
                                     WHEN workflow_state='completed' THEN 5
                                     WHEN workflow_state='rejected' THEN 6
                                     WHEN workflow_state='inactive' THEN 7
                                     WHEN workflow_state='deleted' THEN 8
                                     ELSE 9
                                     END, sis_batch_id DESC, updated_at DESC")).first

      # delete all duplicate
      scope.where("id<>?", keeper).delete_all
      recalulate_grades_for << keeper.user_id if keeper.type == 'StudentEnrollment'
    end

    recalulate_grades_for.each do |u|
      Enrollment.send_later_if_production(:recompute_final_scores, u)
    end

  end
end
