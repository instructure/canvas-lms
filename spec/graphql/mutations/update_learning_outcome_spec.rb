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
    <<~VARS
      id: #{args[:id] || record.id},
      title: "#{args[:title] || 'Outcome 1 edited'}",
      displayName: "#{args[:display_name] || 'Outcome display name 1'}",
      description: "#{args[:description] || 'Outcome description 1'}",
      vendorGuid: "#{args[:vendor_guid] || 'vg--1'}"
    VARS
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
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {current_user: user_executing, request: ActionDispatch::TestRequest.create, session: {}}
    CanvasSchema.execute(mutation_command, context: context)
  end

  it "updates a learning outcome" do
    result = execute_with_input(variables)
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'updateLearningOutcome', 'errors')).to be_nil
    result = result.dig('data', 'updateLearningOutcome', 'learningOutcome')
    expect(result['title']).to eq 'Outcome 1 edited'
    expect(result['displayName']).to eq 'Outcome display name 1'
    expect(result['description']).to eq 'Outcome description 1'
    expect(result['vendorGuid']).to eq 'vg--1'
  end

  context 'errors' do
    def expect_error(result, message)
      errors = result.dig('errors') || result.dig('data', 'updateLearningOutcome', 'errors')
      expect(errors).not_to be_nil
      expect(errors[0]['message']).to match(message)
    end

    it "requires outcome to exist" do
      result = execute_with_input(variables(id: 99999))
      expect_error(result, "unable to find LearningOutcome")
    end

    it "requires update permission for teacher" do
      result = execute_with_input(variables, user_executing: @teacher)
      expect_error(result, 'insufficient permissions')
    end

    it "requires update permission for student" do
      result = execute_with_input(variables, user_executing: @student)
      expect_error(result, 'insufficient permissions')
    end

    it "requires title to be present" do
      result = execute_with_input(variables(title: ''))
      expect_error(result, "can't be blank")
    end
  end
end
