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

class AddReplicaIdentityForGroupCategories < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_replica_identity 'GroupCategory', :root_account_id, 0
    remove_index :group_categories, name: 'index_group_categories_on_root_account_id', if_exists: true
  end

  def down
    remove_replica_identity 'GroupCategory'
    # no need to re-add index_group_categories_on_root_account_id
    # since index_group_categories_on_root_account_id_and_sis_source_id exists
  end
end
