# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe Types::LearningOutcomeGroupType do
  before(:once) do
    account_admin_user
    @account_user = Account.default.account_users.first
    @parent_group = outcome_group_model(context: Account.default)
    @child_group = outcome_group_model(context: Account.default)
    @child_group3 = outcome_group_model(context: Account.default)
    @child_group2 = outcome_group_model(context: Account.default, workflow_state: "deleted")
    outcome_group_model(context: Account.default, vendor_guid: "vendor_guid")
    @outcome_group.learning_outcome_group = @parent_group
    @outcome_group.save!
    @child_group.learning_outcome_group = @outcome_group
    @child_group.save!
    @child_group2.learning_outcome_group = @outcome_group
    @child_group2.save
    @child_group3.learning_outcome_group = @outcome_group
    @child_group3.save!
    @user = @admin
    @outcome1 = outcome_model(context: Account.default, outcome_group: @outcome_group, short_description: "BBBB")
    @outcome2 = outcome_model(context: Account.default, outcome_group: @outcome_group, short_description: "AAAA")
    Account.default.enable_feature! :improved_outcomes_management
  end

  let(:outcome_group_type) { GraphQLTypeTester.new(@outcome_group, current_user: @user) }

  it "works" do
    expect(outcome_group_type.resolve("_id")).to eq @outcome_group.id.to_s
    expect(outcome_group_type.resolve("title")).to eq @outcome_group.title
    expect(outcome_group_type.resolve("description")).to eq @outcome_group.description
    expect(outcome_group_type.resolve("contextId")).to eq @outcome_group.context_id.to_s
    expect(outcome_group_type.resolve("contextType")).to eq @outcome_group.context_type
    expect(outcome_group_type.resolve("vendorGuid")).to eq @outcome_group.vendor_guid
    expect(outcome_group_type.resolve("childGroupsCount")).to eq 2
    expect(outcome_group_type.resolve("outcomesCount")).to be_a Integer
    expect(outcome_group_type.resolve("notImportedOutcomesCount")).to be_nil
    expect(outcome_group_type.resolve("parentOutcomeGroup { _id }")).to eq @parent_group.id.to_s
    expect(outcome_group_type.resolve("canEdit")).to be true
    expect(outcome_group_type.resolve("childGroups { nodes { _id } }"))
      .to match_array([@child_group.id.to_s, @child_group3.id.to_s])
  end

  it "gets outcomes ordered by title" do
    expect(outcome_group_type.resolve("outcomes { nodes { ... on LearningOutcome { _id } } }")).to match_array([
                                                                                                                 @outcome2.id.to_s, @outcome1.id.to_s
                                                                                                               ])
  end

  it "accepts search_query in outcomes" do
    expect(outcome_group_type.resolve("outcomes(searchQuery: \"BBBB\") { nodes { ... on LearningOutcome { _id } } }")).to match_array([
                                                                                                                                        @outcome1.id.to_s
                                                                                                                                      ])
  end

  describe "within course context" do
    before do
      @course1 = Course.create!
      @course_outcome1 = outcome_model(context: @course1, short_description: "CCC")
      @course_outcome2 = outcome_model(context: @course1, short_description: "DDD")
      @course_outcome2.align(assignment_model, @course1)
      @course1.account.enable_feature!(:improved_outcomes_management)
    end

    let(:course_outcome_group_type) { GraphQLTypeTester.new(@course1.root_outcome_group, current_user: @admin) }

    it "accepts filter in outcomes" do
      expect(course_outcome_group_type.resolve("outcomes(filter: \"WITH_ALIGNMENTS\") { nodes { ... on LearningOutcome { _id } } }")).to match_array([
                                                                                                                                                       @course_outcome2.id.to_s
                                                                                                                                                     ])
    end

    it "accepts both search_query and filter in outcomes" do
      @course_outcome1.align(assignment_model, @course1)
      expect(course_outcome_group_type.resolve("outcomes(filter: \"WITH_ALIGNMENTS\", searchQuery: \"CCC\") { nodes { ... on LearningOutcome { _id } } }")).to match_array([
                                                                                                                                                                             @course_outcome1.id.to_s
                                                                                                                                                                           ])
    end
  end

  it "returns isImported for a given context" do
    course = Course.create!
    root_group = course.root_outcome_group

    query = <<~GQL
      outcomes {
        nodes {
          ... on LearningOutcome {
            isImported(targetContextType: "Course", targetContextId: #{course.id})
          }
        }
      }
    GQL

    expect(outcome_group_type.resolve(query)).to match_array([
                                                               false, false
                                                             ])

    root_group.add_outcome(@outcome2)

    expect(outcome_group_type.resolve(query)).to match_array([
                                                               true, false
                                                             ])
  end

  context "when doesn't have edit permission" do
    before(:once) do
      RoleOverride.manage_role_override(@account_user.account, @account_user.role, "manage_outcomes", override: false)
    end

    it "returns false for canEdit" do
      expect(outcome_group_type.resolve("canEdit")).to be false
    end

    it "returns false for canUnlink on the outcome edge" do
      expect(outcome_group_type.resolve("outcomes { edges { canUnlink } }")).to match_array([
                                                                                              false, false
                                                                                            ])
    end
  end

  context "when doesn't have context permission" do
    before(:once) do
      user_model
    end

    it "returns" do
      expect(outcome_group_type.resolve("_id")).to be_nil
    end
  end

  context "when outcome_group doesn't have context" do
    before(:once) do
      @outcome_group.context = nil
      @outcome_group.learning_outcome_group = nil
      @outcome_group.save
      user_model
    end

    it "returns outcome group" do
      expect(outcome_group_type.resolve("_id")).to eql @outcome_group.id.to_s
    end

    context "user not logged" do
      before(:once) do
        @user = nil
      end

      it "returns nil" do
        expect(outcome_group_type.resolve("_id")).to be_nil
      end
    end
  end

  describe "#child_groups_count" do
    it "returns the total active outcome groups" do
      expect(outcome_group_type.resolve("childGroupsCount")).to eq 2
      @child_group.destroy
      expect(outcome_group_type.resolve("childGroupsCount")).to eq 1
    end
  end

  describe "#outcomes_count" do
    it "returns the total outcomes at the nested outcome groups" do
      expect(outcome_group_type.resolve("outcomesCount")).to eq 2
    end

    it "accepts search_query in outcomes_count" do
      expect(outcome_group_type.resolve("outcomesCount(searchQuery: \"BBBB\")")).to eq 1
    end
  end

  describe "#not_imported_outcomes_count" do
    before(:once) do
      @course = course_model name: "course", account: @account, workflow_state: "created"
      @parent_course_group = @course.learning_outcome_groups.create!(title: "parent course group")
      @child_course_group1 = @course.learning_outcome_groups.create!(title: "child course group level 1")
      @child_course_group2 = @course.learning_outcome_groups.create!(title: "child course group level 2")
      @child_course_group1.learning_outcome_group = @parent_course_group
      @child_course_group1.save!
      @child_course_group2.learning_outcome_group = @child_course_group1
      @child_course_group2.save!
      @child_course_group1.add_outcome @outcome1
      @child_course_group2.add_outcome @outcome2
    end

    it "returns the number of not imported outcomes in the targetGroupId" do
      expect(outcome_group_type.resolve("notImportedOutcomesCount(targetGroupId: #{@child_course_group1.id})")).to eq 0
      expect(outcome_group_type.resolve("notImportedOutcomesCount(targetGroupId: #{@child_course_group2.id})")).to eq 1
    end

    it "returns nil if no targetGroupId provided" do
      expect(outcome_group_type.resolve("notImportedOutcomesCount")).to be_nil
    end
  end

  describe "content tag links" do
    it "canUnlink returns false if there are outcome alignments" do
      @rubric = Rubric.new(context: Account.default)
      @rubric.data = [
        {
          points: 3,
          description: "Rubric with outcome",
          id: 1,
          data: [],
          learning_outcome_id: @outcome1.id
        }
      ]
      @rubric.save!
      expect(outcome_group_type.resolve("outcomes { edges { canUnlink } }")).to match_array([
                                                                                              true, false
                                                                                            ])
    end
  end

  describe "global outcomes" do
    before do
      @global_group = LearningOutcomeGroup.find_or_create_root(nil, true)
      outcome_model(outcome_group: @global_group)
    end

    let(:outcome_group_type) { GraphQLTypeTester.new(@global_group, current_user: @user) }

    describe "without manage_global_outcomes permission" do
      before do
        account_admin_user_with_role_changes(
          account: Account.site_admin,
          role_changes: { manage_global_outcomes: false }
        )
      end

      it "canUnlink returns false" do
        expect(outcome_group_type.resolve("outcomes { edges { canUnlink } }")).to match_array([
                                                                                                false
                                                                                              ])
      end
    end

    describe "with manage_global_outcomes permission" do
      before do
        account_admin_user_with_role_changes(
          account: Account.site_admin,
          role_changes: { manage_global_outcomes: true }
        )
      end

      it "canUnlink returns true" do
        expect(outcome_group_type.resolve("outcomes { edges { canUnlink } }")).to match_array([
                                                                                                true
                                                                                              ])
      end
    end
  end

  describe "group" do
    it "returns parent group of an outcome" do
      expect(outcome_group_type.resolve("outcomes { edges { group { _id } } }")).to match_array([
                                                                                                  @outcome_group.id.to_s, @outcome_group.id.to_s
                                                                                                ])
    end
  end
end
