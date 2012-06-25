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

class Conversation < ActiveRecord::Base
  include SimpleTags
  include ModelCache
  cacheable_by :id, :private_hash

  has_many :conversation_participants, :dependent => :destroy
  has_many :conversation_messages, :order => "created_at DESC, id DESC", :dependent => :delete_all

  # see also User#messageable_users
  has_many :participants,
    :through => :conversation_participants,
    :source => :user,
    :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_courses, NULL AS common_groups",
    :order => 'last_authored_at IS NULL, last_authored_at DESC, LOWER(COALESCE(short_name, name))'

  attr_accessible

  def private?
    private_hash.present?
  end

  def self.find_all_private_conversations(user_id, other_user_ids)
    find_all_by_private_hash(other_user_ids.map{ |id| private_hash_for([user_id, id])})
  end

  def self.private_hash_for(user_ids)
    Digest::SHA1.hexdigest(user_ids.uniq.sort.join(','))
  end

  def self.initiate(user_ids, private)
    user_ids = user_ids.map(&:to_i).uniq
    private_hash = private ? private_hash_for(user_ids) : nil
    transaction do
      unless private_hash && conversation = find_by_private_hash(private_hash)
        conversation = new
        conversation.private_hash = private_hash
        conversation.has_attachments = false
        conversation.has_media_objects = false
        conversation.tags = []
        conversation.save!
        connection.bulk_insert('conversation_participants', user_ids.map{ |user_id|
          {
            :conversation_id => conversation.id,
            :user_id => user_id,
            :workflow_state => 'read',
            :has_attachments => false,
            :has_media_objects => false,
            :tags => ''
          }
        })
      end
      conversation
    end
  end

  #
  # ==== Arguments
  # * <tt>asset</tt> - The asset with conversation_messages to update.
  # * <tt>options</tt> - Options for special behavior.
  #
  # ==== Options
  # * <tt>:delete_all</tt> - Boolean option. If +true+, all of the asset's conversation messages are destroyed.
  # * <tt>:only_existing</tt> - Boolean option. If +true+, only existing ones are updated. No new ones are created.
  # Additional options are passed on further but not directly used here.
  # * <tt>:update_participants</tt> - Boolean option.
  # * <tt>:skip_ids</tt> - Array of IDs to skip.
  # * <tt>:recalculate_count</tt> - Boolean
  # * <tt>:recalculate_last_authored_at</tt> - Boolean
  def self.update_all_for_asset(asset, options)
    transaction do
      asset.lock!
      if options[:delete_all]
        asset.conversation_messages.destroy_all
        return
      end

      groups = asset.conversation_groups

      conversations = if groups.empty?
        []
      elsif options[:only_existing]
        find_all_by_private_hash(groups.map{ |g| private_hash_for(g) }, :lock => true)
      else
        groups.map{ |g| initiate(g, true) }.each(&:lock!)
      end

      current_messages = conversations.map{ |c| c.update_for_asset(asset, options) }

      # delete asset messages from obsolete conversations (e.g. once the first
      # instructor comments on a submission, remove it from conversations
      # between the submitter and other instructors)
      (asset.conversation_messages - current_messages).each(&:destroy)
    end
  end

  #
  # ==== Arguments
  # * <tt>asset</tt> - The asset with conversation_messages to update.
  # * <tt>options</tt> - Options for special behavior.
  #
  # ==== Options
  # * <tt>:update_participants</tt> - Boolean option.
  def update_for_asset(asset, options)
    message = asset.conversation_messages.detect { |m| m.conversation_id == id }
    if message
      add_message_to_participants(message, options) # make sure it gets re-added
    else
      message = add_message(asset.user, '', options.merge(:asset => asset, :update_participants => false, :root_account_id => asset.context.try(:root_account_id)))
    end
    if (data = asset.conversation_message_data).present?
      message.created_at = data[:created_at]
      message.author_id = data[:author_id]
      message.body = data[:body]
      message.save!
    end

    if options[:update_participants]
      update_participants message, options
    else
      conversation_participants.each{ |cp| cp.update_cached_data!(options.merge(:set_last_message_at => false)) }
    end
    message
  end

  def add_participants(current_user, user_ids, options={})
    user_ids = user_ids.map(&:to_i).uniq
    raise "can't add participants to a private conversation" if private?
    transaction do
      lock!
      user_ids -= conversation_participants.map(&:user_id)
      next if user_ids.empty?

      last_message_at = conversation_messages.human.first.created_at
      raise "can't add participants if there are no messages" unless last_message_at
      num_messages = conversation_messages.human.size

      User.update_all(["unread_conversations_count = unread_conversations_count + 1, updated_at = ?", Time.now.utc], :id => user_ids)

      connection.bulk_insert('conversation_participants', user_ids.map{ |user_id|
        {
          :conversation_id => id,
          :user_id => user_id,
          :workflow_state => 'unread',
          :has_attachments => has_attachments?,
          :has_media_objects => has_media_objects?,
          :last_message_at => last_message_at,
          :message_count => num_messages
        }
      })

      # give them all messages
      # NOTE: individual messages in group conversations don't have tags
      connection.execute(sanitize_sql([<<-SQL, self.id, user_ids]))
        INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id)
        SELECT conversation_messages.id, conversation_participants.id
        FROM conversation_messages, conversation_participants
        WHERE conversation_messages.conversation_id = ?
          AND conversation_messages.conversation_id = conversation_participants.conversation_id
          AND conversation_participants.user_id IN (?)
      SQL

      # announce their arrival
      add_event_message(current_user, {:event_type => :users_added, :user_ids => user_ids}, options)
    end
  end

  def add_event_message(current_user, event_data={}, options={})
    add_message(current_user, event_data.to_yaml, options.merge(:generated => true))
  end

  # Add message to this conversation.
  #
  # ==== Arguments
  # * <tt>current_user</tt> - The user who is creating the message.
  # * <tt>body</tt> - Message body to add.
  #
  # ==== Options
  # * <tt>:generated</tt> - Boolean. If the message was generated.
  # * <tt>:update_for_sender</tt> - Boolean
  # * <tt>:only_existing</tt> - Boolean
  # * <tt>:update_participants</tt> - Boolean. Defaults to true unless message was :generated. Will update all
  #                                   participants with the new message.
  # * <tt>:update_for_skips</tt> - Boolean. Defaults to true (or :update_for_sender).
  # * <tt>:skip_ids</tt> - Array of IDs. Defaults to the current_user only.
  # * <tt>:tags</tt> - Array of tags for the message.
  # * <tt>:root_account_id</tt> - The root account ID to link to the conversation. When set, the message context
  #                               is the Account.
  # * <tt>:asset</tt> - The asset to attach to the message
  # * <tt>:attachment_ids</tt> - The attachment_ids to link to the new message. Defaults to nil.
  # * <tt>:media_comment</tt> - The media_comment for the message. Defaults to nil.
  # * <tt>:forwarded_message_ids</tt> - Array of message IDs to forward. Only if forwardable and limited to 1.
  def add_message(current_user, body, options = {})
    transaction do
      lock!

      options = {:generated => false,
                 :update_for_sender => true,
                 :only_existing => false}.update(options)
      options[:update_participants] = !options[:generated]         unless options.has_key?(:update_participants)
      options[:update_for_skips]    = options[:update_for_sender]  unless options.has_key?(:update_for_skips)
      options[:skip_ids]          ||= [current_user.id]

      # all specified (or implicit) tags, regardless of visibility to individual participants
      new_tags = options[:tags] ? options[:tags] & current_context_strings(1) : []
      new_tags = current_context_strings if new_tags.blank? && tags.empty? # i.e. we're creating the first message and there are no tags yet
      self.tags |= new_tags if new_tags.present?
      self.root_account_ids |= [options[:root_account_id]] if options[:root_account_id].present?
      save! if new_tags.present? || root_account_ids_changed?

      message = conversation_messages.build
      message.author_id = current_user.id
      message.body = body
      message.generated = options[:generated]
      if options[:root_account_id]
        message.context_type = 'Account'
        message.context_id = options[:root_account_id]
      end
      message.asset = options[:asset]
      message.attachment_ids = options[:attachment_ids] if options[:attachment_ids].present?
      message.media_comment = options[:media_comment] if options[:media_comment].present?
      if options[:forwarded_message_ids].present?
        messages = ConversationMessage.find_all_by_id(options[:forwarded_message_ids].map(&:to_i))
        conversation_ids = messages.select(&:forwardable?).map(&:conversation_id).uniq
        raise "can only forward one conversation at a time" if conversation_ids.size != 1
        raise "user doesn't have permission to forward these messages" unless current_user.conversations.find_by_conversation_id(conversation_ids.first)
        # TODO: optimize me
        message.forwarded_message_ids = messages.map(&:id).join(',')
      end
      # so we can take advantage of other preloaded associations
      ConversationMessage.send :add_preloaded_record_to_collection, [message], :conversation, self
      message.save!

      add_message_to_participants(message, options.merge(:tags => new_tags, :new_message => true))
      if options[:update_participants]
        update_participants(message, options)
      end
      message
    end
  end

  # Add the message to the conversation for all the participants.
  #
  # ==== Arguments
  # * <tt>message</tt> - Message to add to conversation for participants.
  # * <tt>options</tt> - Additional options.
  #
  # ==== Options
  # * <tt>:only_existing</tt> - Boolean value. If +true+, include only currently visible conversation participants.
  #                             When +false+, all participants are included.
  # * <tt>:new_message</tt> - Boolean value. When +false+, excludes already involved participants from receiving
  #                           the message. Otherwise, the participants receive it.
  # * <tt>:tags</tt> - Array of tags for the message data.
  def add_message_to_participants(message, options = {})
    cps = options[:only_existing] ?
      conversation_participants.visible :
      conversation_participants

    unless options[:new_message]
      skip_ids = ConversationMessageParticipant.for_conversation_and_message(id, message.id).map(&:conversation_participant_id)
      cps = cps.scoped(:conditions => ["id NOT IN (?)", skip_ids]) if skip_ids.present?
    end

    ConversationParticipant.update_all("message_count = message_count + 1", ["id IN (?)", cps.map(&:id)]) unless options[:generated]

    all_new_tags = options[:tags] || []
    message_data = []
    ConversationMessage.preload_latest(cps) if private? && !all_new_tags.present?
    cps.each do |cp|
      next unless cp.user
      new_tags, message_tags = infer_new_tags_for(cp, all_new_tags)
      cp.update_attribute :tags, cp.tags | new_tags if new_tags.present?
      message_data << {
        :conversation_message_id => message.id,
        :conversation_participant_id => cp.id,
        :tags => message_tags ? serialized_tags(message_tags) : nil
      }
    end

    connection.bulk_insert "conversation_message_participants", message_data
  end

  def infer_new_tags_for(cp, all_new_tags)
    new_tags = []
    if all_new_tags.present?
      # limit it to what they can see
      new_tags = all_new_tags & cp.user.conversation_context_codes
    end
    # if they don't have any tags yet (e.g. this is the first message) and
    # there are no new tags, just get the best possible match(es)
    if new_tags.empty? && cp.tags.empty?
      new_tags = current_context_strings & cp.user.conversation_context_codes
    end

    # see ConversationParticipant#update_cached_data ... tags are only
    # recomputed for private conversations, so for group ones we don't bother
    # tracking at the message level
    message_tags = if private?
      if new_tags.present?
        new_tags
      elsif cp.message_count > 0 and last_message = cp.last_message
        last_message.tags
      end
    end

    [new_tags, message_tags]
  end

  def update_participants(message, options = {})
    skip_ids = options[:skip_ids] || [message.author_id]
    skip_ids = [0] if skip_ids.empty?
    update_for_skips = options[:update_for_skips] != false

    # make sure this jumps to the top of the inbox and is marked as unread for anyone who's subscribed
    cp_conditions = sanitize_sql([
      "cp.conversation_id = ? AND cp.workflow_state <> 'unread' AND (cp.last_message_at IS NULL OR cp.subscribed) AND cp.user_id NOT IN (?)",
      self.id,
      skip_ids
    ])
    if connection.adapter_name =~ /mysql/i
      connection.execute <<-SQL
        UPDATE users, conversation_participants cp
        SET unread_conversations_count = unread_conversations_count + 1
        WHERE users.id = cp.user_id AND #{cp_conditions}
      SQL
    else
      User.update_all 'unread_conversations_count = unread_conversations_count + 1',
                      "id IN (SELECT user_id FROM conversation_participants cp WHERE #{cp_conditions})"
    end
    conversation_participants.update_all(
      {:last_message_at => message.created_at, :workflow_state => 'unread'},
      ["(last_message_at IS NULL OR subscribed) AND user_id NOT IN (?)", skip_ids]
    )

    # for the sender (or override(s)), we just update the timestamps (if
    # needed). for last_authored_at, we ignore update_for_skips, since the
    # column is only viewed by the other participants and doesn't care about
    # what messages the author may have deleted
    updates = [
      maybe_update_timestamp('last_message_at', message.created_at, update_for_skips ? [] : ["last_message_at IS NOT NULL"]),
      maybe_update_timestamp('last_authored_at', message.created_at, ["user_id = ?", message.author_id]),
      maybe_update_timestamp('visible_last_authored_at', message.created_at, ["user_id = ?", message.author_id])
    ]
    updates << "workflow_state = CASE WHEN workflow_state = 'archived' THEN 'read' ELSE workflow_state END" if update_for_skips
    conversation_participants.update_all(updates.join(", "), ["user_id IN (?)", skip_ids])

    updated = false
    if message.attachment_ids.present?
      self.has_attachments = true
      conversation_participants.update_all({:has_attachments => true}, "NOT has_attachments")
      updated = true
    end
    if message.media_comment_id.present?
      self.has_media_objects = true
      conversation_participants.update_all({:has_media_objects => true}, "NOT has_media_objects")
      updated = true
    end
    self.save if updated
  end

  def subscribed_participants
    ConversationParticipant.send(:preload_associations, conversation_participants, :user) unless ModelCache[:users]
    conversation_participants.select(&:subscribed?).map(&:user).compact
  end

  def reply_from(opts)
    user = opts.delete(:user)
    message = opts.delete(:text).to_s.strip
    user = nil unless user && self.participants.find_by_id(user.id)
    if !user
      raise "Only message participants may reply to messages"
    elsif message.blank?
      raise "Message body cannot be blank"
    else
      add_message(user, message, opts)
    end
  end

  def migrate_context_tags!
    return unless tags.empty?
    transaction do
      lock!
      cps = conversation_participants(:include => :user).all
      update_attribute :tags, current_context_strings
      cps.each do |cp|
        next unless cp.user
        cp.update_attribute :tags, current_context_strings & cp.user.conversation_context_codes
        cp.conversation_message_participants.update_all ["tags = ?", serialized_tags(cp.tags)] if private?
      end
    end
  end

  def self.batch_migrate_context_tags!(ids)
    find_all_by_id(ids).each(&:migrate_context_tags!)
  end

  # if the participant list has changed, e.g. we merged user accounts
  def regenerate_private_hash!(user_ids = nil)
    return unless private?
    self.private_hash = Conversation.private_hash_for(user_ids || self.participant_ids)
    return unless private_hash_changed?
    if existing = Conversation.find_by_private_hash(private_hash)
      merge_into(existing)
    else
      save!
    end
  end

  def self.batch_regenerate_private_hashes!(ids)
    find(:all,
     :select => "conversations.*, (SELECT #{connection.func(:group_concat, :user_id, ',')} FROM conversation_participants WHERE conversation_id = conversations.id) AS user_ids",
     :conditions => {:id => ids}
    ).each do |c|
      c.regenerate_private_hash!(c.user_ids.split(',').map(&:to_i)) # group_concat order is arbitrary in sqlite, so we just let ruby do the sorting
    end
  end

  def merge_into(other)
    transaction do
      new_participants = other.conversation_participants.inject({}){ |h,p| h[p.user_id] = p; h }
      conversation_participants(true).each do |cp|
        if new_cp = new_participants[cp.user_id]
          new_cp.update_attribute(:workflow_state, cp.workflow_state) if cp.unread? || new_cp.archived?
          cp.conversation_message_participants.update_all(["conversation_participant_id = ?", new_cp.id])
          cp.destroy
        else
          cp.update_attribute(:conversation_id, other.id)
        end
      end
      conversation_messages.update_all(["conversation_id = ?", other.id])
      conversation_participants.reload # now empty ... need to make sure callbacks don't double-delete
      other.conversation_participants(true).each do |cp|
        cp.update_cached_data! :recalculate_count => true, :set_last_message_at => false, :regenerate_tags => false
      end
      destroy
    end
  end

  def root_account_ids
    (read_attribute(:root_account_ids) || '').split(',').map(&:to_i)
  end

  def root_account_ids=(ids)
    # ids must be sorted for the scope to work
    write_attribute(:root_account_ids, ids.sort.join(','))
  end

  # rails' has_many-:through preloading doesn't preserve :select or :order
  # options, so we roll our own that does (plus we do it in one query so we
  # don't load conversation_participants into memory)
  def self.preload_participants(conversations)
    user_map = User.find_by_sql(sanitize_sql([<<-SQL, conversations.map(&:id)])).group_by(&:conversation_id)
      SELECT #{reflections[:participants].options[:select]}, conversation_id
      FROM users, conversation_participants
      WHERE users.id = conversation_participants.user_id
        AND conversation_id IN (?)
      ORDER BY #{reflections[:participants].options[:order]}
    SQL
    conversations.each do |conversation|
      send :add_preloaded_records_to_collection, [conversation], :participants, user_map[conversation.id.to_s] 
    end
  end

  # contexts currently shared by > 50% of participants
  # note that these may not all be relevant for a specific participant, so
  # they should be and-ed with User#conversation_context_codes
  # returns best matches first
  def current_context_strings(threshold = nil)
    participants = conversation_participants.to_a
    return [] if private? && participants.size == 1

    threshold ||= participants.size / 2

    participants.inject([]){ |ary, cp|
      cp.user ? ary.concat(cp.user.conversation_context_codes) : ary
    }.sort.inject({}){ |hash, str|
      hash[str] = (hash[str] || 0) + 1
      hash
    }.select{ |key, value|
      value > threshold
    }.sort_by(&:last).map(&:first).reverse
  end
  memoize :current_context_strings

  protected

  def maybe_update_timestamp(col, val, additional_conditions=[])
    condition = self.class.merge_conditions(["(#{col} IS NULL OR #{col} < ?)", val], additional_conditions)
    sanitize_sql ["#{col} = CASE WHEN #{condition} THEN ? ELSE #{col} END", val]
  end
end
