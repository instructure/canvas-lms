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

require_relative '20180516171715_add_index_to_observer_alert_threshold'

class FixupAddIndexToObserverAlertThreshold < ActiveRecord::Migration[5.1]
  tag :predeploy
  def change
    ObserverAlertThreshold.delete_all # no data expected. This should be a no-op, but just in case
    revert AddIndexToObserverAlertThreshold

    change_table :observer_alert_thresholds do |t|
      t.remove_belongs_to :user_observation_link, foreign_key: { to_table: 'user_observers' }
      t.references :user, null: false, foreign_key: { to_table: 'users'}
      t.references :observer, null: false, foreign_key: { to_table: 'users'}
    end

    add_index :observer_alert_thresholds, [:alert_type, :user_id, :observer_id], unique: true, name: 'observer_alert_thresholds_on_alert_type_and_observer_and_user'
  end
end
