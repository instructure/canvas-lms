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

class Collection < ActiveRecord::Base
  include Workflow
  include CustomValidations
  include UserFollow::FollowedItem

  belongs_to :context, :polymorphic => true
  has_many :collection_items
  has_many :following_user_follows, :class_name => 'UserFollow', :as => :followed_item

  attr_accessible :name, :visibility
  validates_allowed_transitions :visibility, "private" => "public"

  validates_inclusion_of :visibility, :in => %w(public private)

  after_create :check_auto_follow_users

  named_scope :public, :conditions => { :visibility => 'public' }
  named_scope :newest_first, { :order => "id desc" }

  def public?
    self.visibility == 'public'
  end

  workflow do
    state :active
    state :deleted
  end

  named_scope :active, { :conditions => { :workflow_state => 'active' } }

  def destroy
    self.workflow_state = 'deleted'
    save!
    # follows won't be recoverable on undelete, they'll have to be re-created
    following_user_follows.destroy_all
  end

  set_policy do
    given { |user| self.public? }
    can :read and can :comment

    given { |user| user.present? && self.public? }
    can :follow

    given { |user| self.context == user }
    can :read and can :create and can :update and can :delete and can :comment

    given { |user| self.context.respond_to?(:has_member?) && self.context.has_member?(user) }
    can :read and can :comment and can :follow

    given { |user| self.context.respond_to?(:has_moderator?) && self.context.has_moderator?(user) }
    can :read and can :create and can :update and can :delete and can :comment
  end

  def check_auto_follow_users
    if context.respond_to?(:following_user_follows) && !context.following_user_follows.empty?
      send_later_enqueue_args :auto_follow_users, :priority => Delayed::LOW_PRIORITY
    end
    true
  end

  def auto_follow_users
    context.followers.each do |user|
      if self.grants_right?(user, :follow)
        UserFollow.create_follow(user, self)
      end
    end
  end
end
