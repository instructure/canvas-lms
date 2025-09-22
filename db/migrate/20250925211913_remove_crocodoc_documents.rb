# frozen_string_literal: true

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

class RemoveCrocodocDocuments < ActiveRecord::Migration[7.2]
  tag :postdeploy

  def up
    remove_reference :canvadocs_submissions,
                     :crocodoc_document,
                     if_exists: true,
                     foreign_key: { to_table: :crocodoc_documents }

    drop_table :crocodoc_documents, if_exists: true
  end

  def down
    create_table :crocodoc_documents do |t|
      t.string :uuid, limit: 255, index: true
      t.string :process_state, limit: 255, index: true
      t.references :attachment
      t.timestamps null: true, precision: nil
    end

    add_reference :canvadocs_submissions,
                  :crocodoc_document,
                  if_not_exists: true,
                  foreign_key: { to_table: :crocodoc_documents }
  end
end
