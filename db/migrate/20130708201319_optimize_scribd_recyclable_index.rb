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

class OptimizeScribdRecyclableIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :attachments, name: 'scribd_attempts_smt_workflow_state'
      add_index :attachments, :scribd_attempts, algorithm: :concurrently, where: "workflow_state='errored' AND scribd_mime_type_id IS NOT NULL", name: 'scribd_attempts_smt_workflow_state'
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      remove_index :attachments, name: 'scribd_attempts_smt_workflow_state'
      add_index :attachments, [:scribd_attempts, :scribd_mime_type_id, :workflow_state], algorithm: :concurrently, name: 'scribd_attempts_smt_workflow_state'
    end
  end
end
