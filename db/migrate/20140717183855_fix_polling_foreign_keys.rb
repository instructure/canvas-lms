#
# Copyright (C) 2014 - present Instructure, Inc.
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

class FixPollingForeignKeys < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    change_column :polling_poll_submissions, :poll_session_id, :integer, limit: 8, null: false
    change_column :polling_polls, :user_id, :integer, limit: 8, null: false
  end

  def self.down
  end
end
