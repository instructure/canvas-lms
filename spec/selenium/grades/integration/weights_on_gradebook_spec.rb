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

require_relative '../pages/gradebook_page'
require_relative './weighting_setup'
require_relative './a_gradebook_shared_example'

describe 'classic gradebook' do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    gradebook = Gradebook::MultipleGradingPeriods.new
    grading_period_ids = [0, @gp1.id, @gp2.id]
    user_session(@teacher)
    gradebook.visit_gradebook(@course,@teacher)

    if @grading_period_index
      gradebook.select_grading_period(grading_period_ids[@grading_period_index])
    end
    gradebook.total_score_for_row(1)
  end

  let(:individual_view) { false }

  before(:once) do
    weighted_grading_setup
  end

  it_behaves_like 'a gradebook'
end
