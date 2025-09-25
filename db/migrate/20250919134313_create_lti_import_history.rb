# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class CreateLtiImportHistory < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :lti_import_histories do |t|
      t.string :target_lti_id, null: false, limit: 255
      t.string :source_lti_id, null: false, limit: 255
      t.timestamps
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.index %i[target_lti_id source_lti_id], unique: true, name: "index_lti_import_histories_on_target_source"

      t.replica_identity_index
    end
  end
end
