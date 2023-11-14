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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateRubricArchivedState do
  before(:once) do
    course_with_teacher(active_all: true)
    rubric_for_course
  end

  def mutation_str(
    id: nil,
    archived: true
  )
    <<~GQL
      mutation {
        updateRubricArchivedState(input: {id: #{id}, archived: #{archived}}) {
          rubric {
            _id
            workflowState
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "marks rubric as archived" do
    Account.site_admin.enable_feature!(:enhanced_rubrics)
    expect(@rubric.workflow_state).to eq "active"
    result = run_mutation({ id: @rubric.id, archived: true })
    expect(result.dig("data", "updateRubricArchivedState", "errors")).to be_nil
    expect(result.dig("data", "updateRubricArchivedState", "rubric", "workflowState")).to eq("archived")
  end

  it "marks rubric as active" do
    Account.site_admin.enable_feature!(:enhanced_rubrics)
    @rubric.archive
    expect { run_mutation({ id: @rubric.id, archived: false }) }.to change { @rubric.reload.workflow_state }.from("archived").to("active")
  end
end
