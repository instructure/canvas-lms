# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module SpeedGrader
  class StudentGroupSelection
    attr_accessor :current_user, :course

    def initialize(current_user:, course:)
      self.current_user = current_user
      self.course = course
    end

    # This method attempts to auto-select a student group when SpeedGrader is
    # loaded and the "Filter SpeedGrader by Student Group" course setting is
    # enabled. Although generally a user must select a group before opening
    # SpeedGrader in Canvas when this setting is active, they can still access
    # specific students directly (say, via an email link), in which case we may
    # need to select a group (if none has been selected) or change the selected
    # group (if it does not contain the requested student). Similarly, we may
    # need to select a group if SpeedGrader is opened without reference to a
    # particular student but no group has been selected.
    def select_group(student_id:)
      reason_for_change = nil
      resolved_group = initial_group

      if student_id.present?
        # If we were given a student ID, try to find a group containing that
        # student, prioritizing the group the viewing user already selected.
        # If the student is part of no groups, the group will just be nil.
        resolved_group = group_containing_student(student_id:)
        if resolved_group != initial_group
          reason_for_change = if resolved_group.blank?
                                # We couldn't find a group for this student
                                :student_in_no_groups
                              elsif initial_group.blank?
                                # No group was selected initially, but we found one
                                :no_group_selected
                              else
                                # We switched from one group to another because this student wasn't in the initial group
                                :student_not_in_selected_group
                              end
        end
      elsif initial_group.blank? || initial_group.group_memberships.active.where(moderator: [false, nil]).none?
        # We weren't given a specific student, but either we didn't previously
        # select a group or we've selected an empty one. Get the first group for
        # the course with at least one student.
        resolved_group = first_group_containing_students
        if resolved_group != initial_group
          reason_for_change = initial_group.blank? ? :no_group_selected : :no_students_in_group
        end
      end

      OpenStruct.new(group: resolved_group, reason_for_change:)
    end

    def group_containing_student(student_id:)
      return initial_group if initial_group.present? && initial_group.group_memberships.active.where(user_id: student_id).exists?

      Group.active.joins(:group_memberships)
           .where(context_id: course.id, context_type: "Course")
           .where(group_memberships: { user_id: student_id })
           .merge(GroupMembership.active)
           .order(:id)
           .first
    end

    def first_group_containing_students
      course.groups.active.joins(:group_memberships)
            .where(GroupMembership.active.where("group_id = groups.id AND moderator IS NOT TRUE").arel.exists)
            .order(:id)
            .first
    end

    def initial_group
      @initial_group ||= begin
        selected_group_id = current_user.get_preference(:gradebook_settings, course.global_id)&.dig("filter_rows_by", "student_group_id")
        selected_group_id.present? ? Group.find_by(id: selected_group_id) : nil
      end
    end
  end
end
