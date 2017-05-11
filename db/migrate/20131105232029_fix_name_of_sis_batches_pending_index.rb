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

class FixNameOfSisBatchesPendingIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL' && connection.select_value("SELECT 1 FROM pg_class INNER JOIN pg_namespace ON relnamespace=pg_namespace.oid WHERE relname='index_sis_batches_on_account_id_and_created_at' AND nspname=ANY(current_schemas(false))")
      rename_index :sis_batches, 'index_sis_batches_on_account_id_and_created_at', 'index_sis_batches_pending_for_accounts'
    end
  end
end
