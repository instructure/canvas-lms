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
  include ModelCache

  belongs_to :conversation
  belongs_to :user
  has_many :conversation_message_participants, :dependent => :delete_all
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
  named_scope :for_masquerading_user, lambda { |user|
    # site admins can see everything
    return {} if Account.site_admin.grants_right?(user, :become_user)

    # we need to ensure that the user can access *all* of each conversation's
    # accounts (and that each conversation has at least one account). so given
    # a user who can access accounts 1-5, we construct a sql string like so:
    #  '[1][2][3][4][5]' like '%[' || REPLACE(root_account_ids, ',', ']%[') || ']%'
    #
    # which when applied to a given row would be something like:
    #  '[1][2][3][4][5]' like '%[2]%[4]%'
    #
    # note that we are reliant on root_account_ids always being in order. if
    # they aren't, this scope will be totally broken (it could be written
    # another slower way)
    #
    # we're also counting on conversations being in the join

    own_root_account_ids = user.associated_root_accounts.select{ |a| a.grants_right?(user, :become_user) }.map(&:id)
    id_string = "[" + own_root_account_ids.sort.join("][") + "]"
    root_account_id_matcher = "'%[' || REPLACE(root_account_ids, ',', ']%[') || ']%'"
    {:conditions => ["conversations.root_account_ids <> '' AND " + like_condition('?', root_account_id_matcher, false), id_string]}
  }

  tagged_scope_handler(/\Auser_(\d+)\z/) do |tags, options|
    user_ids = tags.map{ |t| t.sub(/\Auser_/, '').to_i }
    conditions = if options[:mode] == :or || tags.size == 1
      [<<-SQL, user_ids]
      EXISTS (
        SELECT *
        FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND user_id IN (?)
      )
      SQL
    else
      [<<-SQL, user_ids, user_ids.size]
      (
        SELECT COUNT(*)
        FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND user_id IN (?)
      ) = ?
      SQL
    end
    sanitize_sql conditions
  end

  cacheable_method :user
  cacheable_method :conversation

  delegate :private?, :to => :conversation

  before_update :update_unread_count_for_update
  before_destroy :update_unread_count_for_destroy

  attr_accessible :subscribed, :starred, :workflow_state

  validates_inclusion_of :label, :in => ['starred'], :allow_nil => true

  def as_json(options = {})
    latest = last_message
    latest_authored = last_authored_message
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

  def participants(options = {})
    options = {
      :include_participant_contexts => false,
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
    return participants unless options[:include_participant_contexts]
    # we do this to find out the contexts they share with the user
    user.messageable_users(:ids => participants.map(&:id), :skip_visibility_checks => true).each { |user|
      context_info[user.id] = user
    }
    participants.each { |user|
      user.common_courses = user.id == self.user_id ? {} : context_info[user.id].common_courses
      user.common_groups = user.id == self.user_id ? {} : context_info[user.id].common_groups
    }
  end
  memoize :participants

  def properties(latest = last_message)
    properties = []
    properties << :last_author if latest && latest.author_id == user_id
    properties << :attachments if has_attachments?
    properties << :media_objects if has_media_objects?
    properties
  end

  def add_participants(user_ids, options={})
    conversation.add_participants(user, user_ids, options)
  end

  def add_message(body, options={})
    conversation.add_message(user, body, options.merge(:generated => false))
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

  def other_participants(participants=conversation.participants)
    participants.reject { |u| u.id == self.user_id }
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
    if latest = last_message
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
      self.has_attachments = messages.with_attachments.first.present?
      self.has_media_objects = messages.with_media_comments.first.present?
      self.visible_last_authored_at = if latest.author_id == user_id
        latest.created_at
      elsif latest_authored = last_authored_message
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

  def move_to_user(new_user)
    self.class.send :with_exclusive_scope do
      conversation.conversation_messages.update_all(["author_id = ?", new_user.id], ["author_id = ?", user_id])
      if existing = conversation.conversation_participants.find_by_user_id(new_user.id)
        existing.update_attribute(:workflow_state, workflow_state) if unread? || existing.archived?
        destroy
      else
        update_attribute :user_id, new_user.id
      end
      conversation.regenerate_private_hash! if private?
    end
  end

  attr_writer :last_message
  def last_message
    @last_message ||= messages.human.first if last_message_at
  end

  attr_writer :last_authored_message
  def last_authored_message
    @last_authored_message ||= messages.human.by_user(user_id).first if visible_last_authored_at
  end

  def self.preload_latest_messages(conversations, author_id)
    # preload last_message
    ConversationMessage.preload_latest conversations.select(&:last_message_at)
    # preload last_authored_message
    ConversationMessage.preload_latest conversations.select(&:visible_last_authored_at), author_id
  end

  def self.conversation_ids
    scope = current_scoped_methods && current_scoped_methods[:find]
    raise "conversation_ids needs to be scoped to a user" unless scope && scope[:conditions] =~ /user_id = \d+/
    scope[:order] ||= "last_message_at DESC"
    # need to join on conversations in case we use this w/ scopes like for_masquerading_user
    connection.select_all("SELECT conversation_id FROM conversations, conversation_participants WHERE #{scope[:conditions]} AND conversations.id = conversation_participants.conversation_id ORDER BY #{scope[:order]}").
      map{ |row| row['conversation_id'].to_i }
  end

  protected
  def message_tags
    messages.map(&:tags).inject([], &:concat).uniq
  end

  private
  def update_unread_count(direction=:up, user_id=self.user_id)
    User.update_all "unread_conversations_count = unread_conversations_count #{direction == :up ? '+' : '-'} 1, updated_at = '#{Time.now.to_s(:db)}'",
                    :id => user_id
  end

  def update_unread_count_for_update
    if user_id_changed?
      update_unread_count(:up) if unread?
      update_unread_count(:down, user_id_was) if workflow_state_was == 'unread'
    elsif workflow_state_changed? && [workflow_state, workflow_state_was].include?('unread')
      update_unread_count(workflow_state == 'unread' ? :up : :down)
    end
  end

  def update_unread_count_for_destroy
    update_unread_count(:down) if unread?
  end
end
