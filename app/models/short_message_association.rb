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

class ShortMessageAssociation < ActiveRecord::Base
  attr_accessible :context, :short_message
  belongs_to :short_message
  belongs_to :context, :polymorphic => true
  

  set_policy do
    given {|user, session| self.context.grants_rights?(user, session, :read)[:read] }
    can :read
    
    given {|user, session| self.context.grants_right?(user, session, :participate_as_student) }
    can :read and can :create
    
    given {|user, session| user && self.short_message && self.short_message.user_id == user.id }
    can :read and can :delete
    
    given {|user, session| self.context.grants_rights?(user, session, :manage)[:manage] }
    can :read and can :create and can :delete
  end
end
