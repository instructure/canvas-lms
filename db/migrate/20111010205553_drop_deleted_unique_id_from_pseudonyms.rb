#
# Copyright (C) 2011 - present Instructure, Inc.
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

class DropDeletedUniqueIdFromPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Pseudonym.where("deleted_unique_id IS NOT NULL AND workflow_state='deleted'").update_all('unique_id=deleted_unique_id')
    remove_column :pseudonyms, :deleted_unique_id
  end

  def self.down
    add_column :pseudonyms, :deleted_unique_id, :string
    Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all('deleted_unique_id=unique_id')
    Pseudonym.where("unique_id IS NOT NULL AND workflow_state='deleted'").update_all("unique_id=unique_id || '--' || SUBSTR(CAST(RANDOM() AS varchar), 3, 4)")
  end
end
