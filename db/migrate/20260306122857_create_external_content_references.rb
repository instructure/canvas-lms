# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class CreateExternalContentReferences < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :external_content_references do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :context, polymorphic: %i[wiki_page], foreign_key: true, null: false
      t.string :content_id, null: false, limit: 255
      t.timestamps

      t.replica_identity_index
    end
  end
end
