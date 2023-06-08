# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

RSpec.describe Mutations::UpdateUserDiscussionsSplitscreenView do
  def mutation_str(
    discussions_splitscreen_view: false
  )
    <<~GQL
      mutation {
        updateUserDiscussionsSplitscreenView(input: {discussionsSplitscreenView: #{discussions_splitscreen_view}}) {
          user {
            discussionsSplitscreenView
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

  before(:once) do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user

    @current_user = @teacher
  end

  it "updates the user's discussions_splitscreen_view? preference" do
    result = run_mutation({ discussions_splitscreen_view: true })
    @current_user.reload

    expect(@current_user.discussions_splitscreen_view?).to be true
    expect(result.dig("data", "updateUserDiscussionsSplitscreenView", "user", "discussionsSplitscreenView")).to be(true)
  end
end
