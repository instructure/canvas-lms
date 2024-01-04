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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateSplitScreenViewDeeplyNestedAlert do
  before(:once) do
    course_with_teacher(active_all: true)
  end

  def mutation_str(
    split_screen_view_deeply_nested_alert: true
  )
    <<~GQL
      mutation {
        updateSplitScreenViewDeeplyNestedAlert(input: {
          splitScreenViewDeeplyNestedAlert: #{split_screen_view_deeply_nested_alert}
        }) {
          user {
            id
            name
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(mutation_str(**opts), context: {
                                    current_user:,
                                    domain_root_account: @course.account.root_account,
                                    request: ActionDispatch::TestRequest.create
                                  })
    result.to_h.with_indifferent_access
  end

  it "changes splitScreenViewDeeplyNestedAlert to TRUE" do
    result = run_mutation({ split_screen_view_deeply_nested_alert: true })
    expect(result["errors"]).to be_nil
    expect(@teacher.should_show_deeply_nested_alert?).to be true
  end

  it "changes splitScreenViewDeeplyNestedAlert to FALSE" do
    result = run_mutation({ split_screen_view_deeply_nested_alert: false })
    expect(result["errors"]).to be_nil
    expect(@teacher.should_show_deeply_nested_alert?).to be false
  end
end
