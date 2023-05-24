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

class AddContextToOutcomeProficiency < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :predeploy

  def change
    add_column :outcome_proficiencies, :context_id, :integer, limit: 8, if_not_exists: true
    add_column :outcome_proficiencies, :context_type, :string, limit: 255, if_not_exists: true
    add_index :outcome_proficiencies, [:context_id, :context_type],
              algorithm: :concurrently, unique: true,
              where: "context_id IS NOT NULL", if_not_exists: true
  end
end
