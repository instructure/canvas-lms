# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class CreateQuizMigrationAlerts < ActiveRecord::Migration[6.0]
  tag :predeploy

  def change
    create_table :quiz_migration_alerts do |t|
      t.belongs_to :migration, polymorphic: true
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.timestamps
    end

    add_index :quiz_migration_alerts, :user_id, if_not_exists: true
    add_index :quiz_migration_alerts, :course_id, if_not_exists: true
  end
end
