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

class AddReplicaIdentityForContentTags < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    until ContentTag.left_outer_joins(:assignment).
      where(context_type: 'Assignment', root_account_id: nil, assignments: {id: nil}).limit(1_000).delete_all < 1_000
    end
    until ContentTag.left_outer_joins(:course).
      where(context_type: 'Course', root_account_id: nil, courses: {id: nil}).limit(1_000).delete_all < 1_000
    end
    add_replica_identity 'ContentTag', :root_account_id, 0
    remove_index :content_tags, name: 'index_content_tags_on_root_account_id', if_exists: true
  end

  def down
    add_index :content_tags, :root_account_id, algorithm: :concurrently, if_not_exists: true
    remove_replica_identity 'ContentTag'
    change_column_null :content_tags, :root_account_id, true
  end
end
