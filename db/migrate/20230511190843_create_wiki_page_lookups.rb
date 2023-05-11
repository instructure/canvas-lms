# frozen_string_literal: true

#
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
#

class CreateWikiPageLookups < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :wiki_page_lookups do |t|
      t.text        :slug, null: false, index: false
      t.references  :wiki_page, null: false, foreign_key: true, index: true
      t.references  :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.integer     :context_id, null: false, limit: 8
      t.string      :context_type, null: false, limit: 255
      t.timestamps
      t.index %i[context_id context_type slug],
              name: "unique_index_on_context_and_slug",
              unique: true
    end

    reversible do |dir|
      dir.up { add_replica_identity "WikiPageLookup", :root_account_id }
      dir.down { remove_replica_identity "WikiPageLookup" }
    end
  end
end
