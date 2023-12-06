# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::AccountType do
  before(:once) do
    teacher_in_course(active_all: true)
    student_in_course(active_all: false)
    account_admin_user
    @sub_account = account_model parent_account: @course.root_account
  end

  let(:account) { @course.root_account }
  let(:account_type) { GraphQLTypeTester.new(account, current_user: @teacher) }

  it "works" do
    expect(account_type.resolve(:name)).to eq account.name
    expect(account_type.resolve(:_id)).to eq account.id.to_s
  end

  it "requires read permission" do
    expect(account_type.resolve(:name, current_user: @student)).to be_nil
  end

  it "works for field outcome_proficiency" do
    outcome_proficiency_model(account)
    expect(account_type.resolve("outcomeProficiency { _id }")).to eq account.outcome_proficiency.id.to_s
  end

  it "works for field proficiency_ratings_connection" do
    outcome_proficiency_model(account)
    expect(
      account_type.resolve("proficiencyRatingsConnection { nodes { _id } }").sort
    ).to eq OutcomeProficiencyRating.all.map { |r| r.id.to_s }.sort
  end

  context "outcome_calculation_method field" do
    it "works" do
      outcome_calculation_method_model(account)
      expect(
        account_type.resolve("outcomeCalculationMethod { _id }")
      ).to eq account.outcome_calculation_method.id.to_s
    end
  end

  it "works for courses" do
    expect(account_type.resolve("coursesConnection { nodes { _id } }", current_user: @admin)).to eq [@course.id.to_s]
  end

  it "requires read_course_list permission" do
    expect(account_type.resolve("coursesConnection { nodes { _id } }", current_user: @teacher)).to be_nil
  end

  it "works for subaccounts" do
    expect(account_type.resolve("subAccountsConnection { nodes { _id } }")).to eq [@sub_account.id.to_s]
  end

  it "works for root_outcome_group" do
    expect(account_type.resolve("rootOutcomeGroup { _id }")).to eq account.root_outcome_group.id.to_s
  end

  context "parent_accounts_connection field" do
    it "works" do
      account_type = GraphQLTypeTester.new(@sub_account, current_user: @admin)
      expect(account_type.resolve("parentAccountsConnection { nodes { _id } }")).to eq [account.id.to_s]
    end
  end

  context "sis field" do
    before(:once) do
      @sub_account.update!(sis_source_id: "sisAccount")
    end

    let(:manage_admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false }) }
    let(:read_admin) { account_admin_user_with_role_changes(role_changes: { manage_sis: false }) }

    it "returns sis_id if you have read_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: read_admin }).dig("data", "account", "sisId")
          query { account(id: "#{@sub_account.id}") { sisId } }
        GQL
      ).to eq("sisAccount")
    end

    it "returns sis_id if you have manage_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: manage_admin }).dig("data", "account", "sisId")
          query { account(id: "#{@sub_account.id}") { sisId } }
        GQL
      ).to eq("sisAccount")
    end

    it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: @student }).dig("data", "account", "sisId")
          query { account(id: "#{@sub_account.id}") { sisId } }
        GQL
      ).to be_nil
    end
  end

  context "custom gradebook statuses feature flag" do
    before(:once) do
      CustomGradeStatus.create!(name: "status", color: "#000000", root_account: @course.root_account, created_by: @teacher)
      StandardGradeStatus.create!(status_name: "missing", root_account: @course.root_account, color: "#000000")
    end

    let(:account_type) { GraphQLTypeTester.new(account, current_user: @admin) }

    it "works for custom grade statuses connection" do
      expect(
        account_type.resolve("customGradeStatusesConnection { nodes { _id } }").sort
      ).to eq CustomGradeStatus.all.map { |r| r.id.to_s }.sort
      expect(account_type.resolve("customGradeStatusesConnection { nodes { name } }")).to eq ["status"]
    end

    it "works for standard grade statuses connection" do
      expect(
        account_type.resolve("standardGradeStatusesConnection { nodes { _id } }").sort
      ).to eq StandardGradeStatus.all.map { |r| r.id.to_s }.sort
      expect(account_type.resolve("standardGradeStatusesConnection { nodes { name } }")).to eq ["missing"]
    end

    it "doesn't work when feature flag is disabled" do
      Account.site_admin.disable_feature!(:custom_gradebook_statuses)
      expect(account_type.resolve("customGradeStatusesConnection { nodes { _id } }")).to be_nil
      expect(account_type.resolve("standardGradeStatusesConnection { nodes { _id } }")).to be_nil
    end
  end

  describe "RubricsConnection" do
    before(:once) do
      @rubric = Rubric.create!(context: account)
      rubric_association_model(context: account, rubric: @rubric, association_object: account, purpose: "bookmark")
    end

    it "returns rubrics" do
      expect(
        account_type.resolve("rubricsConnection { edges { node { _id } } }")
      ).to eq [account.rubrics.first.to_param]

      expect(
        account_type.resolve("rubricsConnection { edges { node { criteriaCount } } }")
      ).to eq [0]

      expect(
        account_type.resolve("rubricsConnection { edges { node { workflowState } } }")
      ).to eq ["active"]
    end
  end
end
