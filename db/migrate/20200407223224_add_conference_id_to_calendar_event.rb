#
# Copyright (C) 2020 - present Instructure, Inc.
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

class AddConferenceIdToCalendarEvent < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_reference :calendar_events, :web_conference, type: :bigint, foreign_key: true, index: false
    add_index :calendar_events, :web_conference_id, where: 'web_conference_id IS NOT NULL', unique: false, algorithm: :concurrently, if_not_exists: true
  end
end
