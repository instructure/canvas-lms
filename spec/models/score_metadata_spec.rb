# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe ScoreMetadata do
  it { is_expected.to belong_to(:score).required }
  it { is_expected.to validate_presence_of(:score) }
  it { is_expected.to validate_presence_of(:calculation_details) }
  it { is_expected.to validate_uniqueness_of(:score_id) }

  include_examples "has_one soft deletion" do
    subject { score.create_score_metadata!(calculation_details:) }

    let(:course) { Course.create! }
    let(:student) { student_in_course(course:) }
    let(:score) { student.scores.create! }
    let(:calculation_details) do
      { "current" => { "dropped" => [] }, "final" => { "dropped" => [] } }
    end
  end
end
