# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

class AddAvailabilityColumns < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    change_table :wiki_pages, bulk: true do |t|
      t.column :unlock_at, :datetime
      t.column :lock_at, :datetime
      t.column :only_visible_to_overrides, :boolean, default: false, null: false
    end

    change_table :discussion_topics, bulk: true do |t|
      t.column :unlock_at, :datetime
      t.column :only_visible_to_overrides, :boolean, default: false, null: false
    end

    add_column :attachments, :only_visible_to_overrides, :boolean, default: false, null: false
  end
end
