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
  validate :unpublish_ok?, if: -> { will_save_change_to_workflow_state?(to: "unpublished") }

  before_save :before_soft_delete, if: -> { will_save_change_to_workflow_state?(to: "deleted") }

  SUB_ASSIGNMENT_SYNC_ATTRIBUTES = %w[workflow_state unlock_at lock_at grading_type].freeze
  after_commit :update_sub_assignments, if: :sync_attributes_changed?

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

  def checkpoints_parent?
    has_sub_assignments? && root_account&.feature_enabled?(:discussion_checkpoints)
  end

  def update_from_sub_assignment(changed_attributes)
    return unless changed_attributes.keys.intersect?(SubAssignment::SUB_ASSIGNMENT_SYNC_ATTRIBUTES)

    self.saved_by = :sub_assignment
    updates = changed_attributes.slice(*SubAssignment::SUB_ASSIGNMENT_SYNC_ATTRIBUTES)

    updates.each do |attr, (_old_value, new_value)|
      send(:"#{attr}=", new_value)
    end

    save!
    update_sub_assignments
  end

  def has_student_submissions_for_sub_assignments? # rubocop:disable Naming/PredicateName
    return false unless has_sub_assignments?

    sub_assignments.active.any?(&:has_student_submissions?)
  end

  def self.assignment_ids_with_sub_assignment_submissions(assignment_ids)
    Assignment
      .where(id: assignment_ids)
      .joins("LEFT OUTER JOIN #{SubAssignment.quoted_table_name} AS sub_assignments ON assignments.id = sub_assignments.parent_assignment_id")
      .where(Submission.active.having_submission.where("submissions.assignment_id=sub_assignments.id").arel.exists)
      .distinct
      .pluck("sub_assignments.parent_assignment_id")
  end

  # AbstractAssignment method with added support for sub_assignment submisssions
  def can_unpublish?
    return true if new_record?
    return @can_unpublish unless @can_unpublish.nil?

    @can_unpublish = !has_student_submissions? && !has_student_submissions_for_sub_assignments?
  end
  attr_writer :can_unpublish

  # AbstractAssignment method with added support for sub_assignment submisssions
  def self.preload_can_unpublish(assignments, assmnt_ids_with_subs = nil)
    return unless assignments.any?

    assignment_ids = assignments.map(&:id)
    assmnt_ids_with_subs ||= (assignment_ids_with_submissions(assignment_ids) + assignment_ids_with_sub_assignment_submissions(assignment_ids)).uniq
    assignments.each { |a| a.can_unpublish = !assmnt_ids_with_subs.include?(a.id) }
  end

  private

  def before_soft_delete
    sub_assignments.destroy_all
  end

  def governs_submittable?
    true
  end

  def update_sub_assignments
    return unless has_sub_assignments?

    changed_attributes = previous_changes.slice(*SUB_ASSIGNMENT_SYNC_ATTRIBUTES)

    sub_assignments.active.each do |checkpoint|
      updates = {}
      changed_attributes.each do |attr, (_, new_value)|
        updates[attr] = new_value if checkpoint.respond_to?(:"#{attr}=")
      end
      next unless updates.any?

      checkpoint.saved_by = :parent_assignment
      checkpoint.update!(updates)
      checkpoint.saved_by = nil
    end
  end

  def sync_attributes_changed?
    previous_changes.keys.intersect?(SUB_ASSIGNMENT_SYNC_ATTRIBUTES) && saved_by != :sub_assignment
  end

  def sync_attributes_changes
    previous_changes.slice(*SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
  end

  def unpublish_ok?
    if has_student_submissions? || has_student_submissions_for_sub_assignments?
      errors.add :workflow_state, I18n.t("Can't unpublish if there are student submissions for the assignment or its sub_assignments")
    end
  end
end
