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

describe DataFixup::BackfillDevKeyAccountBindings do
  describe "#run" do
    let(:key) { DeveloperKey.create! }

    it "backfills when no binding is present" do
      # Setup
      key.developer_key_account_bindings.destroy_all
      expect(key.developer_key_account_bindings.count).to eq(0)

      # Backfill with a new binding with "on" state
      described_class.run

      # Verify
      key.reload
      expect(key.developer_key_account_bindings.count).to eq(1)
      expect(
        key.developer_key_account_bindings.first.workflow_state
      ).to eq(DeveloperKeyAccountBinding::ON_STATE)
    end

    it "does not backfill when a binding is present" do
      # Setup
      expect(key.developer_key_account_bindings.count).to eq(1)
      original_binding_id = key.developer_key_account_bindings.first.id

      # The backfill should not change the binding's state
      described_class.run

      # Verify
      key.reload
      expect(key.developer_key_account_bindings.count).to eq(1)
      expect(key.developer_key_account_bindings.first.id).to eq(original_binding_id)
    end
  end
end
