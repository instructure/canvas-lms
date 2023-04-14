# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe Types::RubricType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:student) { student_in_course(course: course, active_all: true).user }
  let(:rubric) { rubric_for_course }
  let(:rubric_type) { GraphQLTypeTester.new(rubric, current_user: student) }

  it "works" do
    expect(rubric_type.resolve("_id")).to eq rubric.id.to_s
  end

  it "requires permission" do
    user2 = User.create!
    expect(rubric_type.resolve("_id", current_user: user2)).to be_nil
  end

  describe "works for the field" do
    it "criteria" do
      expect(
        rubric_type.resolve("criteria { _id }")
      ).to eq(rubric.criteria.map { |c| c[:id].to_s })
    end

    it "free_form_criterion_comments" do
      expect(
        rubric_type.resolve("freeFormCriterionComments")
      ).to be false
    end

    it "hide_score_total" do
      expect(rubric_type.resolve("hideScoreTotal")).to be false
    end

    it "points_possible" do
      rubric.update!(points_possible: 10)
      expect(rubric_type.resolve("pointsPossible")).to eq rubric.points_possible
    end

    it "title" do
      expect(rubric_type.resolve("title")).to eq rubric.title
    end
  end
end
