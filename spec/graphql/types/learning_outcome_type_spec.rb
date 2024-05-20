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

require_relative "../graphql_spec_helper"

describe Types::LearningOutcomeType do
  before(:once) do
    account_admin_user
    @account_user = Account.default.account_users.first
    @domain_root_account = Account.default

    outcome_with_individual_ratings(context: Account.default)
  end

  let(:outcome_type) { GraphQLTypeTester.new(@outcome, { current_user: @admin, domain_root_account: @domain_root_account }) }

  let(:outcome_type_raw) do
    outcome_type_raw = GraphQLTypeTester.new(@outcome, { current_user: @admin, domain_root_account: @domain_root_account })
    outcome_type_raw.extract_result = false
    outcome_type_raw
  end

  context "Account Level Mastery Scales Feature Flag" do
    it "returns outcome with individual ratings and calculation method if FF disabled" do
      @domain_root_account.disable_feature! :account_level_mastery_scales
      expect(outcome_type.resolve("_id")).to eq @outcome.id.to_s
      expect(outcome_type.resolve("contextId")).to eq @outcome.context_id.to_s
      expect(outcome_type.resolve("contextType")).to eq @outcome.context_type
      expect(outcome_type.resolve("title")).to eq @outcome.title
      expect(outcome_type.resolve("description")).to eq @outcome.description
      expect(outcome_type.resolve("assessed")).to eq @outcome.assessed?
      expect(outcome_type.resolve("displayName")).to eq @outcome.display_name
      expect(outcome_type.resolve("vendorGuid")).to eq @outcome.vendor_guid
      expect(outcome_type.resolve("calculationMethod")).to eq @outcome.calculation_method
      expect(outcome_type.resolve("calculationMethod")).not_to be_nil
      expect(outcome_type.resolve("calculationInt")).to eq @outcome.calculation_int
      expect(outcome_type.resolve("pointsPossible")).to eq @outcome.points_possible
      expect(outcome_type.resolve("masteryPoints")).to eq @outcome.rubric_criterion[:mastery_points]

      raw = outcome_type_raw.resolve("ratings { description points }")
      expect(raw["ratings"].map(&:symbolize_keys)).to eq @outcome.rubric_criterion[:ratings]

      expect(outcome_type.resolve("canEdit")).to be true
    end

    it "returns outcome without individual ratings and calculation method if FF enabled" do
      @domain_root_account.enable_feature! :account_level_mastery_scales

      expect(outcome_type.resolve("calculationMethod")).to be_nil
      expect(outcome_type.resolve("calculationInt")).to be_nil
      expect(outcome_type.resolve("pointsPossible")).to be_nil
      expect(outcome_type.resolve("masteryPoints")).to be_nil
      expect(outcome_type.resolve("ratings { points }")).to be_nil
    end
  end

  context "without edit permission" do
    before(:once) do
      RoleOverride.manage_role_override(@account_user.account, @account_user.role, "manage_outcomes", override: false)
    end

    it "returns canEdit false" do
      expect(outcome_type.resolve("canEdit")).to be false
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
      expect(outcome_type.resolve("assessed")).to be false
    end

    it "returns true when assessed" do
      rubric_assessment_model(rubric: @rubric, user: @student)
      expect(outcome_type.resolve("assessed")).to be true
    end

    it "returns false when assessment deleted" do
      assessment = rubric_assessment_model(rubric: @rubric, user: @student)
      assessment.learning_outcome_results.destroy_all
      expect(outcome_type.resolve("assessed")).to be false
    end
  end

  context "imported" do
    let(:course) { Course.create! }
    let(:root_group) { course.root_outcome_group }

    it "returns false when not imported" do
      expect(outcome_type.resolve("isImported(targetContextType: \"Course\", targetContextId: #{course.id})"))
        .to be false
    end

    it "returns true when imported" do
      root_group.add_outcome(@outcome)
      expect(outcome_type.resolve("isImported(targetContextType: \"Course\", targetContextId: #{course.id})"))
        .to be true
    end
  end

  context "friendlyDescription" do
    let(:course) { Course.create! }

    it "resolves friendly description correctly" do
      Account.site_admin.enable_feature!(:outcomes_friendly_description)
      course.account.enable_feature!(:improved_outcomes_management)

      course_fd = OutcomeFriendlyDescription.create!({
                                                       learning_outcome: @outcome,
                                                       context: course,
                                                       description: "course's description"
                                                     })

      expect(outcome_type.resolve("friendlyDescription(contextType: \"Course\", contextId: #{course.id}) { _id }"))
        .to eq course_fd.id.to_s
    end
  end

  describe "alignments" do
    before do
      course_model
      course_with_student(course: @course)
      assignment1 = assignment_model({ course: @course, name: "First Assignment" })
      assignment2 = assignment_model({ course: @course, name: "Second Assignment" })
      assignment3 = assignment_model({ course: @course, name: "Third Assignment" })
      @course_outcome = outcome_model(context: @course, title: "course outcome")
      @global_outcome = outcome_model(global: true, title: "global outcome")
      @course_outcome_group = @course.root_outcome_group
      @course_outcome_group.add_outcome @global_outcome
      @course_outcome_group.save!
      @alignment1 = @course_outcome.align(assignment1, @course)
      @alignment2 = @course_outcome.align(assignment2, @course)
      @alignment3 = @global_outcome.align(assignment3, @course)
      @alignment1_id = ["D", @alignment1.id].join("_")
      @alignment2_id = ["D", @alignment2.id].join("_")
      @alignment3_id = ["D", @alignment3.id].join("_")
      @course.account.enable_feature!(:improved_outcomes_management)
    end

    context "for users with Admin role" do
      it "resolves alignments for course outcomes" do
        outcome_type = GraphQLTypeTester.new(@course_outcome, { current_user: @admin })
        alignment_ids = outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")
        expect(alignment_ids.length).to eq 2
        expect(alignment_ids).to include(@alignment1_id, @alignment2_id)
      end

      it "resolves alignments for global outcomes added to course" do
        outcome_type = GraphQLTypeTester.new(@global_outcome, { current_user: @admin })
        alignment_ids = outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")
        expect(alignment_ids.length).to eq 1
        expect(alignment_ids).to include(@alignment3_id)
      end
    end

    context "for users with Teacher role" do
      it "resolves alignments for course outcomes" do
        outcome_type = GraphQLTypeTester.new(@course_outcome, { current_user: @teacher })
        alignment_ids = outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")
        expect(alignment_ids.length).to eq 2
        expect(alignment_ids).to include(@alignment1_id, @alignment2_id)
      end

      it "resolves alignments for global outcomes added to course" do
        outcome_type = GraphQLTypeTester.new(@global_outcome, { current_user: @teacher })
        alignment_ids = outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")
        expect(alignment_ids.length).to eq 1
        expect(alignment_ids).to include(@alignment3_id)
      end
    end

    context "for users with Student role" do
      it "does not resolve alignments for course outcomes" do
        outcome_type = GraphQLTypeTester.new(@outcome, { current_user: @student })
        expect(outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")).to be_nil
      end

      it "does not resolve alignments for global outcomes added to course" do
        outcome_type = GraphQLTypeTester.new(@global_outcome, { current_user: @student })
        expect(outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")).to be_nil
      end
    end

    it "does not resolve alignments for invalid context type" do
      outcome_type = GraphQLTypeTester.new(@course_outcome, { current_user: @admin })
      expect(outcome_type.resolve("alignments(contextType: \"Invalid\", contextId: #{@course.id}) { _id }")).to be_nil
    end

    it "does not resolve alignments for invalid context id" do
      outcome_type = GraphQLTypeTester.new(@course_outcome, { current_user: @admin })
      expect(outcome_type.resolve("alignments(contextType: \"Course\", contextId: 999999) { _id }")).to be_nil
    end
  end

  context "canArchive" do
    let(:course) { Course.create! }

    it "returns true if outcome was created in the same context" do
      expect(outcome_type.resolve("canArchive(contextType: \"Account\", contextId: #{Account.default.id})"))
        .to be true
    end

    it "return false if outcome was created in a different context" do
      expect(outcome_type.resolve("canArchive(contextType: \"Course\", contextId: #{course.id})"))
        .to be false
    end
  end
end
