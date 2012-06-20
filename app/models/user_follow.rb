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

class UserFollow < ActiveRecord::Base
  VALID_FOLLOWED_ITEM_TYPES = [:user, :collection, :group]

  attr_accessible :following_user, :followed_item

  belongs_to :following_user, :class_name => "User"
  belongs_to :followed_item, :polymorphic => true, :types => VALID_FOLLOWED_ITEM_TYPES

  validates_presence_of :following_user, :followed_item

  # Using this method to create a new UserFollow is preferable to creating it
  # directly, since it handles if the unique constraint fails because the
  # record is being created twice in parallel.
  #
  # normally just leave complementary_record as false, that's used internally
  # while creating the complementary record on the other shard.
  def self.create_follow(following_user, followed_item, complementary_record = false)
    search_shard = (complementary_record ? followed_item : following_user).shard
    UserFollow.unique_constraint_retry do
      user_follow = search_shard.activate { UserFollow.first(:conditions => { :following_user_id => following_user.id, :followed_item_id => followed_item.id, :followed_item_type => followed_item.class.name }) }
      user_follow ||= UserFollow.create(:following_user => following_user, :followed_item => followed_item) { |uf| uf.complementary_record = complementary_record }
    end
  end

  validate_on_create :validate_following_logic

  def validate_following_logic
    case followed_item
    when User
      if followed_item == following_user
        errors.add(:followed_item, t("errors.follow_self", "You cannot follow yourself"))
        return false
      end
    when Collection
      if followed_item.context == following_user
        errors.add(:followed_item, t("errors.follow_own_collection", "You cannot follow your own collection"))
        return false
      end
    when Group
      # always ok
    else
      raise("unknown followed_item type: #{followed_item.inspect}")
    end
    return true
  end

  # we force the record to be created on the same shard as the following_user
  # then the after_create below creates a duplicate, complementary record on
  # the shard of the followed_item, if it's on a different shard
  #
  # this way both associations work as expected
  set_shard_override do |record|
    record.following_user.shard unless record.complementary_record?
  end

  after_create :create_complementary_record
  attr_writer :complementary_record

  # returns true if the following user isn't on the same shard as the followed
  # item, and this UserFollow is the secondary copy that's on the followed
  # item's shard
  def complementary_record?
    if new_record?
      @complementary_record
    else
      self.shard != following_user.shard
    end
  end

  def create_complementary_record
    if !complementary_record? && followed_item.shard != following_user.shard
      followed_item.shard.activate do
        UserFollow.create_follow(following_user, followed_item, true)
      end
    end
    true
  end

  after_destroy :destroy_complementary_record
  def destroy_complementary_record
    find_complementary_record.try(:destroy)
  end

  def find_complementary_record
    return nil if followed_item.shard == following_user.shard
    if self.shard == followed_item.shard
      finding_shard = following_user.shard
    elsif self.shard == following_user.shard
      finding_shard = followed_item.shard
    else
      return nil
    end

    finding_shard.try(:activate) do
        UserFollow.first(:conditions => { :following_user_id => following_user.id,
                                          :followed_item_id => followed_item.id,
                                          :followed_item_type => followed_item.class.name })
    end
  end

  after_create :check_auto_follow_collections

  # when a user follows a group or other user, they auto-follow all existing
  # collections in that context as well
  def check_auto_follow_collections
    return true if self.complementary_record?
    case followed_item
    when User, Group
      if !followed_item.collections.empty?
        send_later_enqueue_args :auto_follow_collections, :priority => Delayed::LOW_PRIORITY
      end
    end
    true
  end

  def auto_follow_collections
    followed_item.collections.active.each do |coll|
      if coll.grants_right?(following_user, :follow)
        UserFollow.create_follow(following_user, coll)
      end
    end
  end

  after_destroy :check_auto_unfollow_collections

  # when a user leaves a group, they auto-unfollow all private collections in
  # that group
  def check_auto_unfollow_collections
    return true if self.complementary_record?
    case followed_item
    when Group
      if !followed_item.collections.empty?
        UserFollow.send_later_enqueue_args(:auto_unfollow_collections_for,
                                           { :priority => Delayed::LOW_PRIORITY },
                                           self.following_user_id,
                                           self.followed_item_type,
                                           self.followed_item_id)
      end
    end
    true
  end

  # this is called after the UserFollow object is destroyed, so it needs to
  # re-lookup the user and context
  def self.auto_unfollow_collections_for(following_user_id, followed_item_type, followed_item_id)
    if context = Object.const_get(followed_item_type).find_by_id(followed_item_id)
      following_user = User.find(following_user_id)
      context.collections.active.each do |coll|
        if !coll.grants_right?(following_user, :follow)
          user_follow = following_user.user_follows.scoped(:conditions => { :followed_item_type => 'Collection', 
                                                                            :followed_item_id => coll.id }).first
          user_follow.try(:destroy)
        end
      end
    end
  end

  trigger.after(:insert) do |t|
    t.where("NEW.followed_item_type = 'Collection'") do
      <<-SQL
      UPDATE collections
      SET followers_count = followers_count + 1
      WHERE id = NEW.followed_item_id;
      SQL
    end
  end

  trigger.after(:delete) do |t|
    t.where("OLD.followed_item_type = 'Collection'") do
      <<-SQL
      UPDATE collections
      SET followers_count = followers_count - 1
      WHERE id = OLD.followed_item_id;
      SQL
    end
  end

  # returns the subset of items that are currently being followed by the given user
  #
  # currently this method assumes that all the items are of the same type, this
  # could be expanded later to partition the query by item type.
  def self.followed_by_user(items, user)
    user.shard.activate do
      item_subset = items
      item_ids = item_subset.map(&:id)
      followed_ids = Set.new(connection.select_values(sanitize_sql_for_conditions(["SELECT followed_item_id FROM #{table_name} WHERE following_user_id = ? AND followed_item_type = ? AND followed_item_id IN (?)", user.id, item_subset.first.class.name, item_ids])))
      item_subset.find_all { |c| followed_ids.include?(c.id.to_s) }
    end
  end

  module FollowedItem
    # returns the users who are following this item
    def followers
      follows = self.following_user_follows.to_a
      UserFollow.send(:preload_associations, follows, :following_user)
      follows.map(&:following_user)
    end
  end
end
