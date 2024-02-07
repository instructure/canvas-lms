# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include SendToStream
  include ConversationHelper

  has_many :conversation_participants, dependent: :destroy
  has_many :conversation_messages, -> { order("created_at DESC, id DESC") }, dependent: :delete_all
  has_many :conversation_message_participants, through: :conversation_messages
  has_one :stream_item, as: :asset
  belongs_to :context, polymorphic: %i[account course group]

  before_save :update_root_account_ids

  validates :subject, length: { maximum: maximum_string_length, allow_nil: true }

  attr_accessor :latest_messages_from_stream_item

  def participants(reload = false)
    if !@participants || reload
      Conversation.preload_participants([self])
    end
    @participants
  end

  def reload(options = nil)
    @current_context_strings = {}
    @participants = nil
    super
  end

  def private?
    private_hash.present?
  end

  def self.find_all_private_conversations(user, other_users, context_type: nil, context_id: nil)
    code = "#{context_type}_#{context_id}" if context_type && context_id
    user.all_conversations.where(private_hash: other_users.map { |u| private_hash_for([user, u], code) }).map(&:conversation)
  end

  def self.private_hash_for(users_or_user_ids, context_code = nil)
    user_ids = if users_or_user_ids.first.is_a?(User)
                 Shard.birth.activate { users_or_user_ids.map(&:id) }
               else
                 users_or_user_ids
               end
    str = user_ids.uniq.sort.join(",")
    str += "|#{context_code}" if context_code
    Digest::SHA1.hexdigest(str)
  end

  def bulk_insert_participants(user_ids, options = {})
    options = {
      conversation_id: id,
      workflow_state: "read",
      has_attachments: has_attachments?,
      has_media_objects: has_media_objects?,
      root_account_ids: read_attribute(:root_account_ids)
    }.merge(options)
    ConversationParticipant.bulk_insert(user_ids.map do |user_id|
      options.merge({ user_id: })
    end)
  end

  def self.initiate(users, private, options = {})
    users = users.uniq(&:id)
    user_ids = users.map(&:id)
    context_code = options[:context_type] && options[:context_id] && "#{options[:context_type]}_#{options[:context_id]}"
    private_hash = private ? private_hash_for(users, context_code) : nil
    transaction do
      if private
        conversation = users.first.all_conversations.except(:preload).where(private_hash:).first.try(:conversation)
        if !conversation && context_code
          # try to match with an existing conversation but make sure the context matches
          conversation = users.first.all_conversations.except(:preload).where(private_hash: private_hash_for(users)).joins(:conversation)
                              .where(conversations: { context_type: options[:context_type], context_id: options[:context_id] }).first.try(:conversation)
        end
      end

      unless conversation
        conversation = new
        conversation.private_hash = private_hash
        conversation.has_attachments = false
        conversation.has_media_objects = false
        conversation.context_type = options[:context_type]
        conversation.context_id = options[:context_id]
        if conversation.context
          conversation.root_account_ids |= [Shard.relative_id_for(conversation.context.resolved_root_account_id, Shard.current, Shard.birth)]
        end
        conversation.tags = [conversation.context_string].compact
        conversation.tags += [conversation.context.context.asset_string] if conversation.context_type == "Group"
        conversation.subject = options[:subject]
        conversation.save!

        # TODO: transaction on these shards as well?
        bulk_insert_options = {
          tags: "",
          private_hash:
        }
        Shard.partition_by_shard(user_ids) do |shard_user_ids|
          next if Shard.current == conversation.shard

          conversation.bulk_insert_participants(shard_user_ids, bulk_insert_options)
        end
        # the conversation's shard gets a full copy
        conversation.bulk_insert_participants(user_ids, bulk_insert_options)
      end
      conversation
    end
  end

  # conversations with more recipients than this should force individual messages
  def self.max_group_conversation_size
    Setting.get("max_group_conversation_size", 100).to_i
  end

  def can_add_participants?(users)
    (users.map(&:id) + conversation_participants.pluck(:user_id)).uniq.count <= self.class.max_group_conversation_size + 1
  end

  def add_participants(current_user, users, options = {})
    message = nil
    shard.activate do
      user_ids = users.map(&:id).uniq
      raise "can't add participants to a private conversation" if private?

      transaction do
        lock!
        user_ids -= conversation_participants.map(&:user_id)
        next if user_ids.empty?

        if options[:no_messages]
          bulk_insert_options = {
            workflow_state: "unread",
            message_count: 0,
            private_hash:
          }
        else
          last_message_at = conversation_messages.human.first.try(:created_at)
          raise "can't add participants if there are no messages" unless last_message_at

          num_messages = conversation_messages.human.size

          bulk_insert_options = {
            workflow_state: "unread",
            last_message_at:,
            message_count: num_messages,
            private_hash:
          }
        end

        Shard.partition_by_shard(user_ids) do |shard_user_ids|
          unless shard_user_ids.empty?
            shard_user_ids.sort!
            shard_user_ids.each_slice(1000) do |sliced_user_ids|
              User.where(id: sliced_user_ids).update_all(["unread_conversations_count = unread_conversations_count + 1, updated_at = ?", Time.now.utc])
            end
          end

          next if Shard.current == shard

          bulk_insert_participants(shard_user_ids, bulk_insert_options)
        end
        # the conversation's shard gets a participant for all users
        bulk_insert_participants(user_ids, bulk_insert_options)

        unless options[:no_messages]
          # give them all messages
          # NOTE: individual messages in group conversations don't have tags
          self.class.connection.execute(sanitize_sql([<<~SQL.squish, id, current_user.id, user_ids]))
            INSERT INTO #{ConversationMessageParticipant.quoted_table_name}(conversation_message_id, conversation_participant_id, user_id, workflow_state, root_account_ids)
            SELECT conversation_messages.id, conversation_participants.id, conversation_participants.user_id, 'active', '#{read_attribute(:root_account_ids)}'
            FROM #{ConversationMessage.quoted_table_name}, #{ConversationParticipant.quoted_table_name}, #{ConversationMessageParticipant.quoted_table_name}
            WHERE conversation_messages.conversation_id = ?
              AND conversation_messages.conversation_id = conversation_participants.conversation_id
            AND conversation_message_participants.conversation_message_id = conversation_messages.id
            AND conversation_message_participants.user_id = ?
              AND conversation_participants.user_id IN (?)
          SQL

          # announce their arrival
          message = add_event_message(current_user, { event_type: :users_added, user_ids: }, options)
        end
        touch
        Canvas::LiveEvents.conversation_forwarded(self)
      end
    end
    message
  end

  def add_event_message(current_user, event_data = {}, options = {})
    add_message(current_user, event_data.to_yaml, options.merge(generated: true))
  end

  # Add message to this conversation.
  #
  # ==== Arguments
  # * <tt>current_user</tt> - The user who is creating the message.
  # * <tt>body_or_obj</tt> - Message body or ConversationMessage instance to add
  #
  # ==== Options
  # * <tt>:generated</tt> - Boolean. If the message was generated.
  # * <tt>:update_for_sender</tt> - Boolean
  # * <tt>:only_existing</tt> - Boolean
  # * <tt>:update_participants</tt> - Boolean. Defaults to true unless message was :generated. Will update all
  #                                   participants with the new message.
  # * <tt>:update_for_skips</tt> - Boolean. Defaults to true (or :update_for_sender).
  # * <tt>:skip_users</tt> - Array of users. Defaults to the current_user only.
  # * <tt>:tags</tt> - Array of tags for the message.
  # * <tt>:root_account_id</tt> - The root account ID to link to the conversation. When set, the message context
  #                               is the Account.
  # * <tt>:asset</tt> - The asset to attach to the message
  # * <tt>:attachment_ids</tt> - The attachment_ids to link to the new message. Defaults to nil.
  # * <tt>:media_comment</tt> - The media_comment for the message. Defaults to nil.
  # * <tt>:forwarded_message_ids</tt> - Array of message IDs to forward. Only if forwardable and limited to 1.
  def add_message(current_user, body_or_obj, options = {})
    message = transaction do
      lock!

      options = { generated: false,
                  update_for_sender: true,
                  only_existing: false }.update(options)
      options[:update_participants] = !options[:generated]         unless options.key?(:update_participants)
      options[:update_for_skips]    = options[:update_for_sender]  unless options.key?(:update_for_skips)
      options[:skip_users]        ||= [current_user]
      options[:reset_unread_counts] = options[:update_participants] unless options.key?(:reset_unread_counts)

      message = if body_or_obj.is_a?(ConversationMessage)
                  body_or_obj
                else
                  Conversation.build_message(current_user, body_or_obj, options)
                end
      message.conversation = self
      message.relativize_attachment_ids(from_shard: message.shard, to_shard: shard)
      message.shard = shard

      if options[:cc_author]
        message.cc_author = options[:cc_author]
      end

      # all specified (or implicit) tags, regardless of visibility to individual participants
      users = preload_users_and_context_codes
      new_tags = options[:tags] ? options[:tags] & current_context_strings(1, users) : []
      new_tags = current_context_strings(nil, users) if new_tags.blank? && tags.empty? # i.e. we're creating the first message and there are no tags yet
      self.tags |= new_tags if new_tags.present?
      Shard.birth.activate do
        self.root_account_ids |= [message.root_account_id] if message.root_account_id
      end

      # we should not need to update participants' root_account_ids unless the conversations
      # ids have changed, but the participants' root_account_ids were not being set for
      # a long time so we set them all the time for fixing up purposes
      # add this check back in when the data is fixed or we decide to run a fixup.
      options[:root_account_ids] = read_attribute(:root_account_ids) # if self.root_account_ids_changed?
      save! if new_tags.present? || root_account_ids_changed?

      # so we can take advantage of other preloaded associations
      message.association(:conversation).target = self
      message.save_without_broadcasting!

      add_message_to_participants(message, options.merge(
                                             tags: new_tags,
                                             new_message: true,
                                             preloaded_users: users,
                                             only_users: options[:only_users]
                                           ))

      if options[:update_participants]
        update_participants(message, options)
      end
      message
    end

    # now that the message participants are all saved, we can properly broadcast to recipients
    message.after_participants_created_broadcast
    delay_if_production.reset_unread_counts if options[:reset_unread_counts]
    message
  end

  def reset_unread_counts
    Shard.partition_by_shard(conversation_participants.pluck(:user_id)) do |shard_user_ids|
      shard_user_ids.compact.sort.each_slice(1000) do |sliced_ids|
        counts_by_user_id = ConversationParticipant.visible.unread.where(user_id: sliced_ids).group(:user_id).count
        User.where(id: sliced_ids).select(:id, :unread_conversations_count).each do |user|
          user.reset_unread_conversations_counter(counts_by_user_id[user.id] || 0)
        end
      end
    end
  end

  def self.build_message(current_user, body, options = {})
    message = ConversationMessage.new
    message.author_id = current_user.id
    message.body = body
    message.generated = options[:generated] || false
    if options[:root_account_id]
      message.context_type = "Account"
      message.context_id = options[:root_account_id]
    end

    message.asset = options[:asset]
    message.attachment_ids = options[:attachment_ids] if options[:attachment_ids].present?
    message.media_comment = options[:media_comment] if options[:media_comment].present?
    if options[:forwarded_message_ids].present?
      messages = ConversationMessage.where(id: options[:forwarded_message_ids].map(&:to_i))
      conversation_ids = messages.select(&:forwardable?).map(&:conversation_id).uniq
      raise "can only forward one conversation at a time" if conversation_ids.size != 1
      raise "user doesn't have permission to forward these messages" unless current_user.all_conversations.where(conversation_id: conversation_ids.first).exists?

      # TODO: optimize me
      message.forwarded_message_ids = messages.map(&:id).join(",")
    end
    message.generate_user_note = true if options[:generate_user_note]
    message
  end

  def preload_users_and_context_codes
    users = User.where(id: conversation_participants.map(&:user_id)).pluck(:id, :updated_at).map do |id, updated_at|
      User.send(:instantiate, "id" => id, "updated_at" => updated_at)
    end
    User.preload_conversation_context_codes(users)
    users.index_by(&:id)
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
    unless options[:new_message]
      skip_participants = message.conversation_message_participants.active.select(:user_id).to_a
    end

    conversation_participants.shard(self).activate do |cps|
      cps.update_all(root_account_ids: options[:root_account_ids]) if options[:root_account_ids].present?

      cps = cps.visible if options[:only_existing]

      if !options[:new_message] && skip_participants.present?
        cps = cps.where.not(user_id: skip_participants.map(&:user_id))
      end

      cps = cps.where(user_id: (options[:only_users] + [message.author]).map(&:id)) if options[:only_users]

      next unless cps.exists?

      cps.update_all("message_count = message_count + 1") unless options[:generated]

      if shard == Shard.current
        users = options[:preloaded_users] || preload_users_and_context_codes
        current_context_strings(nil, users)

        all_new_tags = options[:tags] || []
        message_participant_data = []
        ConversationMessage.preload_latest(cps) if private? && all_new_tags.blank?
        cps.each do |cp|
          cp.user = users[cp.user_id]
          next unless cp.user

          new_tags, message_tags = infer_new_tags_for(cp, all_new_tags)
          if new_tags.present?
            updated_tags = if (active_tags = cp.user.conversation_context_codes(false)).present?
                             (cp.tags | new_tags) & active_tags
                           else
                             cp.tags | new_tags
                           end

            cp.update_attribute(:tags, updated_tags)
            if cp.user.shard != shard
              cp.user.shard.activate do
                ConversationParticipant.where(conversation_id: self, user_id: cp.user_id)
                                       .update_all(tags: serialized_tags(cp.tags))
              end
            end
          end
          message_participant_data << {
            conversation_message_id: message.id,
            conversation_participant_id: cp.id,
            user_id: cp.user_id,
            tags: message_tags ? serialized_tags(message_tags) : nil,
            workflow_state: "active",
            root_account_ids: read_attribute(:root_account_ids)
          }
        end
        # some of the participants we're about to insert may have been soft-deleted,
        # so we'll hard-delete them before reinserting. It would probably be better
        # to update them instead, but meh.
        inserting_user_ids = message_participant_data.pluck(:user_id)
        ConversationMessageParticipant.unique_constraint_retry do
          ConversationMessageParticipant.where(
            conversation_message_id: message.id, user_id: inserting_user_ids
          ).delete_all
          ConversationMessageParticipant.bulk_insert message_participant_data
        end
      end
    end
  end

  def context_components
    if context_type.nil? && context_tags.first
      ActiveRecord::Base.parse_asset_string(context_tags.first)
    else
      [context_type, context_id]
    end
  end

  def context_name
    name = context.try(:name)
    name ||= Context.find_by_asset_string(context_tags.first).try(:name) if context_tags.first
    name
  end

  def context_code
    if context_type && context_id
      "#{context_type.underscore}_#{context_id}"
    else
      nil
    end
  end

  def context_tags
    tags.grep(/\A(course|group)_\d+\z/)
  end

  def infer_new_tags_for(participant, all_new_tags)
    active_tags   = participant.user.conversation_context_codes(false)
    context_codes = active_tags.presence || participant.user.conversation_context_codes
    visible_codes = all_new_tags & context_codes

    # limit available codes to codes the user can see
    # otherwise, use all of the available tags
    new_tags = visible_codes.presence || (current_context_strings & context_codes)

    message_tags = if private?
                     if new_tags.present?
                       new_tags
                     elsif participant.message_count > 0 && (last_message = participant.last_message)
                       last_message.tags
                     end
                   end

    [new_tags, message_tags]
  end

  def update_participants(message, options = {})
    updated = false
    conversation_participants.shard(self).activate do |conversation_participants|
      if options[:only_users]
        conversation_participants = conversation_participants.where(user_id:           (options[:only_users]).map(&:id))
      end

      skip_ids = options[:skip_users].try(:map, &:id) || [message.author_id]
      update_for_skips = options[:update_for_skips] != false

      conversation_participants.where("(last_message_at IS NULL OR subscribed) AND user_id NOT IN (?)", skip_ids)
                               .update_all(last_message_at: message.created_at, workflow_state: "unread")

      # for the sender (or override(s)), we just update the timestamps (if
      # needed). for last_authored_at, we ignore update_for_skips, since the
      # column is only viewed by the other participants and doesn't care about
      # what messages the author may have deleted
      updates = [
        maybe_update_timestamp("last_message_at", message.created_at, update_for_skips ? [] : ["last_message_at IS NOT NULL AND user_id NOT IN (?)", skip_ids]),
        maybe_update_timestamp("last_authored_at", message.created_at, ["user_id = ?", message.author_id]),
        maybe_update_timestamp("visible_last_authored_at", message.created_at, ["user_id = ?", message.author_id])
      ]
      updates << "workflow_state = CASE WHEN workflow_state = 'archived' THEN 'read' ELSE workflow_state END" if update_for_skips
      conversation_participants.where(user_id: skip_ids).update_all(updates.join(", "))

      if message.has_attachments?
        self.has_attachments = true
        conversation_participants.where(has_attachments: false).update_all(has_attachments: true)
        updated = true
      end
      if message.has_media_objects?
        self.has_media_objects = true
        conversation_participants.where(has_media_objects: false).update_all(has_media_objects: true)
        updated = true
      end
    end
    save if updated
  end

  def subscribed_participants
    ActiveRecord::Associations.preload(conversation_participants, :user) unless ModelCache[:users]
    conversation_participants.select(&:subscribed?).filter_map(&:user)
  end

  def reply_from(opts)
    user = opts.delete(:user)
    message = opts.delete(:text).to_s.strip
    participant = conversation_participants.where(user_id: user).first
    user = nil unless user && participant
    if user
      raise IncomingMail::Errors::InvalidParticipant if replies_locked_for?(user, conversation_participants.map(&:user_id))

      participant.update_attribute(:workflow_state, "read") if participant.workflow_state == "unread"
      message = truncate_message(message)
      add_message(user, message, opts)
    else
      raise IncomingMail::Errors::InvalidParticipant
    end
  end

  def truncate_message(message)
    if message.length < 64.kilobytes - 1
      message
    else
      message[0..64.kilobytes - 100] + I18n.t("... This message was truncated.")
    end
  end

  def migrate_context_tags!
    return unless tags.empty?

    transaction do
      lock!
      cps = conversation_participants.preload(:user).to_a
      update_attribute :tags, current_context_strings
      cps.each do |cp|
        next unless cp.user

        cp.update_attribute :tags, current_context_strings & cp.user.conversation_context_codes
        cp.conversation_message_participants.update_all(tags: serialized_tags(cp.tags)) if private?
      end
    end
  end

  def self.batch_migrate_context_tags!(ids)
    where(id: ids).each(&:migrate_context_tags!)
  end

  # if the participant list has changed, e.g. we merged user accounts
  def regenerate_private_hash!(user_ids = nil)
    return unless private?

    self.private_hash = Conversation.private_hash_for(user_ids ||
      Shard.birth.activate { conversation_participants.reload.map(&:user_id) })
    return unless private_hash_changed?

    existing = shard.activate do
      ConversationParticipant.unscoped do
        ConversationParticipant.where(private_hash:).take&.conversation
      end
    end
    if existing
      merge_into(existing)
    else
      save!
      Shard.with_each_shard(associated_shards) do
        ConversationParticipant.where(conversation_id: self).update_all(private_hash:)
      end
    end
  end

  def self.batch_regenerate_private_hashes!(ids)
    select("conversations.*, (SELECT #{connection.func(:group_concat, :user_id, ",")} FROM #{ConversationParticipant.quoted_table_name} WHERE conversation_id = conversations.id) AS user_ids")
      .where(id: ids)
      .each do |c|
      c.regenerate_private_hash!(c.user_ids.split(",").map(&:to_i)) # group_concat order is arbitrary in sqlite, so we just let ruby do the sorting
    end
  end

  def merge_into(other)
    transaction do
      new_participants = other.conversation_participants.index_by(&:user_id)
      ConversationParticipant.suspend_callbacks(:destroy_conversation_message_participants) do
        conversation_participants.reload.each do |cp|
          if (new_cp = new_participants[cp.user_id])
            if cp.unread? || new_cp.archived?
              ConversationParticipant.where(id: new_cp).update_all(workflow_state: cp.workflow_state)
              new_cp.workflow_state = cp.workflow_state
              new_cp.send(:update_unread_count_for_update)
            end
            # backcompat
            cp.conversation_message_participants.update_all(conversation_participant_id: new_cp.id)
            # remove the duplicate participant
            cp.destroy

            if cp.user.shard != shard
              # remove the duplicate secondary CP on the user's shard
              cp.user.shard.activate do
                ConversationParticipant.where(conversation_id: self, user_id: cp.user_id).delete_all
              end
            end
          else
            # keep the cp, with updated conversation, iff the source
            # conversation shared a shard with the user OR the target
            # conversation
            if shard == other.shard || shard == cp.user.shard
              ConversationParticipant.where(id: cp).update_all(conversation_id: other.id)
            else
              cp.destroy
            end
            # update the duplicate cp on the user's shard if it's a different
            # shard
            if cp.user.shard != shard
              cp.user.shard.activate do
                ConversationParticipant.where(conversation_id: self, user_id: cp.user_id)
                                       .update_all(conversation_id: other.id)
              end
            end
            # create a new duplicate cp on the target conversation's shard
            # if neither the user nor source conversation were there
            # already.
            if shard != other.shard && cp.user.shard != other.shard
              new_cp = cp.clone
              new_cp.shard = other.shard
              new_cp.conversation = other
              new_cp.save!
            end
          end
        end
      end
      if other.shard == shard
        conversation_messages.update_all(conversation_id: other.id)
      else
        # move messages and participants over to new shard
        conversation_messages.find_each do |message|
          new_message = message.clone
          new_message.conversation = other
          message.relativize_attachment_ids(from_shard: shard, to_shard: other.shard)
          new_message.shard = other.shard
          new_message.save!
          message.conversation_message_participants.find_each do |cmp|
            new_cmp = cmp.clone
            new_cmp.conversation_message = new_message
            new_cmp.shard = other.shard
            new_cmp.save!
          end
        end
        shard.activate do
          ConversationMessageParticipant.joins(:conversation_message)
                                        .where(conversation_messages: { conversation_id: id })
                                        .delete_all
          conversation_messages.delete_all
        end
      end

      conversation_participants.reload # now empty ... need to make sure callbacks don't double-delete
      other.conversation_participants.reload.each do |cp|
        cp.update_cached_data! recalculate_count: true, set_last_message_at: false, regenerate_tags: false
      end
      destroy
    end
  end

  def update_root_account_ids
    if root_account_ids_changed?
      # ids must be sorted for the scope to work
      latest_ids = read_attribute(:root_account_ids)
      %w[conversation_participants conversation_messages conversation_message_participants].each do |assoc|
        scope = send(assoc).where("#{assoc}.root_account_ids IS DISTINCT FROM ?", latest_ids).limit(1_000)
        until scope.update_all(root_account_ids: latest_ids) < 1_000; end
      end
    end
  end

  # rails' has_many-:through preloading doesn't preserve :select or :order
  # options, so we roll our own that does (plus we do it in one query so we
  # don't load conversation_participants into memory)
  def self.preload_participants(conversations)
    # start with no participants per conversation
    participants = {}
    conversations.each do |conversation|
      participants[conversation.global_id] = []
    end

    # look up participants across all shards
    shards = conversations.map(&:associated_shards).flatten.uniq
    Shard.with_each_shard(shards) do
      guard_rail_env = (conversations.any? { |c| c.updated_at && c.updated_at > 10.seconds.ago }) ? :primary : :secondary
      user_map = GuardRail.activate(guard_rail_env) do
        User.select("users.id, users.updated_at, users.short_name, users.name, users.avatar_image_url, users.pronouns, users.avatar_image_source, last_authored_at, conversation_id")
            .joins(:all_conversations)
            .where(conversation_participants: { conversation_id: conversations })
            .order(Conversation.nulls(:last, :last_authored_at, :desc), Conversation.best_unicode_collation_key("COALESCE(short_name, name)"))
            .group_by { |u| u.conversation_id.to_i }
      end
      conversations.each do |conversation|
        participants[conversation.global_id].concat(user_map[conversation.id] || [])
      end
    end

    # post-sort and -uniq in Ruby
    if shards.length > 1
      participants.each do |key, value|
        participants[key] = value.uniq(&:id).sort_by do |user|
          [user.last_authored_at ? -user.last_authored_at.to_f : CanvasSort::Last, Canvas::ICU.collation_key(user.short_name || user.name)]
        end
      end
    end

    # set the cached participants
    conversations.each do |conversation|
      conversation.instance_variable_set(:@participants, participants[conversation.global_id])
    end
  end

  # contexts currently shared by > 50% of participants
  # note that these may not all be relevant for a specific participant, so
  # they should be and-ed with User#conversation_context_codes
  # returns best matches first
  def current_context_strings(threshold = nil, preloaded_users_hash = nil)
    @current_context_strings ||= {}
    @current_context_strings[threshold] ||= begin
      participants = conversation_participants.to_a
      if private? && participants.size == 1
        []
      else
        threshold ||= participants.size / 2
        preloaded_users_hash ||= preload_users_and_context_codes

        participants.flat_map { |cp| (cp.user = preloaded_users_hash[cp.user_id])&.conversation_context_codes }
                    .group_by { |code| code }
                    .map { |code, dups| [code, dups.length] }
                    .select { |_code, dups| dups > threshold }
                    .sort_by(&:last)
                    .map(&:first)
                    .reverse
      end
    end
  end

  def associated_shards
    [Shard.default]
  end

  def delete_for_all
    stream_item.try(:destroy_stream_item_instances)
    shard.activate do
      conversation_message_participants.scope.delete_all
    end
    conversation_participants.shard(self).delete_all
  end

  def replies_locked_for?(user, participants_user_ids = [])
    return false unless %w[Course Group].include?(context_type)
    return true if context.nil?

    course = context.is_a?(Course) ? context : context.context

    if course.is_a?(Course)
      return true if course.workflow_state == "completed"

      user_course_roles = course.all_current_enrollments.where(user_id: user.id).pluck(:type)

      has_non_concluded_enrollment = !user_course_roles.empty? && user_course_roles.any? { |ucr| !course.soft_concluded?(ucr) }
      has_non_concluded_section = course.sections_visible_to(user).any? { |vs| !vs.concluded? }
      return true unless has_non_concluded_enrollment || has_non_concluded_section
    end

    # can still reply if a teacher is involved
    if (course.is_a?(Course) && conversation_participants.where(user_id: participants_user_ids).where(user_id: course.admin_enrollments.active.select(:user_id)).exists?) ||
       # can still reply if observing all the other participants
       (course.is_a?(Course) && observing_all_other_participants(user, course))
      false
    else
      !context.grants_any_right?(user, :send_messages, :send_messages_all)
    end
  end

  def observing_all_other_participants(user, course)
    observee_ids = user.observer_enrollments.active.where(course:).pluck(:associated_user_id)
    return false if observee_ids.empty?

    (conversation_participants.pluck(:user_id) - observee_ids - [user.id]).empty?
  end

  protected

  def maybe_update_timestamp(col, val, additional_conditions = [])
    scope = self.class.where(["(#{col} IS NULL OR #{col} < ?)", val]).where(additional_conditions)
    condition = scope.where_clause.send(:predicates).join(" AND ")
    sanitize_sql ["#{col} = CASE WHEN #{condition} THEN ? ELSE #{col} END", val]
  end
end
