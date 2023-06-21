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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::UpdateOutcomeCalculationMethod do
  before :once do
    @account = Account.default
    @course = @account.courses.create!
    @admin = account_admin_user(account: @account)
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
  end

  let!(:original_record) { outcome_calculation_method_model(@course) }

  def execute_with_input(update_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        updateOutcomeCalculationMethod(input: {
          #{update_input}
        }) {
          outcomeCalculationMethod {
            _id
            calculationInt
            contextId
            calculationMethod
            contextType
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, request: ActionDispatch::TestRequest.create, session: {} }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "updates an outcome calculation method" do
    query = <<~GQL
      id: #{original_record.id}
      calculationMethod: "highest"
      calculationInt: null
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateOutcomeCalculationMethod", "errors")).to be_nil
    result = result.dig("data", "updateOutcomeCalculationMethod", "outcomeCalculationMethod")
    record = OutcomeCalculationMethod.find(result["_id"])
    expect(result["contextType"]).to eq "Course"
    expect(result["contextId"]).to eq @course.id.to_s
    expect(result["calculationMethod"]).to eq "highest"
    expect(result["calculationInt"]).to be_nil
    expect(record.calculation_method).to eq "highest"
    expect(record.calculation_int).to be_nil
    expect(record.context).to eq @course
  end

  it "restores previously soft-deleted record" do
    original_record.destroy
    query = <<~GQL
      id: #{original_record.id}
      calculationMethod: "highest"
      calculationInt: null
    GQL
    result = execute_with_input(query)
    result = result.dig("data", "updateOutcomeCalculationMethod", "outcomeCalculationMethod")
    record = OutcomeCalculationMethod.find(result["_id"])
    expect(record.id).to eq original_record.id
    expect(record.calculation_method).to eq "highest"
    expect(record.calculation_int).to be_nil
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateOutcomeCalculationMethod", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "requires manage_proficiency_calculations permission" do
      query = <<~GQL
        id: #{original_record.id}
        calculationMethod: "highest"
      GQL
      result = execute_with_input(query, user_executing: @teacher)
      expect_error(result, "insufficient permission")
    end

    it "invalid calculation method" do
      query = <<~GQL
        id: #{original_record.id}
        calculationMethod: "foobaz"
      GQL
      result = execute_with_input(query)
      expect_error(result, "calculation_method must be one of")
    end

    it "invalid calculation int" do
      query = <<~GQL
        id: #{original_record.id}
        calculationMethod: "highest"
        calculationInt: 100
      GQL
      result = execute_with_input(query)
      expect_error(result, "invalid calculation_int for this calculation_method")
    end
  end
end
