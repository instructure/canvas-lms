# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

class ContentParticipationCount < ActiveRecord::Base
  ACCESSIBLE_ATTRIBUTES = [:context, :user, :content_type, :unread_count].freeze

  belongs_to :context, polymorphic: [:course]
  belongs_to :user

  before_create :set_root_account_id

  def self.create_or_update(opts={})
    opts = opts.with_indifferent_access
    context = opts.delete(:context)
    user = opts.delete(:user)
    type = opts.delete(:content_type)
    return nil unless user && context

    participant = nil
    context.shard.activate do
      unique_constraint_retry do
        participant = context.content_participation_counts.where(:user_id => user, :content_type => type).lock.first
        if participant.blank?
          participant ||= context.content_participation_counts.build({
            :user => user,
            :content_type => type,
            :unread_count => unread_count_for(type, context, user),
          })
        end
        participant.attributes = opts.slice(*ACCESSIBLE_ATTRIBUTES)

        # if the participant was just created, the count will already be correct
        if opts[:offset].present? && !participant.new_record?
          participant.unread_count = participant.unread_count(!:refresh) + opts[:offset]
        end
        participant.save if participant.new_record? || participant.changed?
      end
    end
    participant
  end

  def self.unread_count_for(type, context, user)
    return 0 unless user.present? && context.present?
    case type
    when "Submission"
      self.unread_submission_count_for(context, user)
    else
      0
    end
  end

  def self.unread_submission_count_for(context, user)
    return 0 unless context.is_a?(Course) && context.user_is_student?(user)
    GuardRail.activate(:secondary) do
      potential_ids = Rails.cache.fetch_with_batched_keys(["potential_unread_submission_ids", context.global_id].cache_key,
          batch_object: user, batched_keys: :submissions) do
        submission_conditions = sanitize_sql_for_conditions([<<~SQL, user.id, context.class.to_s, context.id])
          submissions.user_id = ? AND
          assignments.context_type = ? AND
          assignments.context_id = ? AND
          assignments.workflow_state NOT IN ('deleted', 'unpublished') AND
          assignments.submission_types != 'not_graded' AND
          (assignments.muted IS NULL OR NOT assignments.muted)
        SQL
        subs_with_grades = Submission.active.graded.
            joins(:assignment).
            where(submission_conditions).
            where("submissions.score IS NOT NULL").
            pluck(:id)
        subs_with_comments = Submission.active.
            joins(:assignment, :submission_comments).
            where(submission_conditions).
            where(<<~SQL, user).pluck(:id)
              (submission_comments.hidden IS NULL OR NOT submission_comments.hidden)
              AND NOT submission_comments.draft
              AND submission_comments.provisional_grade_id IS NULL
              AND submission_comments.author_id <> ?
            SQL
        (subs_with_grades + subs_with_comments).uniq
      end
      already_read_count = potential_ids.any? ? ContentParticipation.where(
        :content_type => "Submission",
        :content_id => potential_ids,
        :user_id => user,
        :workflow_state => "read"
      ).count : 0
      potential_ids.size - already_read_count
    end
  end

  def unread_count(refresh = true)
    refresh_unread_count if refresh && !frozen? && ttl.present? && self.updated_at.utc < ttl.seconds.ago.utc
    read_attribute(:unread_count)
  end

  def refresh_unread_count
    self.unread_count = ContentParticipationCount.unread_count_for(content_type, context, user)
    GuardRail.activate(:primary) {self.save} if self.changed?
  end

  def set_root_account_id
    self.root_account_id = self.context&.root_account_id
  end

  # Things we know of that will only get updated by a refresh:
  # - delayed_post announcements
  # - unlocking discussions/announcements from a module
  # - unmuting an assignment with submissions
  # - deleting a discussion/announcement/assignment/submission
  # - marking a previously graded assignment as not_graded
  def ttl
    Setting.get('content_participation_count_ttl', 30.minutes).to_i
  end
  private :ttl
end
