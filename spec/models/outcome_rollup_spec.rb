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

describe OutcomeRollup do
  describe "validations" do
    it "allows valid calculation methods" do
      valid_methods = %w[average decaying_average highest latest n_mastery standard_decaying_average weighted_average]
      valid_methods.each do |method|
        rollup = outcome_rollup_model(calculation_method: method)
        expect(rollup).to be_valid, "Expected calculation method '#{method}' to be valid"
      end
    end

    it "starts in an active state" do
      rollup = outcome_rollup_model(calculation_method: "decaying_average")

      expect(rollup.workflow_state).to eq "active"
    end
  end
end
