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
    @domain_root_account = @account = Account.default
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

  it "updates learning outcome" do
    result = execute_with_input(variables)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateLearningOutcome", "errors")).to be_nil
    result = result.dig("data", "updateLearningOutcome", "learningOutcome")
    expect(result["title"]).to eq "Outcome 1 edited"
    expect(result["displayName"]).to eq "Outcome display name 1"
    expect(result["description"]).to eq "Outcome description 1"
    expect(result["vendorGuid"]).to eq "vg--1"
  end

  context "account_level_mastery_scales feature flag disabled" do
    def expect_result(rating_vars, calculation_method, calculation_int, mastery_points, ratings)
      result = execute_with_input "#{variables},#{rating_vars}"
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateLearningOutcome", "errors")).to be_nil

      result = result.dig("data", "updateLearningOutcome", "learningOutcome")
      result_record = LearningOutcome.find(record.id)

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

    before do
      @domain_root_account.disable_feature!(:account_level_mastery_scales)
    end

    it "updates individual ratings and calculation method for learning outcome" do
      calculation_method = default_rating_variables[:calculation_method]
      calculation_int = default_rating_variables[:calculation_int]
      mastery_points = default_rating_variables[:mastery_points]
      ratings = default_rating_variables[:ratings]

      expect_result(rating_variables, calculation_method, calculation_int, mastery_points, ratings)
    end

    it "updates individual calculation method for learning outcome" do
      rating_variables_calculation_only = <<~GQL
        calculationMethod: "#{default_rating_variables[:calculation_method]}",
        calculationInt: #{default_rating_variables[:calculation_int]},
      GQL
      calculation_method = default_rating_variables[:calculation_method]
      calculation_int = default_rating_variables[:calculation_int]
      mastery_points = record.data[:rubric_criterion][:mastery_points]
      ratings = record.data[:rubric_criterion][:ratings]

      expect_result(rating_variables_calculation_only, calculation_method, calculation_int, mastery_points, ratings)
    end

    it "updates individual ratings for learning outcome" do
      rating_variables_ratings_only = <<~GQL
        masteryPoints: #{default_rating_variables[:mastery_points]},
        ratings: #{
          default_rating_variables[:ratings]
            .to_json
            .gsub(/"([a-z]+)":/, '\1:')
        }
      GQL
      calculation_method = record[:calculation_method]
      calculation_int = record[:calculation_int]
      mastery_points = default_rating_variables[:mastery_points]
      ratings = default_rating_variables[:ratings]

      expect_result(rating_variables_ratings_only, calculation_method, calculation_int, mastery_points, ratings)
    end

    it "updates individual mastery points independent of ratings for learning outcome" do
      rating_variables_mastery_points_only = <<~GQL
        masteryPoints: #{default_rating_variables[:mastery_points]}
      GQL
      calculation_method = record[:calculation_method]
      calculation_int = record[:calculation_int]
      mastery_points = default_rating_variables[:mastery_points]
      ratings = record.data[:rubric_criterion][:ratings]

      expect_result(rating_variables_mastery_points_only, calculation_method, calculation_int, mastery_points, ratings)
    end

    it "updates individual mastery points dependent on ratings if no mastery points provided for learning outcome" do
      rating_variables_without_mastery_points = <<~GQL
        ratings: #{
          default_rating_variables[:ratings]
            .to_json
            .gsub(/"([a-z]+)":/, '\1:')
        }
      GQL
      calculation_method = record[:calculation_method]
      calculation_int = record[:calculation_int]
      mastery_points = default_rating_variables[:ratings][0][:points]
      ratings = default_rating_variables[:ratings]

      expect_result(rating_variables_without_mastery_points, calculation_method, calculation_int, mastery_points, ratings)
    end

    it "updates individual ratings independent of mastery points for learning outcome" do
      rating_variables_ratings_only = <<~GQL
        ratings: #{
          default_rating_variables[:ratings]
            .to_json
            .gsub(/"([a-z]+)":/, '\1:')
        }
      GQL
      calculation_method = record[:calculation_method]
      calculation_int = record[:calculation_int]
      mastery_points = record.data[:rubric_criterion][:mastery_points]
      ratings = default_rating_variables[:ratings]

      expect_result(rating_variables_ratings_only, calculation_method, calculation_int, mastery_points, ratings)
    end
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

    it "raises error when data includes individual ratings with account_level_mastery_scales FF enabled" do
      @course.root_account.enable_feature!(:account_level_mastery_scales)

      result = execute_with_input "#{variables},#{rating_variables}"
      expect_error(result, "individual ratings data input with acount_level_mastery_scale FF enabled")
    end
  end
end
