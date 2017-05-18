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

class AddOtpToUsers < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :users, :otp_secret_key_enc, :string
    add_column :users, :otp_secret_key_salt, :string
    add_column :users, :otp_communication_channel_id, :integer, :limit => 8
  end

  def self.down
    remove_column :users, :otp_communication_channel_id
    remove_column :users, :otp_secret_key_salt
    remove_column :users, :otp_secret_key_enc
  end
end
