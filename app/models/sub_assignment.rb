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

class SubAssignment < AbstractAssignment
  validates :parent_assignment_id, presence: true, comparison: { other_than: :id, message: -> { I18n.t("cannot reference self") }, allow_blank: true }
  validates :has_sub_assignments, inclusion: { in: [false], message: -> { I18n.t("cannot be true for sub assignments") } }
  validates :sub_assignment_tag, inclusion: { in: [CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY] }

  has_one :discussion_topic, through: :parent_assignment

  SUB_ASSIGNMENT_SYNC_ATTRIBUTES = %w[unlock_at lock_at].freeze
  after_save :sync_with_parent, if: :should_sync_with_parent?
  after_commit :aggregate_checkpoint_assignments, if: :checkpoint_changes?

  set_broadcast_policy do |p|
    p.dispatch :checkpoints_created
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
  end

  delegate :effective_group_category_id, to: :parent_assignment

  def checkpoint?
    true
  end

  def checkpoints_parent?
    false
  end

  # AbstractAssignment method with support for sub_assignments
  # link points to the parent assignment as sub_assignments cannot be accessed directly
  def direct_link
    "http://#{HostUrl.context_host(context)}/#{context_url_prefix}/assignments/#{parent_assignment_id}"
  end

  # AbstractAssignment method with support for sub_assignments and sub_assignment overrides
  def to_atom(opts = {})
    extend ApplicationHelper
    author_name = context.present? ? context.name : t("atom_no_author", "No Author")
    content = "#{before_label(:due, "Due")} #{datetime_string(due_at, :due_date)}"
    unless opts[:exclude_description]
      content += "<br/>#{description}<br/><br/>
        <div>
          #{description}
        </div>
      "
    end

    sub_title = title_with_required_replies

    if applied_overrides.present?
      applied_overrides.try(:each) do |override|
        next unless override.due_at_overridden

        sub_title = "#{sub_title} (#{override.title})" if override.title.present?
      end
    end

    sub_title = if opts[:include_context]
                  t(:feed_entry_title_with_course, "Assignment, %{course}: %{sub_title}", sub_title:, course: context.name)
                else
                  t(:feed_entry_title, "Assignment: %{sub_title}", sub_title:)
                end

    due_at_str = due_at.strftime("%Y-%m-%d-%H-%M") rescue "none" # rubocop:disable Style/RescueModifier

    {
      title: sub_title,
      updated: updated_at.utc,
      published: created_at.utc,
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/sub_assignments/#{feed_code}_#{due_at_str}",
      content:,
      link: direct_link,
      author: author_name
    }
  end

  def title_with_required_replies
    required_replies = discussion_topic&.reply_to_entry_required_count || 1
    if sub_assignment_tag == CheckpointLabels::REPLY_TO_TOPIC
      I18n.t("%{title} Reply to Topic", title:)
    elsif sub_assignment_tag == CheckpointLabels::REPLY_TO_ENTRY
      I18n.t("%{title} Required Replies (%{required_replies})", title:, required_replies:)
    else
      title
    end
  end

  private

  def sync_with_parent
    return if saved_by == :parent_assignment || saved_by == :discussion_topic # saved by discussion_topic happens during assignment importer, where update from sub assignment breaks the import of the asset

    changed_attributes = previous_changes.slice(*SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
    parent_assignment.update_from_sub_assignment(changed_attributes)
  end

  def should_sync_with_parent?
    sync_attributes_changed? && saved_by != :parent_assignment
  end

  def sync_attributes_changed?
    previous_changes.keys.intersect?(SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
  end

  def sync_attributes_changes
    previous_changes.slice(*SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
  end

  def aggregate_checkpoint_assignments
    Checkpoints::AssignmentAggregatorService.call(assignment: parent_assignment)
  end

  def checkpoint_changes?
    !!root_account&.feature_enabled?(:discussion_checkpoints) && checkpoint_attributes_changed?
  end

  def checkpoint_attributes_changed?
    tracked_attributes = Checkpoints::AssignmentAggregatorService::AggregateAssignment.members.map(&:to_s) - ["updated_at"]
    relevant_changes = tracked_attributes & previous_changes.keys
    relevant_changes.any?
  end

  def governs_submittable?
    false
  end

  # visibility of sub_assignments is determined by the visibility of their parent assignment
  scope :visible_to_students_in_course_with_da, lambda { |user_ids, course_ids|
    if Account.site_admin.feature_enabled?(:selective_release_backend)
      visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids:, course_ids:).map(&:assignment_id)
      if visible_assignment_ids.any?
        where(parent_assignment_id: visible_assignment_ids)
      else
        none
      end
    else
      joins("JOIN #{AssignmentStudentVisibility.quoted_table_name} AS asv ON asv.assignment_id = assignments.parent_assignment_id")
        .where("assignments.context_id IN (?)
          AND assignments.context_type = 'Course'
          AND asv.course_id IN (?)
          AND asv.user_id = ANY( '{?}'::INT8[] )
        ",
               course_ids,
               course_ids,
               user_ids)
    end
  }
end
