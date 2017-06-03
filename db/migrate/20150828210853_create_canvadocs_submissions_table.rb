#
# Copyright (C) 2015 - present Instructure, Inc.
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

class CreateCanvadocsSubmissionsTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :canvadocs_submissions do |t|
      t.integer :canvadoc_id, limit: 8
      t.integer :crocodoc_document_id, limit: 8
      t.integer :submission_id, limit: 8, null: false
    end

    add_foreign_key :canvadocs_submissions, :submissions
    add_foreign_key :canvadocs_submissions, :canvadocs
    add_foreign_key :canvadocs_submissions, :crocodoc_documents

    add_index :canvadocs_submissions, :canvadoc_id, where: "canvadoc_id IS NOT NULL"
    add_index :canvadocs_submissions, :crocodoc_document_id, where: "crocodoc_document_id IS NOT NULL"
    add_index :canvadocs_submissions, :submission_id
  end
end
