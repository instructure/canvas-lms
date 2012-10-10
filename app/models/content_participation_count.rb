#
# Copyright (C) 2012 Instructure, Inc.
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
  attr_accessible :context, :user, :content_type, :unread_count

  belongs_to :context, :polymorphic => true
  belongs_to :user

  def self.create_or_update(opts={})
    opts = opts.with_indifferent_access
    context = opts.delete(:context)
    user = opts.delete(:user)
    type = opts.delete(:content_type)
    return nil unless user && context

    participant = nil
    uncached do
      unique_constraint_retry do
        participant = context.content_participation_counts.find(:first, {
          :conditions => { :user_id => user.id, :content_type => type },
          :lock => true
        })
        if participant.blank?
          participant ||= context.content_participation_counts.build({
            :user => user,
            :content_type => type,
            :unread_count => unread_count_for(type, context, user),
          })
        end
        participant.attributes = opts.slice(*ContentParticipationCount.accessible_attributes.to_a)

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
    when "DiscussionTopic"
      self.unread_discussion_topic_count_for(context, user)
    when "Announcement"
      self.unread_announcement_count_for(context, user)
    when "Submission"
      self.unread_submission_count_for(context, user)
    else
      0
    end
  end

  def self.unread_discussion_topic_count_for(context, user)
    unread_count = 0
    if context.respond_to?(:active_discussion_topics)
      unread_count = context.active_discussion_topics.only_discussion_topics.
        reject{ |dt| dt.read?(user) || dt.locked_for?(user, :check_policies => true) }.
        count
    end
    unread_count
  end

  def self.unread_announcement_count_for(context, user)
    unread_count = 0
    if context.respond_to?(:active_announcements)
      unread_count = context.active_announcements.
        reject{ |dt| dt.read?(user) || dt.locked_for?(user, :check_policies => true) }.
        count
    end
    unread_count
  end

  def self.unread_submission_count_for(context, user, enrollment = nil)
    unread_count = 0
    if context.is_a?(Course)
      enrollment ||= context.enrollments.find(:first, {
        :conditions => { :user_id => user.id },
        :order => "#{Enrollment.state_rank_sql}, #{Enrollment.type_rank_sql}"
      })
      if enrollment.try(:student?)
        submission_conditions = sanitize_sql_for_conditions([<<-SQL, user.id, context.class.to_s, context.id])
          submissions.user_id = ? AND
          assignments.context_type = ? AND
          assignments.context_id = ? AND
          assignments.workflow_state <> 'deleted' AND
          (assignments.muted IS NULL OR NOT assignments.muted)
        SQL
        subs_with_grades = Submission.graded.scoped({
          :select => "submissions.id",
          :joins => :assignment,
          :conditions => "submissions.score IS NOT NULL AND #{submission_conditions}",
        }).map(&:id)
        subs_with_comments = SubmissionComment.scoped({
          :select => "submissions.id",
          :joins => { :submission => :assignment },
          :conditions => [<<-SQL, user.id],
            (submission_comments.hidden IS NULL OR NOT submission_comments.hidden)
            AND submission_comments.author_id <> ?
            AND #{submission_conditions}
            SQL
        }).map(&:id)
        potential_ids = (subs_with_grades + subs_with_comments).uniq
        already_read_count = ContentParticipation.scoped(:conditions => {
          :content_type => "Submission",
          :content_id => potential_ids,
          :user_id => user.id,
          :workflow_state => "read",
        }).count
        unread_count = potential_ids.size - already_read_count
      end
    end
    unread_count
  end

  def unread_count(refresh = true)
    refresh_unread_count if refresh && !frozen? && ttl.present? && self.updated_at.utc < ttl.ago.utc
    read_attribute(:unread_count)
  end

  def refresh_unread_count
    transaction do
      self.unread_count = ContentParticipationCount.unread_count_for(content_type, context, user)
      self.save if self.changed?
    end
  end

  # Things we know of that will only get updated by a refresh:
  # - delayed_post announcements
  # - unlocking discussions/announcements from a module
  # - unmuting an assignment with submissions
  # - deleting a discussion/announcement/assignment/submission
  def ttl
    Setting.get('content_participation_count_ttl', 30.minutes).to_i
  end
  private :ttl
end
