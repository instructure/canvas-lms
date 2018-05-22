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

module DataFixup::SetExistingBindingState
  def self.run
    DeveloperKeyAccountBinding.find_each do |binding|
      # This shouldn't ever happen, but strange things occur
      next if binding.developer_key.blank?

      new_workflow_state = DeveloperKeyAccountBinding::ON_STATE

      if binding.developer_key.workflow_state == 'deleted' || binding.developer_key.workflow_state == 'inactive'
        new_workflow_state = DeveloperKeyAccountBinding::OFF_STATE
      end

      binding.update!(workflow_state: new_workflow_state) unless binding.workflow_state == new_workflow_state
    end
  end
end

