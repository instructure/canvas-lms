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

class DiscussionEntryParticipant < ActiveRecord::Base
  include Workflow

  # Be more restrictive if this is ever updatable from user params
  attr_accessible :discussion_entry, :user, :workflow_state

  belongs_to :discussion_entry
  belongs_to :user

  def self.read_entry_ids(entry_ids, user)
    self.connection.select_values(sanitize_sql_array ["SELECT discussion_entry_id FROM #{connection.quote_table_name(table_name)} WHERE user_id = ? AND discussion_entry_id IN (?) AND workflow_state = ?", user.id, entry_ids, 'read']).map(&:to_i)
  end

  workflow do
    state :unread
    state :read
  end

  scope :read, where(:workflow_state => 'read')
end
