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
#

require 'spec_helper'

describe DataFixup::SetExistingBindingState do
  describe "#run" do
    it "sets the bindings workflow_state" do
      # Setup keys
      active_key_1   = DeveloperKey.create!
      active_key_2   = DeveloperKey.create!
      inactive_key_1 = DeveloperKey.create!.tap(&:deactivate)
      inactive_key_2 = DeveloperKey.create!.tap(&:deactivate)
      deleted_key_1  = DeveloperKey.create!.tap(&:destroy)
      deleted_key_2  = DeveloperKey.create!.tap(&:destroy)

      # Set bindings' workflow state
      active_key_1.developer_key_account_bindings.first.update(workflow_state: DeveloperKeyAccountBinding::ON_STATE)
      active_key_2.developer_key_account_bindings.first.update(workflow_state: DeveloperKeyAccountBinding::OFF_STATE)
      inactive_key_1.developer_key_account_bindings.first.update(workflow_state: DeveloperKeyAccountBinding::ON_STATE)
      inactive_key_2.developer_key_account_bindings.first.update(workflow_state: DeveloperKeyAccountBinding::OFF_STATE)
      deleted_key_1.developer_key_account_bindings.first.update(workflow_state: DeveloperKeyAccountBinding::ON_STATE)
      deleted_key_2.developer_key_account_bindings.first.update(workflow_state: DeveloperKeyAccountBinding::OFF_STATE)

      # Update binding state
      described_class.run

      # Verify
      expect(
        active_key_1.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::ON_STATE)

      expect(
        active_key_2.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::ON_STATE)

      expect(
        inactive_key_1.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::OFF_STATE)

      expect(
        inactive_key_2.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::OFF_STATE)

      expect(
        deleted_key_1.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::OFF_STATE)

      expect(
        deleted_key_2.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::OFF_STATE)
    end
  end
end
