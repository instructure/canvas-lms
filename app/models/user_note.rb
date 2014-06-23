#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class UserNote < ActiveRecord::Base
  include Workflow
  attr_accessible :user, :note, :title, :creator
  belongs_to :user
  belongs_to :creator, :class_name => 'User', :foreign_key => :created_by_id

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :note, :title, :created_by_id, :workflow_state, :deleted_at, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:user, :creator]

  validates_presence_of :user_id, :created_by_id, :workflow_state
  validates_length_of :note, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  after_save :update_last_user_note

  sanitize_field :note, CanvasSanitize::SANITIZE

  workflow do
    state :active
    state :deleted
  end
  
  scope :active, where("workflow_state<>'deleted'")
  scope :desc_by_date, order('created_at DESC')
  
  set_policy do
    given { |user| self.creator == user }
    can :delete and can :read
    
    given { |user| self.user.grants_right?(user, nil, :delete_user_notes) }
    can :delete and can :read
    
    given { |user| self.user.grants_right?(user, nil, :read_user_notes) }
    can :read
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    save!
  end
  
  def formatted_note(truncate=nil)
    self.extend TextHelper
    res = self.note
    res = truncate_html(self.note, :max_length => truncate, :words => true) if truncate
    res
  end
  
  def creator_name
    self.creator ? self.creator.name : nil
  end
  
  def update_last_user_note
    self.user.update_last_user_note
    self.user.save
  end
  
end
