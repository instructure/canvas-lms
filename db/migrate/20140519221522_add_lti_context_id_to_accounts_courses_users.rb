#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AddLtiContextIdToAccountsCoursesUsers < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :accounts, :lti_context_id, :string
    add_column :courses, :lti_context_id, :string
    add_column :users, :lti_context_id, :string
  end

  def self.down
    remove_column :accounts, :lti_context_id
    remove_column :courses, :lti_context_id
    remove_column :users, :lti_context_id
  end
end
