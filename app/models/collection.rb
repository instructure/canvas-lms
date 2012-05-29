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

  belongs_to :context, :polymorphic => true
  has_many :collection_items

  attr_accessible :name, :visibility
  validates_as_readonly :visibility

  validates_inclusion_of :visibility, :in => %w(public private)

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
  end

  set_policy do
    given { |user| self.public? }
    can :read and can :comment

    given { |user| self.context == user }
    can :read and can :create and can :update and can :delete and can :comment
  end
end
