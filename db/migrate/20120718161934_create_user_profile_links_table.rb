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

class CreateUserProfileLinksTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :user_profile_links do |t|
      t.string :url
      t.string :title
      t.references :user_profile, :limit => 8
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :user_profile_links
  end
end
