# frozen_string_literal: true

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

class AddAssignmentEmbeddings < ActiveRecord::Migration[7.0]
  tag :predeploy

  def self.runnable?
    connection.extension_available?(:vector)
  end

  def change
    create_table :assignment_embeddings do |t|
      t.references :assignment, null: false, foreign_key: true
      t.column :embedding, "#{connection.extension("vector").schema}.vector", limit: 1536, null: false
      t.timestamps
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
    end
  end
end
