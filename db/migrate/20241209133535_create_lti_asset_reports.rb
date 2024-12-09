# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class CreateLtiAssetReports < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :lti_asset_reports do |t|
      t.string :report_type, null: false
      t.timestamp :timestamp, null: false
      t.string :title
      t.string :comment
      t.float :score_given
      t.float :score_maximum

      t.check_constraint <<~SQL.squish, name: "score_maximum_present_if_score_given_present"
        (score_maximum IS NOT NULL) OR (score_given IS NULL)
      SQL

      t.string :indication_color, limit: 255
      t.string :indication_alt, limit: 255
      t.string :processing_progress, null: false
      t.string :error_code
      t.integer :priority, null: false

      t.jsonb :extensions, null: false, default: {}

      t.references :lti_asset, null: false, foreign_key: true
      t.references :lti_asset_processor, null: false, foreign_key: true
      # Per spec, there can only be one active asset report per asset-type
      t.index %i[lti_asset_id lti_asset_processor_id report_type], unique: true, where: "workflow_state = 'active'"

      t.string :workflow_state, limit: 255, null: false
      t.timestamps
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
    end
  end
end
