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
#

describe OutcomesFeaturesHelper do
  include OutcomesFeaturesHelper

  before :once do
    @account = Account.default
    @context = @course = @account.courses.create!
    outcome_model(context: @course)
  end

  describe "#individual_outcome_rating_and_calculation_enabled?" do
    before do
      @context.root_account.enable_feature!(:improved_outcomes_management)
      @context.root_account.enable_feature!(:individual_outcome_rating_and_calculation)
      @context.root_account.disable_feature!(:account_level_mastery_scales)
    end

    it "is true when IOM and IORCM are enabled and ALMS is disabled" do
      expect(individual_outcome_rating_and_calculation_enabled?(@outcome.context)).to eq true
    end

    it "is false when improved outcomes management (IOM) is disabled" do
      @context.root_account.disable_feature!(:improved_outcomes_management)
      expect(individual_outcome_rating_and_calculation_enabled?(@outcome.context)).to eq false
    end

    it "is false when individual outcome rating and calculation (IORCM) is disabled" do
      @context.root_account.disable_feature!(:individual_outcome_rating_and_calculation)
      expect(individual_outcome_rating_and_calculation_enabled?(@outcome.context)).to eq false
    end

    it "is false when account level mastery scales (ALMS) is enabled" do
      @context.root_account.enable_feature!(:account_level_mastery_scales)
      expect(individual_outcome_rating_and_calculation_enabled?(@outcome.context)).to eq false
    end
  end
end
