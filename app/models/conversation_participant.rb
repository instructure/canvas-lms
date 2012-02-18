#
# Copyright (C) 2011 Instructure, Inc.
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

class ConversationParticipant < ActiveRecord::Base
  include Workflow
  include TextHelper
  include SimpleTags

  belongs_to :conversation
  belongs_to :user
  has_many :conversation_message_participants
  has_many :messages, :source => :conversation_message,
           :through => :conversation_message_participants,
           :select => "conversation_messages.*, conversation_message_participants.tags",
           :order => "created_at DESC, id DESC",
           :conditions => 'conversation_id = #{conversation_id}'
           # conditions are redundant, but they let us use the best index

  named_scope :visible, :conditions => "last_message_at IS NOT NULL"
  named_scope :default, :conditions => "workflow_state IN ('read', 'unread')"
  named_scope :unread, :conditions => "workflow_state = 'unread'"
  named_scope :archived, :conditions => "workflow_state = 'archived'"
  named_scope :starred, :conditions => "label = 'starred'"
  named_scope :sent, :conditions => "visible_last_authored_at IS NOT NULL", :order => "visible_last_authored_at DESC, conversation_id DESC"
  delegate :private?, :to => :conversation

  before_update :update_unread_count

  attr_accessible :subscribed, :starred, :workflow_state

  validates_inclusion_of :label, :in => ['starred'], :allow_nil => true

  def as_json(options = {})
    latest = options[:last_message] || last_message_at && messages.human.first
    latest_authored = options[:last_authored_message] || visible_last_authored_at && messages.human.by_user(user_id).first
    options[:include_context_info] ||= private?
    {
      :id => conversation_id,
      :workflow_state => workflow_state,
      :last_message => latest ? truncate_text(latest.body, :max_length => 100) : nil,
      :last_message_at => latest ? latest.created_at : last_message_at,
      :last_authored_message => latest_authored ? truncate_text(latest_authored.body, :max_length => 100) : nil,
      :last_authored_message_at => latest_authored ? latest_authored.created_at : visible_last_authored_at,
      :message_count => message_count,
      :subscribed => subscribed?,
      :private => private?,
      :starred => starred,
      :properties => properties(latest)
    }.with_indifferent_access
  end

  [:attachments].each do |association|
    class_eval <<-ASSOC
      def #{association}
        @#{association} ||= conversation.#{association}.scoped(:conditions => <<-SQL)
          EXISTS (
            SELECT 1
            FROM conversation_message_participants
            WHERE conversation_participant_id = \#{id}
              AND conversation_message_id = conversation_messages.id
          )
          SQL
      end
    ASSOC
  end

  def participants(options = {})
    options = {
      :include_context_info => true,
      :include_indirect_participants => false
    }.merge(options)

    context_info = {}
    participants = conversation.participants
    if options[:include_indirect_participants]
      user_ids =
        messages.map(&:all_forwarded_messages).flatten.map(&:author_id) |
        messages.map{
          |m| m.submission.submission_comments.map(&:author_id) if m.submission
        }.compact.flatten
      user_ids -= participants.map(&:id)
      participants += User.find(:all, :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_courses, NULL AS common_groups", :conditions => {:id => user_ids})
    end
    return participants unless options[:include_context_info]
    # we do this to find out the contexts they share with the user
    user.messageable_users(:ids => participants.map(&:id), :no_check_context => true).each { |user|
      context_info[user.id] = user
    }
    participants.each { |user|
      user.common_courses = user.id == self.user_id ? {} : context_info[user.id].common_courses
      user.common_groups = user.id == self.user_id ? {} : context_info[user.id].common_groups
    }
  end
  memoize :participants

  def properties(latest = nil)
    latest ||= messages.human.first
    properties = []
    properties << :last_author if latest && latest.author_id == user_id
    properties << :attachments if has_attachments?
    properties << :media_objects if has_media_objects?
    properties
  end

  def add_participants(user_ids, options={})
    conversation.add_participants(user, user_ids, options)
  end

  def add_message(body, options={}, &blk)
    conversation.add_message(user, body, options.merge(:generated => false), &blk)
  end

  def remove_messages(*to_delete)
    if to_delete == [:all]
      messages.clear
    else
      messages.delete(*to_delete)
      # if the only messages left are generated ones, e.g. "added
      # bob to the conversation", delete those too
      messages.clear if messages.all?(&:generated?)
    end
    update_cached_data
    save
  end

  def update_attributes(hash)
    # subscribed= can update the workflow_state, but an explicit
    # workflow_state should trump that. so we do this first
    subscribed = (hash.has_key?(:subscribed) ? hash.delete(:subscribed) : hash.delete('subscribed'))
    self.subscribed = subscribed unless subscribed.nil?
    super
  end

  def recent_messages
    messages.scoped(:limit => 10)
  end

  def subscribed=(value)
    super unless private?
    if subscribed_changed?
      if subscribed?
        update_cached_data(:recalculate_count => false, :set_last_message_at => false, :regenerate_tags => false)
        self.workflow_state = 'unread' if last_message_at_changed? && last_message_at > last_message_at_was
      else
        self.workflow_state = 'read' if unread?
      end
    end
    subscribed?
  end

  def starred
    read_attribute(:label) == 'starred'
  end

  def starred=(val)
    # if starred were an actual boolean column, this is the method that would
    # be used to convert strings to appropriate boolean values (e.g. 'true' =>
    # true and 'false' => false)
    val = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(val)
    write_attribute(:label, val ? 'starred' : nil)
  end

  def one_on_one?
    conversation.participants.size == 2 && private?
  end

  def other_participants
    conversation.participants - [self.user]
  end

  def other_participant
    other_participants.first
  end

  workflow do
    state :unread
    state :read
    state :archived
  end

  def update_cached_data(options = {})
    options = {:recalculate_count => true, :set_last_message_at => true, :regenerate_tags => true}.update(options)
    if latest = messages.human.first
      self.tags = message_tags if options[:regenerate_tags] && private?
      self.message_count = messages.human.size if options[:recalculate_count]
      self.last_message_at = if last_message_at.nil?
        options[:set_last_message_at] ? latest.created_at : nil
      elsif subscribed?
        latest.created_at
      else
        # not subscribed, so set last_message_at to itself (or if that message
        # was just removed to the closest one before it, or if none, the
        # closest one after it)
        times = messages.map(&:created_at)
        older = times.reject!{ |t| t <= last_message_at} || []
        older.first || times.reverse.first
      end
      self.has_attachments = attachments.size > 0
      self.has_media_objects = messages.with_media_comments.size > 0
      self.visible_last_authored_at = if latest.author_id == user_id
        latest.created_at
      elsif latest_authored = messages.human.by_user(user_id).first
        latest_authored.created_at
      end
    else
      self.tags = nil
      self.workflow_state = 'read' if unread?
      self.message_count = 0
      self.last_message_at = nil
      self.has_attachments = false
      self.has_media_objects = false
      self.starred = false
      self.visible_last_authored_at = nil
    end
    # note that last_authored_at doesn't know/care about messages you may
    # have deleted... this is because it is only used by other participants
    # when displaying the most active participants in the conversation.
    # visible_last_authored_at, otoh, takes into account ones you've deleted
    # (see above)
    if options[:recalculate_last_authored_at]
      my_latest = conversation.conversation_messages.human.by_user(user_id).first
      self.last_authored_at = my_latest ? my_latest.created_at : nil
    end
  end

  def update_cached_data!(*args)
    update_cached_data(*args)
    save!
  end

  def context_tags
    read_attribute(:tags) ? tags.grep(/\A(course|group)_\d+\z/) : infer_tags
  end

  def infer_tags
    conversation.infer_new_tags_for(self, []).first
  end

  protected
  def message_tags
    messages.map(&:tags).inject([], &:concat).uniq
  end

  private
  def update_unread_count
    if workflow_state_changed? && [workflow_state, workflow_state_was].include?('unread')
      User.update_all "unread_conversations_count = unread_conversations_count #{workflow_state == 'unread' ? '+' : '-'} 1, updated_at = '#{Time.now.to_s(:db)}'",
                      :id => user_id
    end
  end
end
