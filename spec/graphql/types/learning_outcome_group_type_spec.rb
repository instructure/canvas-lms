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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::LearningOutcomeGroupType do

  before(:once) do
    account_admin_user
    @account_user = Account.default.account_users.first
    @parent_group = outcome_group_model(context: Account.default)
    @child_group = outcome_group_model(context: Account.default)
    @child_group3 = outcome_group_model(context: Account.default)
    @child_group2 = outcome_group_model(context: Account.default, workflow_state: 'deleted')
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
    expect(outcome_group_type.resolve("contextId")).to eq @outcome_group.context_id
    expect(outcome_group_type.resolve("contextType")).to eq @outcome_group.context_type
    expect(outcome_group_type.resolve("vendorGuid")).to eq @outcome_group.vendor_guid
    expect(outcome_group_type.resolve("childGroupsCount")).to be_a Integer
    expect(outcome_group_type.resolve("outcomesCount")).to be_a Integer
    expect(outcome_group_type.resolve("parentOutcomeGroup { _id }")).to eq @parent_group.id.to_s
    expect(outcome_group_type.resolve("canEdit")).to eq true
    expect(outcome_group_type.resolve("childGroups { nodes { _id } }")).
      to match_array([@child_group.id.to_s, @child_group3.id.to_s])
  end

  it "gets outcomes ordered by title" do
    expect(outcome_group_type.resolve("outcomes { nodes { ... on LearningOutcome { _id } } }")).to match_array([
      @outcome2.id.to_s, @outcome1.id.to_s
    ])
  end

  context "when doesn't have edit permission" do
    before(:once) do
      RoleOverride.manage_role_override(@account_user.account, @account_user.role, "manage_outcomes", :override => false)
    end

    it "returns false for canEdit" do
      expect(outcome_group_type.resolve("canEdit")).to eq false
    end
  end

  context "when doesn't have context permission" do
    before(:once) do
      user_model
    end

    it "returns " do
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

  describe '#child_groups_count' do
    it 'returns the total nested outcome groups' do
      expect(outcome_group_type.resolve("childGroupsCount")).to eq 2
    end
  end

  describe '#outcomes_count' do
    it 'returns the total outcomes at the nested outcome groups' do
      expect(outcome_group_type.resolve("outcomesCount")).to eq 2
    end
  end
end
