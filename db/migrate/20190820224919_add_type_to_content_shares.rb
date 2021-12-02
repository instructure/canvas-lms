# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
#

class AddTypeToContentShares < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    add_column :content_shares, :type, :string, limit: 255
    # there shouldn't be any ContentShares in production, so we shouldn't have to worry
    # about long jobs
    ContentShare.where(type: nil, sender_id: nil).update_all(type: 'SentContentShare')
    ContentShare.where(type: nil).where.not(sender_id: nil).update_all(type: 'ReceivedContentShare')
    change_column :content_shares, :type, :string, limit: 255, null: false
  end

  def down
    remove_column :content_shares, :type, :string, limit: 255
  end
end
