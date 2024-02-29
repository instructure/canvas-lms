# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
class AddRatingOrderToRubrics < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    add_column :rubrics, :rating_order, :string, default: "descending", null: false
    add_check_constraint :rubrics, "rating_order IN ('descending', 'ascending')", name: "check_rating_order"
  end
end
