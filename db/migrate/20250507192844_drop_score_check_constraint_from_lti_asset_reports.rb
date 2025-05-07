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

class DropScoreCheckConstraintFromLtiAssetReports < ActiveRecord::Migration[7.2]
  tag :postdeploy

  def change
    change_table :lti_asset_reports, bulk: true do |t|
      t.remove_check_constraint <<~SQL.squish, name: "chk_score_maximum_present_if_score_given_present"
        (score_maximum IS NOT NULL) OR (score_given IS NULL)
      SQL
    end
  end
end
