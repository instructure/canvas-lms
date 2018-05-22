#
# Copyright (C) 2018 - present Instructure, Inc.
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

module DataFixup
  module BackfillDevKeyAccountBindingsForDeletedKeys
    def self.run
      DeveloperKey.not_active.find_each do |developer_key|
        find_or_create_default_account_binding(developer_key)
      end
    end

    def self.find_or_create_default_account_binding(developer_key)
      return if developer_key.owner_account.developer_key_account_bindings.where(developer_key: developer_key).exists?

      developer_key.owner_account.developer_key_account_bindings.create!(
        workflow_state: DeveloperKeyAccountBinding::OFF_STATE,
        developer_key: developer_key
      )
    end
  end
end

