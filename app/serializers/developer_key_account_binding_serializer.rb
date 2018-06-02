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

class DeveloperKeyAccountBindingSerializer
  def initialize(developer_key_account_binding, context)
    @binding = developer_key_account_binding
    @context = context
  end

  def as_json
    {
      id: @binding.global_id,
      account_id: @binding.account.global_id,
      developer_key_id: @binding.developer_key.global_id,
      workflow_state: @binding.workflow_state,
      account_owns_binding: @binding.account == @context
    }
  end
end
