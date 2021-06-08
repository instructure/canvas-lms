# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::LearningOutcomeType do
  before(:once) do
    account_admin_user
    @account_user = Account.default.account_users.first
    outcome_model(context: Account.default)
  end

  let(:outcome_type) { GraphQLTypeTester.new(@outcome, current_user: @admin) }

  it "works" do
    expect(outcome_type.resolve("_id")).to eq @outcome.id.to_s
    expect(outcome_type.resolve("contextId")).to eq @outcome.context_id
    expect(outcome_type.resolve("contextType")).to eq @outcome.context_type
    expect(outcome_type.resolve("title")).to eq @outcome.title
    expect(outcome_type.resolve("description")).to eq @outcome.description
    expect(outcome_type.resolve("assessed")).to eq @outcome.assessed?
    expect(outcome_type.resolve("displayName")).to eq @outcome.display_name
    expect(outcome_type.resolve("vendorGuid")).to eq @outcome.vendor_guid
    expect(outcome_type.resolve("canEdit")).to eq true
  end

  context "without edit permission" do
    before(:once) do
      RoleOverride.manage_role_override(@account_user.account, @account_user.role, "manage_outcomes", :override => false)
    end

    it "returns canEdit false" do
      expect(outcome_type.resolve("canEdit")).to eq false
    end
  end

  context "without read permission" do
    before(:once) do
      user_model
    end

    let(:outcome_type) { GraphQLTypeTester.new(@outcome, current_user: @user) }

    it "returns nil" do
      expect(outcome_type.resolve("_id")).to be_nil
    end
  end

  context "assessed" do
    before(:once) do
      outcome_with_rubric(outcome: @outcome, context: Account.default)
      course_with_student
    end

    it "returns false when not assessed" do
      expect(outcome_type.resolve("assessed")).to eq false
    end

    it "returns true when assessed" do
      rubric_assessment_model(rubric: @rubric, user: @student)
      expect(outcome_type.resolve("assessed")).to eq true
    end

    it "returns false when assessment deleted" do
      assessment = rubric_assessment_model(rubric: @rubric, user: @student)
      assessment.learning_outcome_results.destroy_all
      expect(outcome_type.resolve("assessed")).to eq false
    end
  end

  context "imported" do
    let(:course) { Course.create! }
    let(:root_group) { course.root_outcome_group }

    it "returns false when not imported" do
      expect(outcome_type.resolve("isImported(targetContextType: \"Course\", targetContextId: #{course.id})"))
        .to eq false
    end

    it "returns true when imported" do
      root_group.add_outcome(@outcome)
      expect(outcome_type.resolve("isImported(targetContextType: \"Course\", targetContextId: #{course.id})"))
        .to eq true
    end
  end
end
