# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Assignment < AbstractAssignment
  validates :parent_assignment_id, :sub_assignment_tag, absence: true

  before_save :before_soft_delete, if: -> { will_save_change_to_workflow_state?(to: "deleted") }

  set_broadcast_policy do |p|
    p.dispatch :assignment_due_date_changed
    p.to do |assignment|
      # everyone who is _not_ covered by an assignment override affecting due_at
      # (the AssignmentOverride records will take care of notifying those users)
      excluded_ids = participants_with_overridden_due_at.to_set(&:id)
      BroadcastPolicies::AssignmentParticipants.new(assignment, excluded_ids).to
    end
    p.whenever do |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment)
                                         .should_dispatch_assignment_due_date_changed?
    end
    p.data { course_broadcast_data }

    p.dispatch :assignment_changed
    p.to do |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    end
    p.whenever do |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment)
                                         .should_dispatch_assignment_changed?
    end
    p.data { course_broadcast_data }

    p.dispatch :assignment_created
    p.to do |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    end
    p.whenever do |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment)
                                         .should_dispatch_assignment_created?
    end
    p.data { course_broadcast_data }
    p.filter_asset_by_recipient do |assignment, user|
      assignment.overridden_for(user, skip_clone: true)
    end

    p.dispatch :submissions_posted
    p.to do |assignment|
      assignment.course.participating_instructors
    end
    p.whenever do |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment)
                                         .should_dispatch_submissions_posted?
    end
    p.data do |record|
      if record.posting_params_for_notifications.present?
        record.posting_params_for_notifications.merge(course_broadcast_data)
      else
        course_broadcast_data
      end
    end
  end

  def effective_group_category_id
    group_category_id || discussion_topic&.group_category_id
  end

  def find_checkpoint(sub_assignment_tag)
    sub_assignments.find_by(sub_assignment_tag:)
  end

  include SmartSearchable
  use_smart_search title_column: :title,
                   body_column: :description,
                   index_scope: ->(course) { course.assignments.active },
                   search_scope: ->(course, user) { Assignments::ScopedToUser.new(course, user, course.assignments.active).scope }

  private

  def before_soft_delete
    sub_assignments.destroy_all
  end

  def governs_submittable?
    true
  end
end
