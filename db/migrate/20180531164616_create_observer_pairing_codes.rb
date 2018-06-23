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
#

class CreateObserverPairingCodes < ActiveRecord::Migration[5.1]
  tag :predeploy
  def change
    create_table :observer_pairing_codes do |t|
      t.belongs_to :user, :null => false, :foreign_key => true
      t.string :code, :null => false, :limit => 10
      t.timestamp :expires_at, :null => false, :index => true
      t.string :workflow_state, :default => 'active', :null => false, :index => true

      t.timestamps
    end
  end
end
