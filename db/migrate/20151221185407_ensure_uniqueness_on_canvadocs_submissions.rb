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

class EnsureUniquenessOnCanvadocsSubmissions < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::RemoveDuplicateCanvadocsSubmissions.run

    remove_index :canvadocs_submissions, :canvadoc_id
    remove_index :canvadocs_submissions, :crocodoc_document_id

    add_index :canvadocs_submissions, [:submission_id, :canvadoc_id],
      where: "canvadoc_id IS NOT NULL",
      name: "unique_submissions_and_canvadocs",
      unique: true, algorithm: :concurrently
    add_index :canvadocs_submissions, [:submission_id, :crocodoc_document_id],
      where: "crocodoc_document_id IS NOT NULL",
      name: "unique_submissions_and_crocodocs",
      unique: true, algorithm: :concurrently
  end

  def down
    remove_index "canvadocs_submissions", name: "unique_submissions_and_canvadocs"
    remove_index "canvadocs_submissions", name: "unique_submissions_and_crocodocs"

    add_index :canvadocs_submissions, :canvadoc_id,
      where: "canvadoc_id IS NOT NULL"
    add_index :canvadocs_submissions, :crocodoc_document_id,
      where: "crocodoc_document_id IS NOT NULL"
  end
end
