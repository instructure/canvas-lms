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

class CreateAnonymousOrModerationEvents < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :anonymous_or_moderation_events do |t|
      t.belongs_to :assignment, foreign_key: true, limit: 8, index: true, null: false
      t.belongs_to :user, foreign_key: true, limit: 8, null: false
      t.belongs_to :submission, foreign_key: true, limit: 8, index: true
      t.belongs_to :canvadoc, foreign_key: true, limit: 8
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: "{}"
      t.timestamps
    end
  end
end
