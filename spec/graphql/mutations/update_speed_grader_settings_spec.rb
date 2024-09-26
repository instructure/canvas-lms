# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Mutations::UpdateSpeedGraderSettings do
  before :once do
    teacher_in_course(active_all: true)
  end

  def execute_with_input(input)
    mutation_command = <<~GQL
      mutation {
        updateSpeedGraderSettings(input: {
          #{input}
        }) {
          speedGraderSettings {
            gradeByQuestion
          }
        }
      }
    GQL
    context = {
      current_user: @teacher,
      domain_root_account: @course.root_account,
      request: ActionDispatch::TestRequest.create,
      session: {},
    }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "updates the speed grader settings" do
    expect do
      execute_with_input <<~GQL
        gradeByQuestion: true
      GQL
    end.to change {
      @teacher.reload.speed_grader_settings.fetch(:grade_by_question)
    }.from(false).to(true)
  end

  it "returns the updated value" do
    result = execute_with_input <<~GQL
      gradeByQuestion: true
    GQL
    expect(result.dig("data", "updateSpeedGraderSettings", "speedGraderSettings", "gradeByQuestion")).to be true
  end
end
