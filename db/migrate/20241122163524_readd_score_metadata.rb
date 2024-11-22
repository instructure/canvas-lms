# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class ReaddScoreMetadata < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    # This table was never sent off to DAP, so it never had a root account id. If we go to send it off to DAP, we'll
    # need to add that column, but for us putting thigns back they way they were before the drop and then revert in
    # previous commits, this is fine.
    #
    # rubocop:disable Migration/RootAccountId
    create_table :score_metadata, if_not_exists: true do |t|
      t.references :score, null: false, foreign_key: true, index: { unique: true }
      t.json :calculation_details, default: {}, null: false
      t.timestamps precision: nil
      t.string :workflow_state, default: "active", null: false
    end
    # rubocop:enable Migration/RootAccountId
  end
end
