# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

RSpec.describe CourseScoreStatistic do
  describe "#grades_presenter_hash" do
    let(:course_score_statistic) { CourseScoreStatistic.new(course_id: 123, average: BigDecimal("12.23"), score_count: 2) }

    it "returns the data in the grades presenter expected shape and keys" do
      expect(course_score_statistic.grades_presenter_hash).to eq({ score: BigDecimal("12.23"), students: 2 })
    end
  end
end
