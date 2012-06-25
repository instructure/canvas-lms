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

  has_many :stream_item_instances, :dependent => :delete_all
  has_many :users, :through => :stream_item_instances

  attr_accessible
  
  def stream_data(viewing_user_id)
    res = data.is_a?(OpenObject) ? data : OpenObject.new
    res.assert_hash_data
    res.user_id ||= viewing_user_id unless res.type == 'DiscussionTopic'
    post_process(res, viewing_user_id)
  end
  
  def prepare_user(user)
    res = user.attributes.slice('id', 'name', 'short_name')
    res['short_name'] ||= res['name']
    res
  end

  def prepare_conversation(conversation)
    res = conversation.attributes.slice('id', 'has_attachments')
    res['private'] = conversation.private?
    res['participant_count'] = conversation.participants.size
    # arbitrary limit. would be nice to say "John, Jane, Michael, and 6
    # others." if there's too many recipients, where those listed are the N
    # most active posters in the conversation, but we'll just leave it at "9
    # Participants" for now when the count is > 8.
    if res['participant_count'] <= 8
      res['participants'] = conversation.participants.map{ |u| prepare_user(u) }
    end
    res
  end
  
  def asset
    @obj ||= ActiveRecord::Base.find_by_asset_string(self.item_asset_string, StreamItem.valid_asset_types)
  end
  
  def regenerate!(obj=nil)
    obj ||= asset
    return nil if self.item_asset_string == 'message_'
    if !obj || (obj.respond_to?(:workflow_state) && obj.workflow_state == 'deleted')
      self.destroy
      return nil
    end
    res = generate_data(obj)
    self.save
    res
  end
  
  def self.delete_all_for(asset, original_asset_string=nil)
    root_asset = nil
    root_asset = root_object(asset)
    
    root_asset_string = root_asset && root_asset.asset_string
    root_asset_string ||= asset.asset_string if asset.respond_to?(:asset_string)
    root_asset_string ||= asset if asset.is_a?(String)
    original_asset_string ||= root_asset_string
    
    return if root_asset_string == 'message_'
    # if this is a sub-message, regenerate instead of deleting
    if root_asset && root_asset.asset_string != original_asset_string
      items = StreamItem.for_item_asset_string(root_asset_string)
      items.each{|i| i.regenerate!(root_asset) }
      return
    end
    
    # Can't use delete_all here, since we need the destroy to fire and delete
    # the StreamItemInstances as well.
    StreamItem.find(:all, :conditions => {:item_asset_string => root_asset_string}).each(&:destroy) if root_asset_string
  end
  
  def self.valid_asset_types
    [
      :assignment, :submission, :submission_comment, :conversation,
      :discussion_topic, :discussion_entry, :message, :collaboration,
      :web_conference
    ]
  end
  
  def self.root_object(object)
    if object.is_a?(String)
      object = ActiveRecord::Base.find_by_asset_string(object, valid_asset_types) rescue nil
      object ||= ActiveRecord::Base.initialize_by_asset_string(object, valid_asset_types) rescue nil
    end
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

  def generate_data(object)
    res = {}

    self.context_code ||= object.context_code rescue nil
    self.context_code ||= object.context.asset_string rescue nil

    case object
    when DiscussionTopic
      object = object
      res = object.attributes
      res['user_ids_that_can_see_responses'] = object.user_ids_who_have_posted_and_admins if object.require_initial_post?
      res['total_root_discussion_entries'] = object.root_discussion_entries.active.count
      res[:root_discussion_entries] = object.root_discussion_entries.active.reverse[0,10].reverse.map do |entry|
        hash = entry.attributes
        hash['user_short_name'] = entry.user.short_name if entry.user
        hash['truncated_message'] = entry.truncated_message(250)
        hash['message'] = hash['message'][0, 4.kilobytes] if hash['message'].present?
        hash
      end
      if object.attachment
        hash = object.attachment.attributes.slice('id', 'display_name')
        hash['scribdable?'] = object.attachment.scribdable?
        res[:attachment] = hash
      end
    when Conversation
      res = prepare_conversation(object)
    when Message
      res = object.attributes
      res['notification_category'] = object.notification_display_category
      if !object.context.is_a?(Context) && object.context.respond_to?(:context) && object.context.context.is_a?(Context)
        self.context_code = object.context.context.asset_string
      elsif object.asset_context_type
        self.context_code = "#{object.asset_context_type.underscore}_#{object.asset_context_id}"
      end
    when Submission
      res = object.attributes
      res.delete 'body' # this can be pretty large, and we don't display it
      res['assignment'] = object.assignment.attributes.slice('id', 'title', 'due_at', 'points_possible', 'submission_types', 'group_category_id')
      res[:submission_comments] = object.submission_comments.map do |comment|
        hash = comment.attributes
        hash['formatted_body'] = comment.formatted_body(250)
        hash['context_code'] = comment.context_code
        hash['user_short_name'] = comment.author.short_name if comment.author
        hash
      end
    when Collaboration
      res = object.attributes
      res['users'] = object.users.map{|u| prepare_user(u)}
    when WebConference
      res = object.attributes
      res['users'] = object.users.map{|u| prepare_user(u)}
    when CollectionItem
      res = object.attributes
    else
      raise "Unexpected stream item type: #{object.class.to_s}"
    end
    code = self.context_code
    if code
      res['context_short_name'] = Rails.cache.fetch(['short_name_lookup', code].cache_key) do
        Context.find_by_asset_string(code).short_name rescue ""
      end
    end
    res['type'] = object.class.to_s
    res['user_short_name'] = object.user.short_name rescue nil
    res['context_code'] = self.context_code
    res = OpenObject.process(res)

    self.item_asset_string = object.asset_string
    self.data = res
  end

  def self.generate_or_update(object)
    item = nil
    # we can't coalesce messages that weren't ever saved to the DB
    unless object.asset_string == 'message_'
      item = StreamItem.find_by_item_asset_string(object.asset_string)
    end
    if item
      item.regenerate!(object)
    else
      item = self.new
      item.generate_data(object)
      item.save
    end
    item
  end

  def self.generate_all(object, user_ids)
    user_ids ||= []
    user_ids.uniq!
    return [] if user_ids.empty?

    # Make the StreamItem
    object = get_parent_for_stream(object)
    res = StreamItem.generate_or_update(object)

    # set the hidden flag if an assignment and muted
    hidden = object.is_a?(Submission) && object.assignment.muted? ? true : false

    # Then insert a StreamItemInstance for each user in user_ids
    instance_ids = []
    Shard.partition_by_shard(user_ids) do |user_ids_subset|
      StreamItemInstance.transaction do
        user_ids_subset.each do |user_id|
          i = StreamItemInstance.create(:user_id => user_id, :stream_item => res) do |sii|
            sii.hidden = object.class == Submission && object.assignment.muted? ? true : false
          end
          instance_ids << i.id
        end
      end
    end
    smallest_generated_id = instance_ids.min || 0

    # Then delete any old instances from these users' streams.
    # This won't actually delete StreamItems out of the table, it just deletes
    # the join table entries.
    # Old stream items are deleted in a periodic job.
    StreamItemInstance.delete_all(
          ["user_id in (?) AND stream_item_id = ? AND id < ?",
          user_ids, res.id, smallest_generated_id])

    # Here is where we used to go through and update the stream item for anybody
    # not in user_ids who had the item in their stream, so that the item would
    # be up-to-date, but not jump to the top of their stream. Now that
    # we're updating StreamItems in-place and just linking to them through
    # StreamItemInstances, this happens automatically.
    # If a teacher leaves a comment for a student, for example
    # we don't want that to jump to the top of the *teacher's* stream, but
    # if it's still visible on the teacher's stream then it had better show
    # the teacher's comment even if it is farther down.

    # touch all the users to invalidate the cache
    User.update_all({:updated_at => Time.now.utc}, {:id => user_ids})

    return [res]
  end

  def self.get_parent_for_stream(object)
    object = object.discussion_topic if object.is_a?(DiscussionEntry)
    object = object.submission if object.is_a?(SubmissionComment)
    object = object.conversation if object.is_a?(ConversationMessage)
    object
  end

  # call destroy_stream_items using a before_date based on the global setting
  def self.destroy_stream_items_using_setting
    ttl = Setting.get('stream_items_ttl', 4.weeks.to_s).ago
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

    query = { :conditions => ['updated_at < ?', before_date] }
    if touch_users
      query[:include] = 'stream_item_instances'
    end

    self.find_each(query) do |item|
      count += 1
      if touch_users
        user_ids.add(item.stream_item_instances.map { |i| i.user_id })
      end
      # this will destroy the associated stream_item_instances as well
      item.destroy
    end

    unless user_ids.empty?
      # touch all the users to invalidate the cache
      User.update_all({:updated_at => Time.now.utc}, {:id => user_ids.to_a})
    end

    count
  end

  named_scope :for_user, lambda {|user|
    {:conditions => ['stream_item_instances.user_id = ?', user.id],
      :include => :stream_item_instances }
  }
  named_scope :for_context_codes, lambda {|codes|
    {:conditions => {:context_code => codes} }
  }
  named_scope :for_item_asset_string, lambda{|string|
    {:conditions => {:item_asset_string => string} }
  }
  named_scope :before, lambda {|id|
    {:conditions => ['id < ?', id], :order => 'updated_at DESC', :limit => 21 }
  }
  named_scope :after, lambda {|start_at| 
    {:conditions => ['updated_at > ?', start_at], :order => 'updated_at DESC', :limit => 21 }
  }
  
  private
  
  def post_process(res, viewing_user_id)
    case res.type
    when 'DiscussionTopic','Announcement'
      if res.require_initial_post
        res.user_has_posted = true
        if res.user_ids_that_can_see_responses && !res.user_ids_that_can_see_responses.member?(viewing_user_id) 
          res.root_discussion_entries = []
          res.user_has_posted = false
        end
      end
    end
    
    res
  end
end
