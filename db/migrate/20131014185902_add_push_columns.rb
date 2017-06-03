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

class AddPushColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :developer_keys, :sns_arn, :string
    add_column :communication_channels, :access_token_id, :integer, limit: 8
    add_column :communication_channels, :internal_path, :string
    add_foreign_key :communication_channels, :access_tokens
  end

  def self.down
    remove_column :developer_keys, :sns_arn
    remove_column :communication_channels, :access_token_id
    remove_column :communication_channels, :internal_path
  end
end
