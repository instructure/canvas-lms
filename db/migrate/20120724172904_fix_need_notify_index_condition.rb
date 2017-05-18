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

class FixNeedNotifyIndexCondition < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  # this migration fixes a the bad index condition in AddNeedNotifyColumnToAttachments

  def self.up
    if connection.adapter_name =~ /\Apostgresql/i
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_attachments_on_need_notify')}")
      add_index :attachments, :need_notify, :algorithm => :concurrently, :where => "need_notify"
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      # before running this migration, the index was either nonexistent or useless
      # so we'll settle for nonexistent when rolling back; the behavior is the same
      remove_index :attachments, :need_notify
    end
  end
end

