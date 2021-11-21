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

describe Mutations::UpdateLearningOutcome do
  before :once do
    @account = Account.default
    @admin = account_admin_user(account: @account)
    course_with_student
  end

  let!(:record) { outcome_model(context: @course) }

  def variables(args = {})
    <<~YAML
      id: #{args[:id] || record.id},
      title: "#{args[:title] || "Outcome 1 edited"}",
      displayName: "#{args[:display_name] || "Outcome display name 1"}",
      description: "#{args[:description] || "Outcome description 1"}",
      vendorGuid: "#{args[:vendor_guid] || "vg--1"}"
    YAML
  end

  def default_rating_variables
    {
      calculation_method: "n_mastery",
      calculation_int: 3,
      rubric_criterion: {
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
    }
  end

  def rating_variables(args = {})
    args.merge!(default_rating_variables)

    <<~GQL
      calculationMethod: "#{args[:calculation_method]}",
      calculationInt: #{args[:calculation_int]},
      rubricCriterion: {
        masteryPoints: #{args[:rubric_criterion][:mastery_points]}
        ratings: #{
          args[:rubric_criterion][:ratings]
            .to_json
            .gsub(/"([a-z]+)":/, '\1:')
        }
      }
    GQL
  end

  def execute_with_input(update_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        updateLearningOutcome(
          input: {
            #{update_input}
          }
        ) {
          learningOutcome {
            _id
            title
            displayName
            description
            vendorGuid
            calculationMethod
            calculationInt
            rubricCriterion {
              masteryPoints
              ratings {
                description
                points
              }
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, request: ActionDispatch::TestRequest.create, session: {} }
    CanvasSchema.execute(mutation_command, context: context)
  end

  it "updates a learning outcome" do
    result = execute_with_input(variables)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateLearningOutcome", "errors")).to be_nil
    result = result.dig("data", "updateLearningOutcome", "learningOutcome")
    expect(result["title"]).to eq "Outcome 1 edited"
    expect(result["displayName"]).to eq "Outcome display name 1"
    expect(result["description"]).to eq "Outcome description 1"
    expect(result["vendorGuid"]).to eq "vg--1"
  end

  it "updates a learning outcome with mastery scale" do
    @course.root_account.enable_feature!(:individual_outcome_rating_and_calculation)
    @course.root_account.disable_feature!(:account_level_mastery_scales)

    calculation_method = default_rating_variables[:calculation_method]
    calculation_int = default_rating_variables[:calculation_int]
    rubric_criterion = default_rating_variables[:rubric_criterion]

    result = execute_with_input "#{variables},#{rating_variables}"
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateLearningOutcome", "errors")).to be_nil

    result = result.dig("data", "updateLearningOutcome", "learningOutcome")
    result_record = LearningOutcome.find(record.id)

    expect(result["calculationMethod"]).to eq calculation_method
    expect(result["calculationInt"]).to eq calculation_int
    expect(result["rubricCriterion"]["masteryPoints"]).to eq rubric_criterion[:mastery_points]
    expect(result["rubricCriterion"]["ratings"].count).to eq rubric_criterion[:ratings].count
    expect(result["rubricCriterion"]["ratings"][0]["description"]).to eq rubric_criterion[:ratings][0][:description]

    expect(result_record.calculation_method).to eq calculation_method
    expect(result_record.calculation_int).to eq calculation_int
    expect(result_record.mastery_points).to eq rubric_criterion[:mastery_points]
    expect(result_record.rubric_criterion[:ratings].count).to eq rubric_criterion[:ratings].count
    expect(result_record.rubric_criterion[:ratings][0][:description]).to eq rubric_criterion[:ratings][0][:description]
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateLearningOutcome", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(message)
    end

    it "requires outcome to exist" do
      result = execute_with_input(variables(id: 99_999))
      expect_error(result, "unable to find LearningOutcome")
    end

    it "requires update permission for teacher" do
      result = execute_with_input(variables, user_executing: @teacher)
      expect_error(result, "insufficient permissions")
    end

    it "requires update permission for student" do
      result = execute_with_input(variables, user_executing: @student)
      expect_error(result, "insufficient permissions")
    end

    it "requires title to be present" do
      result = execute_with_input(variables(title: ""))
      expect_error(result, "can't be blank")
    end

    it "raises error when data includes individual ratings with IORC FF disabled" do
      @course.root_account.disable_feature!(:individual_outcome_rating_and_calculation)
      @course.root_account.disable_feature!(:account_level_mastery_scales)

      result = execute_with_input "#{variables},#{rating_variables}"
      expect_error(result, "individual ratings data input with invidual_outcome_rating_and_calculation FF disabled")
    end

    it "raises error when data includes individual ratings with both IORC and ALMS FFs enabled" do
      @course.root_account.enable_feature!(:individual_outcome_rating_and_calculation)
      @course.root_account.enable_feature!(:account_level_mastery_scales)

      result = execute_with_input "#{variables},#{rating_variables}"
      expect_error(result, "individual ratings data input with acount_level_mastery_scale FF enabled")
    end
  end
end
