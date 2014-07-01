#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
  # deprecated
  has_many :conversation_message_participants

  EXPORTABLE_ATTRIBUTES = [
    :id, :conversation_id, :user_id, :last_message_at, :subscribed, :workflow_state, :last_authored_at, :has_attachments, :has_media_objects, :message_count,
    :label, :tags, :visible_last_authored_at, :root_account_ids
  ]

  EXPORTABLE_ASSOCIATIONS = [:conversation, :user]

  after_destroy :destroy_conversation_message_participants

  scope :visible, -> { where("last_message_at IS NOT NULL") }
  scope :default, -> { where(:workflow_state => ['read', 'unread']) }
  scope :unread, -> { where(:workflow_state => 'unread') }
  scope :archived, -> { where(:workflow_state => 'archived') }
  scope :starred, -> { where(:label => 'starred') }
  scope :sent, -> { where("visible_last_authored_at IS NOT NULL").order("visible_last_authored_at DESC, conversation_id DESC") }
  scope :for_masquerading_user, lambda { |user|
    # site admins can see everything
    return scoped if user.account_users.map(&:account_id).include?(Account.site_admin.id)

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

    own_root_account_ids = Shard.birth.activate do
      user.associated_root_accounts.select{ |a| a.grants_right?(user, :become_user) }.map(&:id)
    end
    id_string = "[" + own_root_account_ids.sort.join("][") + "]"
    root_account_id_matcher = "'%[' || REPLACE(conversation_participants.root_account_ids, ',', ']%[') || ']%'"
    where("conversation_participants.root_account_ids <> '' AND " + like_condition('?', root_account_id_matcher, false), id_string)
  }

  # Produces a subscope for conversations in which the given users are
  # participants (either all or any, depending on options[:mode]).
  #
  # The execution of subqueries and general complexity is due to the fact that
  # the existence of a CP for any given user can only be guaranteed on the
  # user's shard and the conversation's shard. To get a condition that can be
  # applied on a single shard (for the scope being constructed) we basically
  # have to execute this condition immediately and then just limit on the
  # resulting ids into the scope we're building.
  #
  # Performance assumptions:
  #
  # * number of unique shards among given user tags is small (there will be one
  #   query per such shard)
  # * the number of unique shards on which those users have conversations is
  #   relatively small (there will be one query per such shard)
  # * number of found conversations is relatively small (each will be
  #   instantiated to get id)
  #
  tagged_scope_handler(/\Auser_(\d+)\z/) do |tags, options|
    if (s = scoped.shard_value) && s.is_a?(Shard)
      scope_shard = s
    end
    scope_shard ||= Shard.current
    exterior_user_ids = tags.map{ |t| t.sub(/\Auser_/, '').to_i }

    # which users have conversations on which shards?
    users_by_conversation_shard =
      ConversationParticipant.users_by_conversation_shard(exterior_user_ids)

    # invert the map (to get shards-for-each-user rather than
    # users-for-each-shard), then combine the keys (shards) according to mode.
    # i.e. if we want conversations with all given users participating,
    # intersect the set of shards; otherwise union them.
    conversation_shards_by_user = {}
    exterior_user_ids.each do |user_id|
      conversation_shards_by_user[user_id] ||= Set.new
    end
    users_by_conversation_shard.each do |shard, user_ids|
      user_ids.each do |user_id|
        user_id = Shard.relative_id_for(user_id, shard, Shard.current)
        conversation_shards_by_user[user_id] << shard
      end
    end
    combinator = (options[:mode] == :or) ? :| : :&
    conversation_shards =
      conversation_shards_by_user.values.inject(combinator).to_a

    # which conversations from those shards include any/all of the given users
    # as participants?
    conditions = Shard.with_each_shard(conversation_shards) do
      user_ids = users_by_conversation_shard[Shard.current]

      shard_conditions = if options[:mode] == :or || user_ids.size == 1
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

      # return arrays because with each shard is gonna try and Array() it
      # anyways, and 1.8.7 would split up the multiline strings.
      if Shard.current == scope_shard
        [sanitize_sql(shard_conditions)]
      else
        with_exclusive_scope do
          conversation_ids = ConversationParticipant.where(shard_conditions).select(:conversation_id).map do |c|
            Shard.relative_id_for(c.conversation_id, Shard.current, scope_shard)
          end
          [sanitize_sql(:conversation_id => conversation_ids)]
        end
      end
    end

    # tagged will flatten a [single_condition] or [] into the list of
    # conditions it's building up, but if we've got multiple conditions here,
    # we want to make sure they're combined with OR regardless of
    # options[:mode], since they're results per shard that we want to combine;
    # each individual condition already takes options[:mode] into account)
    if conditions.size > 1
      "(#{conditions.join(' OR ')})"
    else
      conditions
    end
  end

  tagged_scope_handler(/\A(course|group|section)_(\d+)\z/) do |tags, options|
    tags.map do |tag|
      # tags in the database use the id relative to the default shard. ids in
      # the filters are assumed relative to the current shard and need to be
      # cast to an id relative to the default shard before use in queries.
      type, id = ActiveRecord::Base.parse_asset_string(tag)
      id = Shard.relative_id_for(id, Shard.current, Shard.birth)
      wildcard('conversation_participants.tags', "#{type.underscore}_#{id}", :delimiter => ',')
    end
  end

  cacheable_method :user
  cacheable_method :conversation

  delegate :private?, :to => :conversation
  delegate :context_name, :to => :conversation
  delegate :context_components, :to => :conversation

  before_update :update_unread_count_for_update
  before_destroy :update_unread_count_for_destroy

  attr_accessible :subscribed, :starred, :workflow_state, :user

  validates_presence_of :conversation_id, :user_id, :workflow_state
  validates_inclusion_of :label, :in => ['starred'], :allow_nil => true

  def as_json(options = {})
    latest = last_message
    latest_authored = last_authored_message
    subject = self.conversation.subject
    options[:include_context_info] ||= private?
    {
      :id => conversation_id,
      :subject => subject,
      :workflow_state => workflow_state,
      :last_message => latest ? CanvasTextHelper.truncate_text(latest.body, :max_length => 100) : nil,
      :last_message_at => last_message_at,
      :last_authored_message => latest_authored ? CanvasTextHelper.truncate_text(latest_authored.body, :max_length => 100) : nil,
      :last_authored_message_at => latest_authored ? latest_authored.created_at : visible_last_authored_at,
      :message_count => message_count,
      :subscribed => subscribed?,
      :private => private?,
      :starred => starred,
      :properties => properties(latest || latest_authored)
    }.with_indifferent_access
  end

  def all_messages
    self.conversation.shard.activate do
      if self.conversation.shard == self.shard
        # use a slightly more forgiving backcompat query (since the migration may not have
        # fully filled in user_id yet)
        ConversationMessage.shard(self.conversation.shard).
          select("conversation_messages.*, conversation_message_participants.tags").
          joins(:conversation_message_participants).
          where("conversation_id=? AND (user_id=? OR (conversation_participant_id=? AND user_id IS NULL))", self.conversation_id, self.user_id, self).
          order("created_at DESC, id DESC")
      else
        ConversationMessage.shard(self.conversation.shard).
          select("conversation_messages.*, conversation_message_participants.tags").
          joins(:conversation_message_participants).
          where("conversation_id=? AND user_id=?", self.conversation_id, self.user_id).
          order("created_at DESC, id DESC")
      end
    end
  end

  def messages
    all_messages.where("(workflow_state <> ? OR workflow_state IS NULL)", 'deleted')
  end

  def participants(options = {})
    options = {
      :include_participant_contexts => false,
      :include_indirect_participants => false
    }.merge(options)

    shard.activate do
      Rails.cache.fetch([conversation, user, 'participants', options].cache_key) do
        participants = conversation.participants
        if options[:include_indirect_participants]
          user_ids = messages.map(&:all_forwarded_messages).flatten.map(&:author_id)
          user_ids -= participants.map(&:id)
          participants += Shackles.activate(:slave) { MessageableUser.available.where(:id => user_ids).all }
        end
        if options[:include_participant_contexts]
          # we do this to find out the contexts they share with the user
          user.load_messageable_users(participants, :strict_checks => false)
        else
          participants
        end
      end
    end
  end

  def properties(latest = last_message)
    properties = []
    properties << :last_author if last_author?(latest)
    properties << :attachments if has_attachments?
    properties << :media_objects if has_media_objects?
    properties
  end

  def last_author?(latest = last_message)
    latest && latest.author_id == user_id
  end

  def add_participants(users, options={})
    conversation.add_participants(user, users, options)
  end

  def add_message(body_or_obj, options={})
    conversation.add_message(user, body_or_obj, options.merge(:generated => false))
  end

  # Public: soft deletes the message participants for this conversation
  # participant for the specified messages. May pass :all to soft delete all
  # message participants.
  #
  # to_delete - the list of messages to the delete
  #
  # Returns nothing.
  def remove_messages(*to_delete)
    remove_or_delete_messages(:remove, *to_delete)
  end

  # Public: hard deletes the message participants for this conversation
  # participant for the specified messages. May pass :all to hard delete all
  # message participants.
  #
  # to_delete - the list of messages to the delete
  #
  # Returns nothing.
  def delete_messages(*to_delete)
    remove_or_delete_messages(:delete, *to_delete)
  end

  # Internal: soft or hard delete message participants, based on the indicated
  # operation. Used by remove_messages and delete_messages methods.
  #
  # operation - The operation to perform.
  #             :remove - Only set the workflow state on the message
  #             participants.
  #             :delete to delete the message participants from the database.
  # to_delete - The list of conversation_messages to operate on. This function
  #             only affects the conversation_message_participants for this
  #             participant.
  #
  # Returns nothing.
  def remove_or_delete_messages(operation, *to_delete)
    self.conversation.shard.activate do
      scope = ConversationMessageParticipant.joins(:conversation_message).
          where(:conversation_messages => { :conversation_id => self.conversation_id },
                          :user_id => self.user_id)
      if to_delete == [:all]
        if operation == :delete
          scope.delete_all
        else
          scope.update_all(:workflow_state => 'deleted')
        end
      else
        if operation == :delete
          scope.where(:conversation_message_id => to_delete).delete_all
        else
          scope.where(:conversation_message_id => to_delete).update_all(:workflow_state => 'deleted')
        end
        # if the only messages left are generated ones, e.g. "added
        # bob to the conversation", delete those too
        return remove_or_delete_messages(operation, :all) unless messages.where(:generated => false).exists?
      end
    end
    unless @destroyed
      update_cached_data
      save
    end
  end

  def update_attributes(hash)
    # subscribed= can update the workflow_state, but an explicit
    # workflow_state should trump that. so we do this first
    subscribed = (hash.has_key?(:subscribed) ? hash.delete(:subscribed) : hash.delete('subscribed'))
    self.subscribed = subscribed unless subscribed.nil?
    super
  end

  def recent_messages
    messages.limit(10)
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
  alias :starred? :starred

  def starred=(val)
    # if starred were an actual boolean column, this is the method that would
    # be used to convert strings to appropriate boolean values (e.g. 'true' =>
    # true and 'false' => false)
    val = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(val)
    write_attribute(:label, val ? 'starred' : nil)
  end

  def one_on_one?
    conversation.conversation_participants.size == 2 && private?
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

  def local_context_tags
    context_tags
  end

  def context_tags
    read_attribute(:tags) ? tags.grep(/\A(course|group)_\d+\z/) : infer_tags
  end

  def infer_tags
    conversation.infer_new_tags_for(self, []).first
  end

  def move_to_user(new_user)
    conversation.shard.activate do
      self.class.send :with_exclusive_scope do
        old_shard = self.user.shard
        conversation.conversation_messages.where(:author_id => user_id).update_all(:author_id => new_user)
        if existing = conversation.conversation_participants.find_by_user_id(new_user)
          existing.update_attribute(:workflow_state, workflow_state) if unread? || existing.archived?
          destroy
        else
          ConversationMessageParticipant.joins(:conversation_message).
              where(:conversation_messages => { :conversation_id => self.conversation_id }, :user_id => self.user_id).
              update_all(:user_id => new_user)
          update_attribute :user, new_user
          existing = self
        end
        # replicate ConversationParticipant record to the new user's shard
        if old_shard != new_user.shard && new_user.shard != conversation.shard
          new_cp = existing.clone
          new_cp.shard = new_user.shard
          new_cp.save!
        end
      end
    end
    self.class.send :with_exclusive_scope do
      conversation.regenerate_private_hash! if private?
    end
  end

  attr_writer :last_message
  def last_message
    @last_message ||= messages.human.first if last_message_at
  end

  attr_writer :last_authored_message
  def last_authored_message
    @last_authored_message ||= self.conversation.shard.activate { messages.human.by_user(user_id).first } if visible_last_authored_at
  end

  def self.preload_latest_messages(conversations, author)
    # preload last_message
    ConversationMessage.preload_latest conversations.select(&:last_message_at)
    # preload last_authored_message
    ConversationMessage.preload_latest conversations.select(&:visible_last_authored_at), author
  end

  def self.conversation_ids
    raise "conversation_ids needs to be scoped to a user" unless scoped.where_values.any? do |v|
      if CANVAS_RAILS2
        v =~ /user_id (?:= |IN \()\d+/
      else
        if v.is_a?(Arel::Nodes::Binary) && v.left.is_a?(Arel::Attributes::Attribute)
          v.left.name == 'user_id'
        else
          v =~ /user_id (?:= |IN \()\d+/
        end
      end
    end
    order = 'last_message_at DESC' unless scoped.order_values.present?
    self.order(order).pluck(:conversation_id)
  end

  def self.users_by_conversation_shard(user_ids)
    { Shard.current => user_ids }
  end

  def update_one(update_params)
    case update_params[:event]

    when 'mark_as_read'
      self.workflow_state = 'read'
    when 'mark_as_unread'
      self.workflow_state = 'unread'
    when 'archive'
      self.workflow_state = 'archived'

    when 'star'
      self.starred = true
    when 'unstar'
      self.starred = false

    when 'destroy'
      self.remove_messages(:all)

    end
    self.save!
  end

  def self.do_batch_update(progress, user, conversation_ids, update_params)
    progress_runner = ProgressRunner.new(progress)
    progress_runner.completed_message do |completed_count|
      t('batch_update_message', {
          :one => "1 conversation processed",
          :other => "%{count} conversations processed"
        },
        :count => completed_count)
    end

    progress_runner.do_batch_update(conversation_ids) do |conversation_id|
      participant = user.all_conversations.find_by_conversation_id(conversation_id)
      raise t('not_participating', 'The user is not participating in this conversation') unless participant
      participant.update_one(update_params)
    end
  end

  def self.batch_update(user, conversation_ids, update_params)
    progress = user.progresses.create! :tag => "conversation_batch_update", :completion => 0.0
    job = ConversationParticipant.send_later_enqueue_args(:do_batch_update,
                                                          { no_delay: true },
                                                          progress, user, conversation_ids, update_params)
    progress.user_id = user.id
    progress.delayed_job_id = job.id
    progress.save!
    progress
  end


  protected
  def message_tags
    messages.map(&:tags).inject([], &:concat).uniq
  end

  private

  def destroy_conversation_message_participants
    @destroyed = true
    delete_messages(:all) if self.conversation_id
  end

  def update_unread_count(direction=:up, user_id=self.user_id)
    User.where(:id => user_id).
        update_all(["unread_conversations_count = unread_conversations_count + ?, updated_at = ?", direction == :up ? 1 : -1, Time.now.utc])
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
