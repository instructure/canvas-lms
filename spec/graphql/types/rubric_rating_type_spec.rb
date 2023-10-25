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

describe Types::RubricRatingType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:student) { student_in_course(course:, active_all: true).user }
  let(:rubric) { rubric_for_course }
  let(:rubric_type) { GraphQLTypeTester.new(rubric, current_user: student) }

  it "works" do
    expect(
      rubric_type.resolve("criteria { ratings { _id } }")
    ).to eq(rubric.criteria.map { |c| c[:ratings].pluck(:id).map(&:to_s) })
  end

  it "rubric id" do
    expect(
      rubric_type.resolve("criteria { ratings { rubricId } }").first.uniq.first
    ).to eq(rubric.id.to_s)
  end

  describe "works for the field" do
    it "description" do
      expect(
        rubric_type.resolve("criteria { ratings { description } }")
      ).to eq(rubric.criteria.map { |c| c[:ratings].pluck(:description) })
    end

    it "long_description" do
      expect(
        rubric_type.resolve("criteria { ratings { longDescription } }")
      ).to eq(rubric.criteria.map { |c| c[:ratings].pluck(:long_description) })
    end

    it "points" do
      expect(
        rubric_type.resolve("criteria { ratings { points } }")
      ).to eq(rubric.criteria.map { |c| c[:ratings].pluck(:points) })
    end
  end
end
