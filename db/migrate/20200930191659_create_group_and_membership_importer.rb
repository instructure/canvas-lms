# frozen_string_literal: true

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

class CreateGroupAndMembershipImporter < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :group_and_membership_importers do |t|
      t.references :group_category, foreign_key: true, index: true, null: false, limit: 8
      t.references :attachment, foreign_key: true, index: false, limit: 8
      t.string :workflow_state, null: false, default: 'active'
      t.timestamps null: false
    end
  end
end
