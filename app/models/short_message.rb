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

class ShortMessage < ActiveRecord::Base
  attr_accessible :message, :user, :author_name, :is_public, :service_message_id, :service, :service_user_name
  has_many :short_message_associations, :dependent => :destroy
  belongs_to :user
  
  def author_name
    self.user ? self.user.name : self.service_user_name
  end
end
