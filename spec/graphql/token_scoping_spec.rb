# frozen_string_literal: true

#
# Copyright (C) 2019 Instructure, Inc.
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

require_relative "../spec_helper"
require_relative "graphql_spec_helper"

describe "GraphQL Token Scoping" do
  before(:once) do
    teacher_in_course(active_all: true)
  end

  let(:scoped_developer_key) { DeveloperKey.create!(require_scopes: true) }
  let(:unscoped_developer_key) { DeveloperKey.create! }
  let(:course_type) { GraphQLTypeTester.new(@course, current_user: @teacher) }

  it "does not affect requests with an unscoped developer key" do
    token = AccessToken.create!(developer_key: unscoped_developer_key)
    expect(
      course_type.resolve("_id", access_token: token)
    ).to eq @course.id.to_s
  end

  it "does not allow queries with a scoped developer key" do
    token = AccessToken.create!(developer_key: scoped_developer_key)
    expect do
      course_type.resolve("_id", access_token: token)
    end.to raise_error(/insufficient scopes/)
  end

  it "does not allow mutations with a scoped developer key" do
    token = AccessToken.create!(developer_key: scoped_developer_key)
    result = CanvasSchema.execute(<<~GQL, context: { current_user: @teacher, access_token: token })
      mutation {
        createAssignment(input: {courseId: "#{@course.id}", name: "asdf"}) {
          assignment { id }
        }
      }
    GQL
    expect(result.dig("errors", 0, "message")).to match(/insufficient scopes/)
    expect(result.dig("data", "createAssignment")).to be_nil
  end
end
