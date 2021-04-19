# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
class AddRedoRequestToSubmissions < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    if connection.postgresql_version >= 110000
      remove_column :submissions, :redo_request, if_exists: true
      add_column :submissions, :redo_request, :boolean, default: false, null: false
    else
      # backfill and default will come in a postdeploy
      add_column :submissions, :redo_request, :boolean
      change_column_default(:submissions, :redo_request, false)
    end
  end

  def down
    remove_column :submissions, :redo_request, if_exists: true
  end
end
