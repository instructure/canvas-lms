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

require 'open_object'
require 'set'

class StreamItem < ActiveRecord::Base
  serialize :data

  has_many :stream_item_instances
  has_many :users, :through => :stream_item_instances
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account', 'Group', 'AssignmentOverride', 'Assignment']
  belongs_to :asset, :polymorphic => true, :types => [
      :collaboration, :conversation, :discussion_entry,
      :discussion_topic, :message, :submission, :web_conference, :assessment_request]
  validates_inclusion_of :asset_type, :allow_nil => true, :in => ['Collaboration', 'Conversation', 'DiscussionEntry',
      'DiscussionTopic', 'Message', 'Submission', 'WebConference', 'AssessmentRequest']
  validates_presence_of :asset_type, :data

  attr_accessible :context, :asset
  after_destroy :destroy_stream_item_instances
  attr_accessor :unread, :participant

  def self.reconstitute_ar_object(type, data)
    return nil unless data
    data = data.instance_variable_get(:@table) if data.is_a?(OpenObject)
    data = data.with_indifferent_access
    type = data['type'] || type
    res = type.constantize.new

    case type
    when 'DiscussionTopic', 'Announcement'
      root_discussion_entries = data.delete(:root_discussion_entries)
      root_discussion_entries = root_discussion_entries.map { |entry| reconstitute_ar_object('DiscussionEntry', entry) }
      res.association(:root_discussion_entries).target = root_discussion_entries
      res.attachment = reconstitute_ar_object('Attachment', data.delete(:attachment))
    when 'Submission'
      data['body'] = nil
    end
    if data.has_key?('users')
      users = data.delete('users')
      users = users.map { |user| reconstitute_ar_object('User', user) }
      res.association(:users).target = users
    end
    if data.has_key?('participants')
      users = data.delete('participants')
      users = users.map { |user| reconstitute_ar_object('User', user) }
      res.instance_variable_set(:@participants, users)
    end

    res.instance_variable_set(:@attributes, data)
    res.instance_variable_set(:@new_record, false) if data['id']
    res
  end

  def data(viewing_user_id = nil)
    # reconstitute AR objects
    @ar_data ||= self.shard.activate do
      self.class.reconstitute_ar_object(asset_type, read_attribute(:data))
    end
    res = @ar_data

    if viewing_user_id
      res.user_id ||= viewing_user_id if asset_type != 'DiscussionTopic' && res.respond_to?(:user_id)
      post_process(res, viewing_user_id)
    else
      res
    end
  end

  def prepare_user(user)
    res = user.attributes.slice('id', 'name', 'short_name')
    res['short_name'] ||= res['name']
    res
  end

  def prepare_conversation(conversation)
    res = conversation.attributes.slice('id', 'has_attachments')
    res['private'] = conversation.private?
    res['participant_count'] = conversation.conversation_participants.size
    # arbitrary limit. would be nice to say "John, Jane, Michael, and 6
    # others." if there's too many recipients, where those listed are the N
    # most active posters in the conversation, but we'll just leave it at "9
    # Participants" for now when the count is > 8.
    if res['participant_count'] <= 8
      res['participants'] = conversation.participants.map{ |u| prepare_user(u) }
    end
    res
  end

  def regenerate!(obj=nil)
    obj ||= asset
    return nil if self.asset_type == 'Message' && self.asset_id.nil?
    if !obj || (obj.respond_to?(:workflow_state) && obj.workflow_state == 'deleted')
      self.destroy
      return nil
    end
    res = generate_data(obj)
    self.save
    res
  end

  def self.delete_all_for(root_asset, asset)
    item = StreamItem.where(:asset_type => root_asset.first, :asset_id => root_asset.last).first
    # if this is a sub-message, regenerate instead of deleting
    if root_asset != asset
      item.try(:regenerate!)
      return
    end
    # Can't use delete_all here, since we need the destroy to fire and delete
    # the StreamItemInstances as well.
    item.try(:destroy)
  end

  ROOT_DISCUSSION_ENTRY_LIMIT = 3
  def generate_data(object)
    self.context ||= object.context rescue nil

    case object
    when DiscussionTopic
      res = object.attributes
      res['user_ids_that_can_see_responses'] = object.user_ids_who_have_posted_and_admins if object.require_initial_post?
      res['total_root_discussion_entries'] = object.root_discussion_entries.active.count
      res[:root_discussion_entries] = object.root_discussion_entries.active.reverse[0,ROOT_DISCUSSION_ENTRY_LIMIT].reverse.map do |entry|
        hash = entry.attributes
        hash['user_short_name'] = entry.user.short_name if entry.user
        hash['message'] = hash['message'][0, 4.kilobytes] if hash['message'].present?
        hash
      end
      if object.attachment
        hash = object.attachment.attributes.slice('id', 'display_name')
        res[:attachment] = hash
      end
    when Conversation
      res = prepare_conversation(object)
    when Message
      res = object.attributes
      res['notification_category'] = object.notification_display_category
      if !object.context.is_a?(Context) && object.context.respond_to?(:context) && object.context.context.is_a?(Context)
        self.context = object.context.context
      elsif object.asset_context_type
        self.context_type, self.context_id = object.asset_context_type, object.asset_context_id
      end
    when Submission
      res = object.attributes
      res.delete 'body' # this can be pretty large, and we don't display it
      res['assignment'] = object.assignment.attributes.slice('id', 'title', 'due_at', 'points_possible', 'submission_types', 'group_category_id')
      res[:course_id] = object.context.id
    when Collaboration
      res = object.attributes
      res['users'] = object.users.map{|u| prepare_user(u)}
    when WebConference
      res = object.attributes
      res['users'] = object.users.map{|u| prepare_user(u)}
    when AssessmentRequest
      res = object.attributes
    else
      raise "Unexpected stream item type: #{object.class.to_s}"
    end
    if self.context_type
      res['context_short_name'] = Rails.cache.fetch(['short_name_lookup', self.context_type, self.context_id].cache_key) do
        self.context.short_name rescue ''
      end
    end
    res['type'] = object.class.to_s
    res['user_short_name'] = object.user.short_name rescue nil

    if self.class.new_message?(object)
      self.asset_type = 'Message'
      self.asset_id = nil
    else
      self.asset = object
    end
    self.data = res
  end

  def self.generate_or_update(object)
    item = nil
    StreamItem.unique_constraint_retry do
      # we can't coalesce messages that weren't ever saved to the DB
      if !new_message?(object)
        item = object.stream_item
      end
      if item
        item.regenerate!(object)
      else
        item = self.new
        item.generate_data(object)
        item.save!
        # prepopulate the reverse association
        # (mostly useful for specs that regenerate stream items
        #  multiple times without reloading the asset)
        if !new_message?(object)
          object.stream_item = item
        end
      end
    end
    item
  end

  def self.generate_all(object, user_ids)
    user_ids ||= []
    user_ids.uniq!
    return [] if user_ids.empty?

    # Make the StreamItem
    object = root_object(object)
    res = StreamItem.generate_or_update(object)
    prepare_object_for_unread(object)

    # set the hidden flag if an assignment and muted
    hidden = object.is_a?(Submission) && object.assignment.muted? ? true : false


    l_context_type = res.context_type
    Shard.partition_by_shard(user_ids) do |user_ids_subset|
      #these need to be determined per shard
      #hence the local caching inside the partition block
      l_context_id = res.context_id
      stream_item_id = res.id

      # do the bulk insert in user id order to avoid locking problems on postges < 9.3 (foreign keys)
      user_ids_subset.sort!
      #find out what the current largest stream item instance is so that we can delete them all once the new ones are created
      greatest_existing_id = StreamItemInstance.where(:stream_item_id => stream_item_id, :user_id => user_ids_subset).maximum(:id) || 0

      inserts = user_ids_subset.map do |user_id|
        {
          :stream_item_id => stream_item_id,
          :user_id => user_id,
          :hidden => hidden,
          :workflow_state => object_unread_for_user(object, user_id),
          :context_type => l_context_type,
          :context_id => l_context_id,
        }
      end

      StreamItemInstance.bulk_insert(inserts)

      #reset caches manually because the observer wont trigger off of the above mass inserts
      user_ids_subset.each do |user_id|
        StreamItemCache.invalidate_recent_stream_items(user_id, l_context_type, l_context_id)
      end

      # Then delete any old instances from these users' streams.
      # This won't actually delete StreamItems out of the table, it just deletes
      # the join table entries.
      # Old stream items are deleted in a periodic job.
      StreamItemInstance.where("user_id in (?) AND stream_item_id = ? AND id <= ?",
            user_ids_subset, stream_item_id, greatest_existing_id).delete_all

      # touch all the users to invalidate the cache
      User.transaction do
        lock_type = true
        lock_type = 'FOR NO KEY UPDATE' if User.connection.adapter_name == 'PostgreSQL' && User.connection.send(:postgresql_version) >= 90300
        # lock the rows in a predefined order to prevent deadlocks
        User.where(id: user_ids).lock(lock_type).order(:id).pluck(:id)
        User.where(id: user_ids).update_all(updated_at: Time.now.utc)
      end
    end

    return [res]
  end

  def self.root_object(object)
    case object
    when DiscussionEntry
      object.discussion_topic
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
      when DiscussionTopic
        ActiveRecord::Associations::Preloader.new(object, :discussion_topic_participants).run
    end
  end

  def self.object_unread_for_user(object, user_id)
    case object
    when DiscussionTopic
      object.read_state(user_id)
    else
      nil
    end
  end

  def self.update_read_state_for_asset(asset, new_state, user_id)
    if item = asset.stream_item
      StreamItemInstance.where(user_id: user_id, stream_item_id: item).first.try(:update_attribute, :workflow_state, new_state)
    end
  end

  # call destroy_stream_items using a before_date based on the global setting
  def self.destroy_stream_items_using_setting
    ttl = Setting.get('stream_items_ttl', 4.weeks).to_i.ago
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

    scope = where("updated_at<?", before_date).
        includes(:context).
        limit(1000)
    scope = scope.includes(:stream_item_instances) if touch_users

    while true
      batch = scope.reload.all
      batch.each do |item|
        count += 1
        if touch_users
          user_ids.add(item.stream_item_instances.map(&:user_id))
        end
        # this will destroy the associated stream_item_instances as well
        item.destroy
      end
      break if batch.empty?
    end

    unless user_ids.empty?
      # touch all the users to invalidate the cache
      User.where(:id => user_ids.to_a).update_all(:updated_at => Time.now.utc)
    end

    count
  end

  scope :before, lambda { |id| where("id<?", id).order("updated_at DESC").limit(21) }
  scope :after, lambda { |start_at| where("updated_at>?", start_at).order("updated_at DESC").limit(21) }

  def associated_shards
    if self.context.try(:respond_to?, :associated_shards)
      self.context.associated_shards
    elsif self.data.respond_to?(:associated_shards)
      self.data.associated_shards
    else
      [self.shard]
    end
  end

  private

  def self.new_message?(object)
    object.is_a?(Message) && object.new_record?
  end

  # Internal: Format the stream item's asset to avoid showing hidden data.
  #
  # res - The stream item asset.
  # viewing_user_id - The ID of the user to prepare the stream item for.
  #
  # Returns the stream item asset minus any hidden data.
  def post_process(res, viewing_user_id)
    case res
    when DiscussionTopic, Announcement
      if res.require_initial_post
        res.user_has_posted = true
        if res.user_ids_that_can_see_responses && !res.user_ids_that_can_see_responses.member?(viewing_user_id)
          original_res = res
          res = original_res.clone
          res.id = original_res.id
          res.association(:root_discussion_entries).target = []
          res.user_has_posted = false
          res.readonly!
        end
      end
    end

    res
  end

  public
  def destroy_stream_item_instances
    self.stream_item_instances.with_each_shard do |scope|
      scope.delete_all
      nil
    end
  end
end
