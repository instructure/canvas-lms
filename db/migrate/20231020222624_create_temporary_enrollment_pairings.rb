# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

class CreateTemporaryEnrollmentPairings < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    create_table :temporary_enrollment_pairings do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, null: false, index: false
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.timestamps
    end

    add_reference :enrollments,
                  :temporary_enrollment_pairing,
                  if_not_exists: true,
                  foreign_key: true,
                  index: {
                    if_not_exists: true,
                    where: "temporary_enrollment_pairing_id IS NOT NULL",
                    algorithm: :concurrently
                  }
  end
end
