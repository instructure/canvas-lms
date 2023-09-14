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
  ACCESSIBLE_ATTRIBUTES = %i[context user content_type unread_count].freeze

  belongs_to :context, polymorphic: [:course]
  belongs_to :user

  before_create :set_root_account_id

  def self.create_or_update(opts = {})
    opts = opts.with_indifferent_access
    context = opts.delete(:context)
    user = opts.delete(:user)
    type = opts.delete(:content_type)
    return nil unless user && context

    participant = nil
    context.shard.activate do
      unique_constraint_retry do
        participant = context.content_participation_counts.where(user_id: user, content_type: type).lock.first
        if participant.blank?
          unread_count = unread_count_for(type, context, user)
          opts["unread_count"] = unread_count
          participant ||= context.content_participation_counts.build({
                                                                       user:,
                                                                       content_type: type,
                                                                       unread_count:,
                                                                     })
        end
        participant.attributes = opts.slice(*ACCESSIBLE_ATTRIBUTES)

        set_unread_count(participant, opts)

        participant.save if participant.new_record? || participant.changed?
      end
    end
    participant
  end

  def self.set_unread_count(participant, opts = {})
    offset = opts.delete(:offset)
    unread_count = opts.delete(:unread_count)

    # allow setting the unread_count and when not present increment|decrement using an offset
    unless unread_count.is_a?(Integer)
      unread_count = participant.unread_count(refresh: false) + offset.to_i
    end

    participant.unread_count = (unread_count > 0) ? unread_count : 0
  end
  private_class_method :set_unread_count

  def self.unread_count_for(type, context, user)
    return 0 unless user.present? && context.present?

    case type
    when "Submission"
      unread_submission_count_for(context, user)
    else
      0
    end
  end

  def self.potential_submissions_by_type(context, user)
    submission_conditions = sanitize_sql_for_conditions([<<~SQL.squish, user.id, context.class.to_s, context.id])
      submissions.user_id = ? AND
      assignments.context_type = ? AND
      assignments.context_id = ? AND
      assignments.workflow_state NOT IN ('deleted', 'unpublished') AND
      assignments.submission_types != 'not_graded' AND
      (submissions.posted_at IS NOT NULL OR post_policies.post_manually IS FALSE)
    SQL

    subs_with_grades = Submission.active.graded
                                 .joins(assignment: [:post_policy])
                                 .where(submission_conditions)
                                 .where.not(submissions: { score: nil })
                                 .pluck(:id)
    subs_with_comments = Submission.active
                                   .joins(:submission_comments, assignment: [:post_policy])
                                   .where(submission_conditions)
                                   .where(<<~SQL.squish, user).pluck(:id)
                                     (submission_comments.hidden IS NULL OR NOT submission_comments.hidden)
                                     AND NOT submission_comments.draft
                                     AND submission_comments.provisional_grade_id IS NULL
                                     AND submission_comments.author_id <> ?
                                   SQL
    subs_with_assessments = Submission.active
                                      .joins(:rubric_assessments, assignment: [:post_policy])
                                      .where(submission_conditions)
                                      .where.not(rubric_assessments: { data: nil })
                                      .pluck(:id)

    { subs_with_grades:, subs_with_comments:, subs_with_assessments: }
  end

  def self.unread_submission_count_for(context, user)
    return 0 unless context.is_a?(Course) && context.user_is_student?(user)

    GuardRail.activate(:secondary) do
      potential_ids = Rails.cache.fetch_with_batched_keys(["potential_unread_submission_ids", context.global_id].cache_key,
                                                          batch_object: user,
                                                          batched_keys: [:submissions, :potential_unread_submission_ids]) do
        potential_subs_by_type = potential_submissions_by_type(context, user)
        subs_with_grades, subs_with_comments, subs_with_assessments = potential_subs_by_type.values
        (subs_with_grades + subs_with_comments + subs_with_assessments).uniq
      end
      potential_ids.size - already_read_count(potential_ids, user)
    end
  end

  def self.already_read_count(ids = [], user)
    return 0 if ids.empty?

    ContentParticipation.already_read_count(ids, user)
  end

  def unread_count(refresh: true)
    refresh_unread_count if refresh && !frozen? && ttl.present? && updated_at.utc < ttl.seconds.ago.utc
    read_attribute(:unread_count)
  end

  def refresh_unread_count
    self.unread_count = ContentParticipationCount.unread_count_for(content_type, context, user)
    GuardRail.activate(:primary) { save } if changed?
  end

  def set_root_account_id
    self.root_account_id = context&.root_account_id
  end

  # Things we know of that will only get updated by a refresh:
  # - delayed_post announcements
  # - unlocking discussions/announcements from a module
  # - unmuting an assignment with submissions
  # - deleting a discussion/announcement/assignment/submission
  # - marking a previously graded assignment as not_graded
  def ttl
    Setting.get("content_participation_count_ttl", 30.minutes).to_i
  end
  private :ttl
end
