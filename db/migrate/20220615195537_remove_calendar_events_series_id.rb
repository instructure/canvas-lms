# frozen_string_literal: true

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

# there doesn't seem to be a way to make rubocop happy if you're removing
# and adding a column in the same migration. It could be done in 2
# migrations, but this is more clear.
# The end result is to change the type of the series_id (now series_uuid) column.
# This is being done during active development, so there's no production data yet
# to worry about

class RemoveCalendarEventsSeriesId < ActiveRecord::Migration[6.1]
  tag :postdeploy

  def change
    remove_index :calendar_events, :series_id, if_exists: true
    remove_column :calendar_events, :series_id, if_exists: true
  end
end
