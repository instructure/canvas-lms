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
class AddCheckConstraintToFeatureFlags < ActiveRecord::Migration[7.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_check_constraint :feature_flags, "context_type IN ('Account', 'User', 'Course')", name: "feature_flags_context_type_check", validate: false, if_not_exists: true
    validate_constraint(:feature_flags, "feature_flags_context_type_check")
  end
end
