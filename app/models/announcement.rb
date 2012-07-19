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

class Announcement < DiscussionTopic
  
  belongs_to :context, :polymorphic => true
  
  has_a_broadcast_policy
  include HasContentTags
  
  sanitize_field :message, Instructure::SanitizeField::SANITIZE
  
  before_save :infer_content
  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :message
  
  def infer_content
    self.title ||= t(:no_title, "No Title")
  end
  protected :infer_content
  
  set_broadcast_policy do 
    dispatch :new_announcement
    to { active_participants(true) - [user] }
    whenever { |record| 
      record.context.available? and
      ((record.just_created and not record.post_delayed?) || record.changed_state(:active, :post_delayed))
    }
  end
    
  set_policy do
    given { |user| self.user == user }
    can :update and can :reply and can :read
    
    given { |user| self.user == user and self.discussion_entries.active.empty? }
    can :delete
    
    given { |user, session| self.context.grants_rights?(user, session, :read)[:read] }
    can :read
    
    given { |user, session| self.context.grants_right?(user, session, :post_to_forum) }
    can :reply
    
    given { |user, session| self.context.is_a?(Group) && self.context.grants_right?(user, session, :post_to_forum) }
    can :create

    given { |user, session| self.context.grants_right?(user, session, :moderate_forum) } #admins.include?(user) }
    can :update and can :delete and can :reply and can :create and can :read and can :attach
  end
  
  def is_announcement; true end
end
