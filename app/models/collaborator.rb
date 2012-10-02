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
  attr_accessible :user, :collaboration, :authorized_service_user_id
  belongs_to :user
  belongs_to :collaboration
  
  has_a_broadcast_policy
  
  set_broadcast_policy do |p|
    p.dispatch :collaboration_invitation
    p.to { self.collaboration.collaboration_type == 'google_docs' ? self.user.gmail_channel : self.user }
    p.whenever {|record| record.just_created && record.collaboration && record.user != record.collaboration.user }
  end

  def context
    collaboration.try(:context)
  end
end
