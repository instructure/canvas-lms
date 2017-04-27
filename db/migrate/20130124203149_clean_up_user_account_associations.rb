#
# Copyright (C) 2013 - present Instructure, Inc.
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

class CleanUpUserAccountAssociations < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    # clean up garbage data
    UserAccountAssociation.where(:user_id => nil).delete_all
    # we don't have any of these in production, but just in case...
    UserAccountAssociation.where(:account_id => nil).delete_all

    # clean up dups by recalculating
    user_ids = UserAccountAssociation.
        select(:user_id).
        distinct.
        group(:user_id, :account_id).
        having("COUNT(*)>1").
        map(&:user_id)
    User.update_account_associations(user_ids)

    # add a unique index
    add_index :user_account_associations, [:user_id, :account_id], :unique => true, :algorithm => :concurrently
    # remove the non-unique index that's now covered by the unique index
    remove_index :user_account_associations, :user_id
  end

  def self.down
    add_index :user_account_associations, :user_id, :algorithm => :concurrently
    remove_index :user_account_associations, [:user_id, :account_id]
  end
end
