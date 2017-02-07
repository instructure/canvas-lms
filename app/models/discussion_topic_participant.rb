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

class DiscussionTopicParticipant < ActiveRecord::Base
  include Workflow

  belongs_to :discussion_topic
  belongs_to :user

  before_save :check_unread_count

  validates_presence_of :discussion_topic_id, :user_id, :workflow_state, :unread_entry_count

  # keeps track of the read state for the initial discussion topic text
  workflow do
    state :unread
    state :read
  end

  private
  # Internal: Ensure unread count never drops below 0.
  #
  # Returns nothing.
  def check_unread_count
    self.unread_entry_count = 0 if unread_entry_count <= 0
  end
end
