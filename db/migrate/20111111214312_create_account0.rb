# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class CreateAccount0 < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    Account.create_with(name: 'Dummy Root Account', workflow_state: 'deleted', root_account_id: 0)
      .find_or_create_by!(id: 0)
  end

  def down
    Account.where(id: 0).delete_all
  end
end
