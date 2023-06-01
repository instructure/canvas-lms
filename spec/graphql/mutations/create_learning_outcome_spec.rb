# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::CreateLearningOutcome do
  before :once do
    @domain_root_account = @account = Account.default
    @course = @account.courses.create!
    @global_group = LearningOutcomeGroup.global_root_outcome_group
    @course_group = @course.learning_outcome_groups.create!(title: "Group Course Level")
    @site_admin = site_admin_user
    @admin = account_admin_user(account: @account)
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
  end

  def execute_with_input(create_input, user_executing: @teacher)
    mutation_command = <<~GQL
      mutation{
        createLearningOutcome(input: {
          #{create_input}
          }) {
          learningOutcome {
            _id
            id
            title
            displayName
            description
            vendorGuid
            contextType
            contextId
            calculationMethod
            calculationInt
            masteryPoints
            ratings {
              description
              points
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, domain_root_account: @domain_root_account, request: ActionDispatch::TestRequest.create, session: {} }
    CanvasSchema.execute(mutation_command, context:)
  end

  def variables(args = {})
    <<~YAML
      groupId: #{args[:group_id] || @course_group.id},
      title: "#{args[:title] || "Spec Learning Outcome via Mutation"}"
    YAML
  end

  def default_rating_variables
    {
      calculation_method: "n_mastery",
      calculation_int: 3,
      mastery_points: 2,
      ratings: [
        {
          description: "GraphQL Exceeds Expectations",
          points: 3
        },
        {
          description: "GraphQL Expectations",
          points: 2
        },
        {
          description: "GraphQL Does Not Meet Expectations",
          points: 1
        }
      ]
    }
  end

  def rating_variables(args = {})
    args.merge!(default_rating_variables)

    <<~GQL
      calculationMethod: "#{args[:calculation_method]}",
      calculationInt: #{args[:calculation_int]},
      masteryPoints: #{args[:mastery_points]},
      ratings: #{
        args[:ratings]
          .to_json
          .gsub(/"([a-z]+)":/, '\1:')
      }
    GQL
  end

  it "creates a learning outcome" do
    result = execute_with_input(variables)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createLearningOutcome", "errors")).to be_nil
    result = result.dig("data", "createLearningOutcome", "learningOutcome")
    record = LearningOutcome.find(result["_id"])
    expect(result["contextType"]).to eq "Course"
    expect(result["contextId"]).to eq @course.id.to_s
    expect(result["title"]).to eq "Spec Learning Outcome via Mutation"
    expect(result["description"]).to be_nil
    expect(result["vendorGuid"]).to be_nil
    expect(result["displayName"]).to be_nil
    expect(record.title).to eq "Spec Learning Outcome via Mutation"
    expect(record.description).to be_nil
    expect(record.vendor_guid).to be_nil
    expect(record.display_name).to be_nil
    expect(record.context).to eq @course
  end

  it "creates a learning outcome with individual ratings and calculation method" do
    @domain_root_account.disable_feature!(:account_level_mastery_scales)

    calculation_method = default_rating_variables[:calculation_method]
    calculation_int = default_rating_variables[:calculation_int]
    mastery_points = default_rating_variables[:mastery_points]
    ratings = default_rating_variables[:ratings]

    result = execute_with_input "#{variables},#{rating_variables}"
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createLearningOutcome", "errors")).to be_nil

    result = result.dig("data", "createLearningOutcome", "learningOutcome")
    result_record = LearningOutcome.find(result["_id"])

    expect(result["calculationMethod"]).to eq calculation_method
    expect(result["calculationInt"]).to eq calculation_int
    expect(result["masteryPoints"]).to eq mastery_points
    expect(result["ratings"].count).to eq ratings.count
    expect(result["ratings"][0]["description"]).to eq ratings[0][:description]

    expect(result_record.calculation_method).to eq calculation_method
    expect(result_record.calculation_int).to eq calculation_int
    expect(result_record.mastery_points).to eq mastery_points
    expect(result_record.rubric_criterion[:ratings].count).to eq ratings.count
    expect(result_record.rubric_criterion[:ratings][0][:description]).to eq ratings[0][:description]
  end

  it "creates a global outcome" do
    query = <<~GQL
      groupId: #{@global_group.id}
      title: "Spec Learning Outcome via Mutation"
    GQL
    result = execute_with_input(query, user_executing: @site_admin)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createLearningOutcome", "errors")).to be_nil
    result = result.dig("data", "createLearningOutcome", "learningOutcome")
    record = LearningOutcome.find(result["_id"])
    expect(result["contextType"]).to be_nil
    expect(result["contextId"]).to be_nil
    expect(result["title"]).to eq "Spec Learning Outcome via Mutation"
    expect(result["description"]).to be_nil
    expect(result["vendorGuid"]).to be_nil
    expect(result["displayName"]).to be_nil
    expect(record.title).to eq "Spec Learning Outcome via Mutation"
    expect(record.description).to be_nil
    expect(record.vendor_guid).to be_nil
    expect(record.display_name).to be_nil
    expect(record.context).to be_nil
  end

  context "creates non required fields if supplied for" do
    it "display_name, vendor_guid, description" do
      query = <<~GQL
        groupId: #{@course_group.id}
        title: "Spec Learning Outcome via Mutation"
        displayName: "Display name for spec"
        vendorGuid: "ven_guid_1"
        description: "Learning Outcome via Mutation Description"
      GQL
      result = execute_with_input(query)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "createLearningOutcome", "errors")).to be_nil
      result = result.dig("data", "createLearningOutcome", "learningOutcome")
      record = LearningOutcome.find(result["_id"])
      expect(result["displayName"]).to eq "Display name for spec"
      expect(record.display_name).to eq "Display name for spec"
      expect(result["vendorGuid"]).to eq "ven_guid_1"
      expect(record.vendor_guid).to eq "ven_guid_1"
      expect(result["description"]).to eq "Learning Outcome via Mutation Description"
      expect(record.description).to eq "Learning Outcome via Mutation Description"
    end
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createLearningOutcome", "errors")
      expect(errors).not_to be_nil
      expect(errors.first["message"]).to include message
    end

    it "group id is required" do
      query = <<~GQL
        title: "Spec Learning Outcome via Mutation"
      GQL
      result = execute_with_input(query)
      expect_error(result, "Argument 'groupId' on InputObject 'CreateLearningOutcomeInput' is required.")
    end

    it "raises error when data includes individual ratings with account_level_mastery_scales FF enabled" do
      @course.root_account.enable_feature!(:account_level_mastery_scales)

      result = execute_with_input "#{variables},#{rating_variables}"
      expect_error(result, "individual ratings data input with acount_level_mastery_scale FF enabled")
    end

    it "non-global outcomes require manage_outcome permission" do
      query = <<~GQL
        groupId: #{@course_group.id}
        title: "Spec Learning Outcome via Mutation"
      GQL
      result = execute_with_input(query, user_executing: @student)
      expect_error(result, "insufficient permission")
    end

    it "global outcomes require manage_global_outcome permission" do
      query = <<~GQL
        groupId: #{@global_group.id}
        title: "Spec Learning Outcome via Mutation"
      GQL
      result = execute_with_input(query, user_executing: @admin)
      expect_error(result, "insufficient permission")
    end

    it "invalid group id" do
      query = <<~GQL
        groupId: 0
        title: "Spec Learning Outcome via Mutation"
      GQL
      result = execute_with_input(query)
      expect_error(result, "group not found")
    end

    it "deleted group" do
      another_group = @course.learning_outcome_groups.create!(title: "Delete me")
      another_group.delete
      query = <<~GQL
        groupId: #{another_group.id}
        title: "Spec Learning Outcome via Mutation"
      GQL
      result = execute_with_input(query)
      expect_error(result, "group not found")
    end

    it "title is required" do
      query = <<~GQL
        groupId: #{@course_group.id}
      GQL
      result = execute_with_input(query)
      expect_error(result, "Argument 'title' on InputObject 'CreateLearningOutcomeInput' is required.")
    end
  end

  context "transactions" do
    it "rolls back outcome creation if linking to group fails" do
      expect_any_instance_of(LearningOutcomeGroup).to receive(:add_outcome).and_raise("Boom!")
      query = <<~GQL
        groupId: #{@course_group.id}
        title: "Spec Learning Outcome via Mutation"
      GQL
      expect { execute_with_input(query) }.to raise_error("Boom!").and not_change(LearningOutcome, :count)
    end
  end
end
