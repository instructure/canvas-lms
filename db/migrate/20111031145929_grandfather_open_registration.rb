#
# Copyright (C) 2011 - present Instructure, Inc.
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

class GrandfatherOpenRegistration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Account.root_accounts.find_each do |account|
      # Grandfather all old accounts to open_registration
      account.settings = { :open_registration => true }
      # These settings were previously exposed, but defaulted to true. They now default to false.
      # So grandfather in the previous setting, accounting for the old default
      [:teachers_can_create_courses, :students_can_create_courses, :no_enrollments_can_create_courses].each do |setting|
        account.settings = { setting => true } if account.settings[setting] != false
      end
      account.save!
    end
  end

  def self.down
  end
end
