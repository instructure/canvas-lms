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

class ClearUnusedAccountSettings < ActiveRecord::Migration[6.0]
  tag :postdeploy

  def up
    DataFixup::ClearAccountSettings.delay_if_production(
      priority: Delayed::LOW_PRIORITY,
      n_strand: "long_datafixups"
    ).run(%w[allow_last_page_on_course_users
             allow_last_page_on_account_courses
             allow_last_page_on_users])
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
