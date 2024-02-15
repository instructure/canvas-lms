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

describe Types::RubricCriterionType do
  let_once(:student) { student_in_course(active_all: true).user }
  let(:learning_outcome) { outcome_model }
  let(:rubric) { rubric_for_course }
  let!(:rubric_type) { GraphQLTypeTester.new(rubric, current_user: student) }

  it "works" do
    expect(rubric_type.resolve("criteria { _id }")).to eq(rubric.criteria.map { |c| c[:id].to_s })
  end

  describe "works for the field" do
    it "criterion_use_range" do
      expect(
        rubric_type.resolve("criteria { criterionUseRange }")
      ).to eq [false]
    end

    it "description" do
      expect(
        rubric_type.resolve("criteria { description }")
      ).to eq rubric.criteria.pluck(:description)
    end

    it "ignore_for_scoring" do
      expect(
        rubric_type.resolve("criteria { ignoreForScoring }")
      ).to eq [false]
    end

    it "long_description" do
      expect(
        rubric_type.resolve("criteria { longDescription }")
      ).to eq rubric.criteria.pluck(:long_description)
    end

    it "mastery_points" do
      expect(
        rubric_type.resolve("criteria { masteryPoints }")
      ).to eq rubric.criteria.pluck(:master_points)
    end

    it "outcome" do
      rubric.criteria[0][:learning_outcome_id] = learning_outcome.id
      rubric.save!
      expect(
        rubric_type.resolve("criteria { outcome { _id }}")
      ).to eq rubric.criteria.pluck(:learning_outcome_id).map(&:to_s)
    end

    it "points" do
      expect(
        rubric_type.resolve("criteria { points }")
      ).to eq rubric.criteria.pluck(:points)
    end

    it "ratings" do
      expect(
        rubric_type.resolve("criteria { ratings { _id }}")
      ).to eq(rubric.criteria.map { |c| c[:ratings].map { |r| r[:id].to_s } })
    end

    it "learning_outcome_id" do
      rubric.criteria[0][:learning_outcome_id] = learning_outcome.id
      rubric.save!

      expect(
        rubric_type.resolve("criteria { learningOutcomeId }")
      ).to eq rubric.criteria.pluck(:learning_outcome_id).map(&:to_s)
    end
  end
end
