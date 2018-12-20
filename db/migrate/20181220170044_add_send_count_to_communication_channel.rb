#
# Copyright (C) 2018 - present Instructure, Inc.
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

class AddSendCountToCommunicationChannel < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :communication_channels, :confirmation_sent_count, :integer
    change_column_default(:communication_channels, :confirmation_sent_count, 0)
    DataFixup::BackfillNulls.run(CommunicationChannel, :confirmation_sent_count, default_value: 0)
    change_column_null(:communication_channels, :confirmation_sent_count, false)
  end

  def down
    remove_column :communication_channels, :confirmation_sent_count
  end
end
