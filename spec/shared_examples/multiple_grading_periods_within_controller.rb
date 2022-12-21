# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

shared_context "grading periods within controller" do
  let(:root_account) { course.root_account }

  it "injects grading periods into the JS ENV if grading periods exist" do
    action, opts = request_params

    group = root_account.grading_period_groups.create!
    group.enrollment_terms << course.enrollment_term
    user_session(teacher)
    get(action, **opts)
    expect(assigns[:js_env]).to have_key(:active_grading_periods)
  end

  it "includes 'last' and 'closed' data on each grading period" do
    action, opts = request_params

    group = root_account.grading_period_groups.create!
    group.enrollment_terms << course.enrollment_term
    group.grading_periods.create!(title: "hi", start_date: 3.days.ago, end_date: 3.days.from_now)
    user_session(teacher)
    get(action, **opts)
    period = assigns[:js_env][:active_grading_periods].first
    expect(period.keys).to include("is_closed", "is_last")
  end

  it "does not inject grading periods into the JS ENV if there are no grading periods" do
    action, opts = request_params

    user_session(teacher)
    get(action, **opts)
    expect(assigns[:js_env]).not_to have_key(:active_grading_periods)
  end
end
