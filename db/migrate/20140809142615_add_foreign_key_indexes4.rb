#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AddForeignKeyIndexes4 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :attachments, :replacement_attachment_id, algorithm: :concurrently, where: "replacement_attachment_id IS NOT NULL"
    add_index :discussion_topics, :old_assignment_id, algorithm: :concurrently, where: "old_assignment_id IS NOT NULL"
    add_index :enrollment_terms, :sis_batch_id, algorithm: :concurrently, where: "sis_batch_id IS NOT NULL"
    add_index :zip_file_imports, :folder_id, algorithm: :concurrently
  end
end
