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

  describe "OutcomesFeaturesHelper" do
    before :once do
      @account = Account.default
      @context = @course = @account.courses.create!
      @global_outcome = outcome_model(global: true, title: "Global outcome")
      @account_outcome = outcome_model(context: @account)
      @course_outcome = outcome_model(context: @course)
    end

    describe "#account_level_mastery_scales_enabled?" do
      before do
        @context.root_account.enable_feature!(:account_level_mastery_scales)
      end

      it "returns true when account_level_mastery_scales FF is enabled" do
        expect(account_level_mastery_scales_enabled?(@course_outcome.context)).to be true
      end

      it "returns false when account_level_mastery_scales FF is disabled" do
        @context.root_account.disable_feature!(:account_level_mastery_scales)
        expect(account_level_mastery_scales_enabled?(@course_outcome.context)).to be false
      end

      it "returns FF status with Course context as argument" do
        expect(account_level_mastery_scales_enabled?(@course_outcome.context)).to be true
        @context.root_account.disable_feature!(:account_level_mastery_scales)
        expect(account_level_mastery_scales_enabled?(@course_outcome.context)).to be false
      end

      it "returns FF status with Account context as argument" do
        expect(account_level_mastery_scales_enabled?(@account_outcome.context)).to be true
        @context.root_account.disable_feature!(:account_level_mastery_scales)
        expect(account_level_mastery_scales_enabled?(@account_outcome.context)).to be false
      end

      it "returns FF status with Global/nil context as argument" do
        expect(account_level_mastery_scales_enabled?(@global_outcome.context)).to be_nil
        @context.root_account.disable_feature!(:account_level_mastery_scales)
        expect(account_level_mastery_scales_enabled?(@global_outcome.context)).to be_nil
      end
    end

    describe "#improved_outcomes_management_enabled?" do
      before do
        @context.root_account.enable_feature!(:improved_outcomes_management)
      end

      it "returns true when improved_outcomes_management FF is enabled" do
        expect(improved_outcomes_management_enabled?(@course_outcome.context)).to be true
      end

      it "returns false when improved_outcomes_management FF is disabled" do
        @context.root_account.disable_feature!(:improved_outcomes_management)
        expect(improved_outcomes_management_enabled?(@course_outcome.context)).to be false
      end

      it "returns FF status with Course context as argument" do
        expect(improved_outcomes_management_enabled?(@course_outcome.context)).to be true
        @context.root_account.disable_feature!(:improved_outcomes_management)
        expect(improved_outcomes_management_enabled?(@course_outcome.context)).to be false
      end

      it "returns FF status with Account context as argument" do
        expect(improved_outcomes_management_enabled?(@account_outcome.context)).to be true
        @context.root_account.disable_feature!(:improved_outcomes_management)
        expect(improved_outcomes_management_enabled?(@account_outcome.context)).to be false
      end

      it "returns FF status with Global/nil context as argument" do
        expect(improved_outcomes_management_enabled?(@global_outcome.context)).to be_nil
        @context.root_account.disable_feature!(:improved_outcomes_management)
        expect(improved_outcomes_management_enabled?(@global_outcome.context)).to be_nil
      end
    end

    describe "#outcome_alignment_summary_with_new_quizzes_enabled?" do
      it "returns true when outcome_alignment_summary_with_new_quizzes FF is enabled" do
        @context.enable_feature!(:outcome_alignment_summary_with_new_quizzes)
        expect(outcome_alignment_summary_with_new_quizzes_enabled?(@course_outcome.context)).to be true
      end

      it "returns false when outcome_alignment_summary_with_new_quizzes FF is disabled" do
        @context.disable_feature!(:outcome_alignment_summary_with_new_quizzes)
        expect(outcome_alignment_summary_with_new_quizzes_enabled?(@course_outcome.context)).to be false
      end
    end
  end
end
