# frozen_string_literal: true

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

class AddImportantDatesColumns < ActiveRecord::Migration[6.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :assignments, :important_dates, :boolean, if_not_exists: true, default: false, null: false
    add_column :calendar_events, :important_dates, :boolean, if_not_exists: true, default: false, null: false

    add_index :assignments, :important_dates, where: "important_dates", algorithm: :concurrently, if_not_exists: true
    add_index :calendar_events, :important_dates, where: "important_dates", algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_column :assignments, :important_dates
    remove_column :calendar_events, :important_dates
  end
end
