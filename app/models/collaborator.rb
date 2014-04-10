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

class Collaborator < ActiveRecord::Base
  attr_accessible :authorized_service_user_id, :collaboration, :group, :user

  belongs_to :collaboration
  belongs_to :group
  belongs_to :user

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :collaboration_id, :created_at, :updated_at, :authorized_service_user_id, :group_id]
  EXPORTABLE_ASSOCIATIONS = [:collaboration, :group, :user]

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :collaboration_invitation
    p.to {
      if self.collaboration.collaboration_type == 'google_docs'
        self.group_id.nil? ? self.user.gmail_channel : (self.group.users - [self.user]).map(&:gmail_channel)
      else
        self.group_id.nil? ? self.user : self.group.users - [self.user]
      end
    }
    p.whenever { |record|
      if record.group_id.nil?
        record.just_created && record.collaboration && record.user != record.collaboration.user
      else
        record.just_created && record.collaboration
      end
    }
  end

  def context
    collaboration.try(:context)
  end
end
