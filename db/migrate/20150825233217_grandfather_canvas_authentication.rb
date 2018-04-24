#
# Copyright (C) 2015 - present Instructure, Inc.
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

class GrandfatherCanvasAuthentication < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    AuthenticationProvider::Canvas.reset_column_information
    Account.root_accounts.each do |account|
      if account.settings[:canvas_authentication] != false || !account.authentication_providers.active.exists?
        account.enable_canvas_authentication
      end
    end
  end

  def down
    AuthenticationProvider.where(auth_type: 'canvas').delete_all
  end
end
