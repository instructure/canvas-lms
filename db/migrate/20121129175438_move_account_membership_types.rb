#
# Copyright (C) 2012 - present Instructure, Inc.
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

class MoveAccountMembershipTypes < ActiveRecord::Migration[4.2]
  # run twice, to pick up any new csv-memberships created
  # after the predeploy migration but before the deploy
  tag :postdeploy

  def self.up
    # for proper security, we need the roles copied to the Roles table
    # before the code that looks for it there is deployed,
    # hence the synchronous predeploy fixup.  there is not a lot of data
    # involved here, so it should not be too painful.
    DataFixup::MoveAccountMembershipTypesToRoles.run
  end

  def self.down
  end
end
