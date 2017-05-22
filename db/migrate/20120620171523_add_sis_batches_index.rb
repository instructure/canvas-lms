#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddSisBatchesIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    # this index may or may not have been created on dev boxes
    remove_index :sis_batches, :name => "index_sis_batches_for_accounts" rescue nil

    case connection.adapter_name
    when 'PostgreSQL'
      # select * from sis_batches where account_id = ? and workflow_state = 'created' order by created_at
      # select count(*) from sis_batches where account_id = ? and workflow_state = 'created'
      # this index is highly optimized for the sis batch job processor workflow
      add_index :sis_batches, [:account_id, :created_at], :algorithm => :concurrently, :where => "workflow_state='created'", name: "index_sis_batches_pending_for_accounts"
      # select * from sis_batches where account_id = ? order by created_at desc limit 1
    else
      add_index :sis_batches, [:workflow_state, :account_id, :created_at], :name => "index_sis_batches_pending_for_accounts"
    end
    add_index :sis_batches, [:account_id, :created_at], :algorithm => :concurrently, :name => "index_sis_batches_account_id_created_at"
  end

  def self.down
    remove_index :sis_batches, :name => "index_sis_batches_pending_for_accounts"
    remove_index :sis_batches, :name => "index_sis_batches_account_id_created_at"
  end
end
