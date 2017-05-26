#
# Copyright (C) 2017 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "legacyNode" do
  before(:once) do
    course_with_student(active_all: true)
  end

  def run_query(query, user)
    CanvasSchema.execute(query, context: {current_user: user})
  end

  context "courses" do
    before(:once) do
      @query = <<-GQL
      query {
        course: legacyNode(type: Course, _id: "#{@course.id}") {
          ... on Course {
            _id,
            name
          }
        }
      }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["course"]["_id"]
      ).to eq @course.id.to_s
    end

    it "needs read permission" do
      @course1, @student1 = @course, @student
      course_with_student
      @course2, @student2 = @course, @student

      expect(run_query(@query, @student2)["data"]["course"]).to be_nil
    end
  end

  context "assignments" do
    before(:once) do
      @assignment = @course.assignments.create! name: "Some Assignment"
      @query = <<-GQL
      query {
        assignment: legacyNode(type: Assignment, _id: "#{@assignment.id}") {
          ... on Assignment {
            _id
            name
          }
        }
      }
      GQL
    end

    it "works" do
      expect(
        run_query(@query, @student)["data"]["assignment"]["_id"]
      ).to eq @assignment.id.to_s
    end

    it "needs read permission" do
      @assignment.unpublish
      expect(run_query(@query, @student)["data"]["assignment"]).to be_nil
    end
  end
end
