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

class AddNeedNotifyColumnToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :attachments, :need_notify, :boolean
    Attachment.reset_column_information
    if connection.adapter_name =~ /\Apostgresql/i
      # bad index condition; postpone creating this index until FixNeedNotifyIndexCondition
      #execute('CREATE INDEX CONCURRENTLY "index_attachments_on_need_notify" ON #{Attachment.quoted_table_name}(need_notify) WHERE need_notify IS NOT NULL')
    else
      add_index :attachments, [:need_notify], :name => "index_attachments_on_need_notify"
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      # this may exist if the source gets upated between migrate and rollback
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_attachments_on_need_notify')}")
    else
      remove_index :attachments, :name => "index_attachments_on_need_notify"
    end
    remove_column :attachments, :need_notify
  end
end

