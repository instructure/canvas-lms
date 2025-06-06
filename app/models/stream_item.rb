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

class StreamItem < ActiveRecord::Base
  serialize :data

  has_many :stream_item_instances
  has_many :users, through: :stream_item_instances
  belongs_to :context, polymorphic: %i[course account group assignment_override assignment]
  belongs_to :asset, polymorphic: %i[
    collaboration
    conversation
    discussion_entry
    discussion_topic
    message
    submission
    web_conference
    assessment_request
  ]
  validates :asset_type, :data, presence: true

  after_destroy :destroy_stream_item_instances
  attr_accessor :unread, :participant, :invalidate_immediately

  before_save :ensure_notification_category

  def ensure_notification_category
    if asset_type == "Message"
      self.notification_category ||= get_notification_category
    end
  end

  def get_notification_category
    self["data"]["notification_category"] || data.notification_category
  end

  def self.reconstitute_ar_object(type, data)
    return nil unless data

    data = data.with_indifferent_access
    type = data["type"] || type
    res = type.constantize.new

    case type
    when "Announcement", "DiscussionTopic"
      root_discussion_entries = data.delete(:root_discussion_entries) || []
      root_discussion_entries = root_discussion_entries.map { |entry| reconstitute_ar_object("DiscussionEntry", entry) }
      res.association(:root_discussion_entries).target = root_discussion_entries
      res.attachment = reconstitute_ar_object("Attachment", data.delete(:attachment))
      res.total_root_discussion_entries = data.delete(:total_root_discussion_entries)
    when "Conversation"
      res.latest_messages_from_stream_item = data.delete(:latest_messages)
    when "Submission"
      data["body"] = nil
    end
    if data.key?("users")
      users = data.delete("users")
      users = users.map { |user| reconstitute_ar_object("User", user) }
      res.association(:users).target = users
    end
    if data.key?("participants")
      users = data.delete("participants")
      users = users.map { |user| reconstitute_ar_object("User", user) }
      res.instance_variable_set(:@participants, users)
    end

    # unnecessary after old stream items have expired
    if res.is_a?(Conversation) && !data.key?("updated_at")
      data["updated_at"] = Time.now.utc
    end

    data = res.class.attributes_builder.build_from_database(data) # @attributes is now an AttributeSet

    res.instance_variable_set(:@attributes, data)
    res.instance_variable_set(:@attributes_cache, {})
    res.instance_variable_set(:@new_record, false) if data["id"]

    # the after_find from NotificationPreloader won't get triggered
    if res.respond_to?(:preload_notification) && res["notification_id"]
      res.preload_notification
    end

    res
  end

  def data(viewing_user_id = nil)
    # reconstitute AR objects
    @ar_data ||= shard.activate do
      self.class.reconstitute_ar_object(asset_type, super())
    end
    res = @ar_data

    if viewing_user_id
      res.user_id ||= viewing_user_id if asset_type != "DiscussionTopic" && res.respond_to?(:user_id)
      post_process(res, viewing_user_id)
    else
      res
    end
  end

  def prepare_user(user)
    res = user.attributes.slice("id", "name", "short_name")
    res["short_name"] ||= res["name"]
    res
  end

  def prepare_conversation(conversation)
    res = conversation.attributes.slice("id", "has_attachments", "updated_at")
    res["title"] = conversation.subject
    res["private"] = conversation.private?
    res["participant_count"] = conversation.conversation_participants.size
    # arbitrary limit. would be nice to say "John, Jane, Michael, and 6
    # others." if there's too many recipients, where those listed are the N
    # most active posters in the conversation, but we'll just leave it at "9
    # Participants" for now when the count is > 8.
    if res["participant_count"] <= 8
      res["participants"] = conversation.participants.map { |u| prepare_user(u) }
    end

    messages = conversation.conversation_messages.human.order(created_at: :desc).limit(LATEST_ENTRY_LIMIT).to_a.reverse
    res["latest_messages"] = messages.map do |message|
      {
        "id" => message.id,
        "created_at" => message.created_at,
        "author_id" => message.author_id,
        "message" => message.body.present? ? message.body[0, 4.kilobytes] : "",
        "participating_user_ids" => message.conversation_message_participants.active.pluck(:user_id).sort
      }
    end

    res
  end

  def regenerate!(obj = nil)
    obj ||= asset
    return nil if asset_type == "Message" && asset_id.nil?

    if !obj || (obj.respond_to?(:workflow_state) && obj.workflow_state == "deleted")
      destroy
      return nil
    end
    res = generate_data(obj)
    save
    res
  end

  def self.delete_all_for(root_asset, asset)
    item = StreamItem.where(asset_type: root_asset.first, asset_id: root_asset.last).first
    # if this is a sub-message, regenerate instead of deleting
    if root_asset != asset
      item.try(:regenerate!)
      return
    end
    # Can't use delete_all here, since we need the destroy to fire and delete
    # the StreamItemInstances as well.
    item.try(:destroy)
  end

  LATEST_ENTRY_LIMIT = 3

  def generate_data(object)
    self.context ||= object.try(:context) unless object.is_a?(Message)

    case object
    when DiscussionEntry
      res = object.attributes
      res["user_ids_that_can_see_responses"] = object.discussion_topic.user_ids_who_have_posted_and_admins if object.discussion_topic.require_initial_post?
      res["title"] = object.discussion_topic.title
      res["message"] = object["message"][0, 4.kilobytes] if object["message"].present?
      res["user_short_name"] = object.user.short_name if object.user
    when DiscussionTopic
      res = object.attributes
      res["user_ids_that_can_see_responses"] = object.user_ids_who_have_posted_and_admins if object.require_initial_post?
      res["total_root_discussion_entries"] = object.root_discussion_entries.active.count
      res[:root_discussion_entries] = object.root_discussion_entries.active.order(created_at: :desc).limit(LATEST_ENTRY_LIMIT).to_a.reverse.map do |entry|
        hash = entry.attributes
        hash["user_short_name"] = entry.user.short_name if entry.user
        hash["message"] = hash["message"][0, 4.kilobytes] if hash["message"].present?
        hash
      end
      if object.attachment
        res[:attachment] = object.attachment.attributes.slice("id", "display_name")
      end
    when Conversation
      res = prepare_conversation(object)
    when Message
      res = object.attributes
      res["notification_category"] = object.notification_display_category
      if !object.context.is_a?(Context) && object.context_context
        self.context = object.context_context
      end
    when Submission
      res = object.attributes
      res.delete "body" # this can be pretty large, and we don't display it
      res["assignment"] = object.assignment.attributes.slice("id", "title", "due_at", "points_possible", "submission_types", "group_category_id")
      res[:course_id] = object.context.id
    when Collaboration, WebConference
      res = object.attributes
      res["users"] = object.users.map { |u| prepare_user(u) }
    when AssessmentRequest
      res = object.attributes
    else
      raise "Unexpected stream item type: #{object.class}"
    end
    if context_type
      res["context_short_name"] = Rails.cache.fetch(["short_name_lookup", "#{context_type.underscore}_#{context_id}"].cache_key) do
        self.context.try(:short_name) || ""
      end
    end
    res["type"] = object.class.to_s
    res["user_short_name"] = object.try(:user)&.short_name

    if self.class.new_message?(object)
      self.asset_type = "Message"
      self.asset_id = nil
    else
      self.asset = object
    end
    self.data = res
  end

  def self.generate_or_update(object)
    # we can't coalesce messages that weren't ever saved to the DB
    unless new_message?(object)
      item = object.stream_item
      # prepopulate the reverse association
      object.stream_item = item
      item&.regenerate!(object)
      return item if item
    end

    item = new
    item.generate_data(object)
    item.insert(on_conflict: -> { item = object.reload.stream_item })

    # prepopulate the reverse association
    # (mostly useful for specs that regenerate stream items
    #  multiple times without reloading the asset)
    object.stream_item = item unless new_message?(object)

    item
  end

  def self.generate_all(object, user_ids)
    user_ids ||= []
    user_ids.uniq!
    return [] if user_ids.empty?

    # Make the StreamItem
    object = root_object(object)
    res = StreamItem.generate_or_update(object)
    return [] if res.nil?

    prepare_object_for_unread(object)

    l_context_type = res.context_type
    Shard.partition_by_shard(user_ids) do |user_ids_subset|
      # these need to be determined per shard
      # hence the local caching inside the partition block
      l_context_id = res.context_id
      stream_item_id = res.id

      # do the bulk insert in user id order to avoid locking problems on postges < 9.3 (foreign keys)
      user_ids_subset.sort!

      user_ids_subset.each_slice(500) do |sliced_user_ids|
        inserts = sliced_user_ids.map do |user_id|
          {
            stream_item_id:,
            user_id:,
            hidden: false,
            workflow_state: object_unread_for_user(object, user_id),
            context_type: l_context_type,
            context_id: l_context_id,
          }
        end
        # set the hidden flag if this submission is not posted
        if object.is_a?(Submission) && (!object.posted? || object.assignment.suppress_assignment?) && (owner_insert = inserts.detect { |i| i[:user_id] == object.user_id })
          owner_insert[:hidden] = true
        end

        StreamItemInstance.where(stream_item_id:, user_id: sliced_user_ids).delete_all
        StreamItemInstance.insert_all(inserts)

        # reset caches manually because the observer wont trigger off of the above mass inserts
        sliced_user_ids.each do |user_id|
          StreamItemCache.invalidate_recent_stream_items(user_id, l_context_type, l_context_id)
        end

        # touch all the users to invalidate the cache
        User.where(id: sliced_user_ids).touch_all_skip_locked
      end
    end

    [res]
  end

  def self.root_object(object)
    case object
    when DiscussionEntry
      object.discussion_topic
    when Mention
      object.discussion_entry
    when SubmissionComment
      object.submission
    when ConversationMessage
      object.conversation
    else
      object
    end
  end

  def self.prepare_object_for_unread(object)
    case object
    when DiscussionEntry
      ActiveRecord::Associations.preload(object, :discussion_entry_participants)
    when DiscussionTopic
      ActiveRecord::Associations.preload(object, :discussion_topic_participants)
    end
  end

  def self.object_unread_for_user(object, user_id)
    case object
    when DiscussionEntry, DiscussionTopic, Submission
      object.read_state(user_id)
    else
      nil
    end
  end

  def self.update_read_state_for_asset(asset, new_state, user_id)
    if (item = asset.stream_item)
      Shard.shard_for(user_id).activate do
        StreamItemInstance.where(user_id:, stream_item_id: item).first&.update_attribute(:workflow_state, new_state)
      end
    end
  end

  # call destroy_stream_items using a before_date based on the global setting
  def self.destroy_stream_items_using_setting
    ttl = Setting.get("stream_items_ttl", 4.weeks).to_i.seconds.ago
    # we pass false for the touch_users argument, on the assumption that these
    # stream items that we delete aren't visible on the user's dashboard anymore
    # anyway, so there's no need to invalidate all the caches.
    destroy_stream_items(ttl, false)
  end

  # delete old stream items and the corresponding instances before a given date
  # returns the number of destroyed stream items
  def self.destroy_stream_items(before_date, touch_users = true)
    user_ids = Set.new
    count = 0

    scope = where("updated_at<?", before_date)
            .preload(:context)
            .limit(1000)
    scope = scope.preload(:stream_item_instances) if touch_users

    while true
      batch = scope.reload.to_a
      batch.each do |item|
        count += 1
        if touch_users
          user_ids.add(item.stream_item_instances.map(&:user_id))
        end

        # this will destroy the associated stream_item_instances as well
        item.invalidate_immediately = true
        item.destroy
      end
      break if batch.empty?
    end

    unless user_ids.empty?
      # touch all the users to invalidate the cache
      User.where(id: user_ids.to_a).touch_all
    end

    GuardRail.activate(:deploy) do
      Shard.current.database_server.unguard do
        StreamItem.vacuum
        StreamItemInstance.vacuum
        unless Rails.env.test?
          ActiveRecord::Base.connection_pool.disconnect!
        end
      end
    end

    count
  end

  scope :before, ->(id) { where("id<?", id).order("updated_at DESC").limit(21) }
  scope :after, ->(start_at) { where("updated_at>?", start_at).order("updated_at DESC").limit(21) }

  def associated_shards
    if self.context.try(:respond_to?, :associated_shards)
      self.context.associated_shards
    elsif data.respond_to?(:associated_shards)
      data.associated_shards
    else
      [shard]
    end
  end

  def self.new_message?(object)
    object.is_a?(Message) && object.new_record?
  end

  private

  # Internal: Format the stream item's asset to avoid showing hidden data.
  #
  # res - The stream item asset.
  # viewing_user_id - The ID of the user to prepare the stream item for.
  #
  # Returns the stream item asset minus any hidden data.
  def post_process(res, viewing_user_id)
    case res
    when Announcement, DiscussionTopic
      if res.require_initial_post
        res.user_has_posted = true
        if res.user_ids_that_can_see_responses && !res.user_ids_that_can_see_responses.member?(viewing_user_id)
          original_res = res
          res = original_res.clone
          res.id = original_res.id
          res.association(:root_discussion_entries).target = []
          res.user_has_posted = false
          res.total_root_discussion_entries = original_res.total_root_discussion_entries
          res.readonly!
        end
      end
    when DiscussionEntry
      if res.discussion_topic.require_initial_post
        res.discussion_topic.user_has_posted = true
        if res.user_ids_that_can_see_responses && !res.user_ids_that_can_see_responses.member?(viewing_user_id)
          original_res = res
          res = original_res.clone
          res.id = original_res.id
          res.message = ""
          res.readonly!
        end
      end
    when Conversation
      res.latest_messages_from_stream_item&.select! { |m| m["participating_user_ids"].include?(viewing_user_id) }
    end

    res
  end

  public

  def destroy_stream_item_instances
    stream_item_instances.preload(:context).shard(self).activate do |scope|
      user_ids = scope.pluck(:user_id)
      if !invalidate_immediately && user_ids.count > 100
        StreamItemCache.delay_if_production(priority: Delayed::LOW_PRIORITY)
                       .invalidate_all_recent_stream_items(user_ids, context_type, context_id)
      else
        StreamItemCache.invalidate_all_recent_stream_items(user_ids, context_type, context_id)
      end
      scope.in_batches(of: 10_000).delete_all
      nil
    end
  end
end
