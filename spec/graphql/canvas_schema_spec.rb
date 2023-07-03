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
#

require_relative "graphql_spec_helper"

describe CanvasSchema do
  before(:once) { course_with_student(active_all: true, course_name:) }

  let(:course_name) { "Kiteboarding 101" }
  let(:entities_query) do
    <<~GQL
      query EntitiesQuery($representations: [_Any!]!) {
        _entities(representations: $representations) {
          ... on Course {
            name
          }
        }
      }
    GQL
  end
  let(:course_gql_id) { GraphQL::Schema::UniqueWithinType.encode("Course", @course.id) }
  let(:variables) { { representations: [{ __typename: "Course", id: course_gql_id }] } }
  let(:gql_context) { { current_user: @student } }

  let(:all_courses_query) do
    <<~GQL
      query Q {
        allCourses {
          name
        }
      }
    GQL
  end

  it "exposes defined queries" do
    result = CanvasSchema.execute(all_courses_query, context: gql_context)
    expect(result["data"]).to eq({ "allCourses" => [{ "name" => course_name }] })
  end

  it "does not expose Apollo Federation special types" do
    result = CanvasSchema.execute(entities_query, variables:, context: gql_context)
    error_messages = result["errors"].pluck("message")
    expect(error_messages).to include("Field '_entities' doesn't exist on type 'Query'")
    expect(result["data"]).to be_nil
  end

  describe ".for_federation" do
    it "exposes defined queries" do
      result = CanvasSchema.for_federation.execute(all_courses_query, context: gql_context)
      expect(result["data"]).to eq({ "allCourses" => [{ "name" => course_name }] })
    end

    it "exposes Apollo Federation special types" do
      result = CanvasSchema.for_federation.execute(entities_query, variables:, context: gql_context)
      expect(result["data"]).to eq({ "_entities" => [{ "name" => course_name }] })
    end
  end
end
