# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe Lti::AssetProcessorEulaAcceptance do
  describe "model" do
    before do
      @eula1 = lti_asset_processor_eula_model
      @eula1.save!
      @eula2 = lti_asset_processor_eula_model
      @eula2.save!
    end

    it "active scope returns only active eulas" do
      @eula2.destroy!

      expect(Lti::AssetProcessorEulaAcceptance.active).to eq([@eula1])
    end

    it "enforces unique constraint on user_id, context_external_tool_id, and active records" do
      expect do
        lti_asset_processor_eula_model(
          user: @eula1.user,
          context_external_tool: @eula1.context_external_tool
        )
      end.to raise_error(ActiveRecord::RecordInvalid, /Validation failed/)
    end
  end
end
