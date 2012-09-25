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
    return 0 unless %w(DiscussionTopic Announcement).include?(type)
    send("unread_#{type.underscore}_count_for", context, user)
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

  def unread_count(refresh = true)
    refresh_count if refresh && !frozen? && self.updated_at.utc < Time.now.utc - stale_after
    read_attribute(:unread_count)
  end

  def refresh_count
    transaction do
      self.unread_count = ContentParticipationCount.unread_count_for(content_type, context, user)
      self.save if self.changed?
    end
  end

  # This is sadness, but because announcements can be post_delayed and
  # discussion_topics can be locked (explicitly or as part of a module) we have
  # to manually refresh our count every so often
  def stale_after
    10.minutes
  end
  private :stale_after
end
