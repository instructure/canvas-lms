#
# Copyright (C) 2011 - present Instructure, Inc.
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

  belongs_to :discussion_entry
  belongs_to :user

  validates_presence_of :discussion_entry_id, :user_id, :workflow_state

  def self.read_entry_ids(entry_ids, user)
    self.where(:user_id => user, :discussion_entry_id => entry_ids, :workflow_state => 'read').
      pluck(:discussion_entry_id)
  end

  def self.forced_read_state_entry_ids(entry_ids, user)
    self.where(:user_id => user, :discussion_entry_id => entry_ids, :forced_read_state => true).
      pluck(:discussion_entry_id)
  end

  def self.entry_ratings(entry_ids, user)
    ratings = self.where(:user_id => user, :discussion_entry_id => entry_ids).where('rating IS NOT NULL')
    Hash[ratings.map{|x| [x.discussion_entry_id, x.rating]}]
  end

  workflow do
    state :unread
    state :read
  end

  scope :read, -> { where(:workflow_state => 'read') }
  scope :existing_participants, ->(user, entry_id) {
    select([:id, :discussion_entry_id]).
      where(user_id: user, discussion_entry_id: entry_id)
  }
end
