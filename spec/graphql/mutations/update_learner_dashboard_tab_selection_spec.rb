# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe Mutations::UpdateLearnerDashboardTabSelection do
  before(:once) do
    student_in_course(active_all: true)
  end

  def mutation_str(tab:)
    <<~GQL
      mutation {
        updateLearnerDashboardTabSelection(input: {
          tab: #{tab}
        }) {
          tab
          errors {
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "updates the learner dashboard tab preference" do
    result = run_mutation(tab: "courses")
    expect(result.dig("data", "updateLearnerDashboardTabSelection", "tab")).to eq("courses")
    expect(@student.get_preference(:learner_dashboard_tab_selection)).to eq("courses")
  end

  it "allows setting to dashboard tab" do
    result = run_mutation(tab: "dashboard")
    expect(result.dig("data", "updateLearnerDashboardTabSelection", "tab")).to eq("dashboard")
    expect(@student.get_preference(:learner_dashboard_tab_selection)).to eq("dashboard")
  end

  it "persists the preference across requests" do
    run_mutation(tab: "courses")
    @student.reload
    expect(@student.get_preference(:learner_dashboard_tab_selection)).to eq("courses")
  end

  it "updates an existing preference" do
    @student.set_preference(:learner_dashboard_tab_selection, "dashboard")
    result = run_mutation(tab: "courses")
    expect(result.dig("data", "updateLearnerDashboardTabSelection", "tab")).to eq("courses")
    @student.reload
    expect(@student.get_preference(:learner_dashboard_tab_selection)).to eq("courses")
  end
end
