# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class ChangeCalendarEventsLocationToText < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column :calendar_events, :location_name, :text
    change_column :calendar_events, :location_address, :text
  end

  def down
    change_column :calendar_events, :location_name, :string
    change_column :calendar_events, :location_address, :string
  end
end
