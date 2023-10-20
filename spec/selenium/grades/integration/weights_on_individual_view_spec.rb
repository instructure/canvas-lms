# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../pages/srgb_page"
require_relative "weighting_setup"
require_relative "a_gradebook_shared_example"

describe "individual view" do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    user_session(@teacher)
    grading_period_titles = ["All Grading Periods", @gp1.title, @gp2.title]
    SRGB.visit(@course.id)

    if @grading_period_index
      SRGB.select_grading_period(grading_period_titles[@grading_period_index])
      refresh_page
    end
    SRGB.select_student(@student)
    SRGB.total_score
  end

  let(:individual_view) { true }

  before(:once) do
    weighted_grading_setup
  end

  after do
    clear_local_storage
  end

  it_behaves_like "a gradebook"
end
