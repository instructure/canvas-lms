# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::PopulateIdentityHashOnContextExternalTools do
  describe "run" do
    context "when the external tool is not duplicated" do
      it "sets the identity hash" do
        tool = external_tool_model
        tool.update_column(:identity_hash, nil)

        expect do
          DataFixup::PopulateIdentityHashOnContextExternalTools.run(tool.id - 1, tool.id + 1)
        end.to change { tool.reload.identity_hash }.from(nil).to(String)
        expect(tool.identity_hash).to eq tool.calculate_identity_hash
      end
    end

    context "when the external tool has a duplicate" do
      it "sets the identity hash to 'duplicate'" do
        account_model
        tool1 = external_tool_model(context: @account)
        tool1.update_column(:identity_hash, nil)
        tool2 = external_tool_model(context: @account)
        tool2.update_column(:identity_hash, nil)
        external_tool_model(context: @account)

        expect do
          DataFixup::PopulateIdentityHashOnContextExternalTools.run(tool1.id, tool2.id)
        end.to change { tool1.reload.identity_hash }.from(nil).to("duplicate")
        expect(tool2.reload.identity_hash).to eq "duplicate"
      end
    end

    context "when there are multiple tools in the batch with the same information" do
      it "sets the identity hash to 'duplicate' for one and the real identity hash for the other" do
        account_model
        tool1 = external_tool_model(context: @account)
        tool1.update_column(:identity_hash, nil)
        tool2 = external_tool_model(context: @account)
        tool2.update_column(:identity_hash, nil)

        expect do
          DataFixup::PopulateIdentityHashOnContextExternalTools.run(tool1.id, tool2.id)
        end.to change { tool1.reload.identity_hash }.from(nil).to(String)
        expect(tool1.identity_hash).not_to eq("duplicate")
        expect(tool2.reload.identity_hash).to eq("duplicate")
      end
    end
  end
end
