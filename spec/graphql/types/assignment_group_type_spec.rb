# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require_relative "../graphql_spec_helper"

describe Types::AssignmentGroupType do
  context "AssignmentGroup" do
    before(:once) do
      course_with_student(active_all: true)
      # adding another student
      @student_enrollment = @course.enroll_student(User.create!, enrollment_state: 'active')
      @group = @course.assignment_groups.create!(name: "a group")
      @assignment = @course.assignments.create!(name: "a assignment")

      @other_group = @course.assignment_groups.create!(name: "other group")
      @group.context.recompute_student_scores
      @other_assignment = @course.assignments.create!(
        name: "other",
        assignment_group: @other_group,
      )

      @group.scores.eager_load(:enrollment, :course).all.each do |score|
        score.update!(
          current_score: 68.0,
          final_score: 78.1,
          override_score: 88.2,
          unposted_current_score: 71.3,
          unposted_final_score: 81.4
        )
      end
    end

    before do
      @group_type = GraphQLTypeTester.new(@group, current_user: @student)
    end

    context "top-level permissions" do
      it "needs read permission" do
        some_person = user_factory(active_all: true)
        expect(@group_type.resolve("_id", current_user: some_person)).to be_nil

        expect(
          CanvasSchema.execute(<<~GQL, context: {current_user: some_person}).dig("data", "ag")
            query { ag: assignmentGroup(id: "#{@group.id}") { id } }
          GQL
        ).to be_nil
      end
    end

    describe 'scores' do
      it "returns scores for the assignment group" do
        expect(@group_type.resolve("gradesConnection { nodes { finalScore } }", current_user: @student)).to eq [78.1]
      end

      it "teacher may see all scores" do
        expect(@group_type.resolve("gradesConnection { nodes { finalScore } }", current_user: @teacher).size).to eq 2
      end

      it "teacher may filter scores to individual enrollments" do
        graphql_query = "gradesConnection(filter: {enrollmentIds: [#{@student_enrollment.id}]}) { nodes { enrollment { _id } } }"
        results = @group_type.resolve(graphql_query, current_user: @teacher)
        expect(results.size).to eq 1 
        expect(results).to eq [@student_enrollment.id.to_s]
      end

      it "student may only see their scores" do
        expect(@group_type.resolve("gradesConnection { nodes { finalScore } }", current_user: @student).size).to eq 1
      end
    end

    it "returns information about the group" do
      expect(@group_type.resolve("_id")).to eq @group.id.to_s
      expect(@group_type.resolve("name")).to eq @group.name
    end

    it "returns assignments from the assignment group" do
      expect(@group_type.resolve("assignmentsConnection { edges { node { _id } } }")).
        to eq @group.assignments.map(&:to_param)
    end

    describe 'assignmentsGroupConnection' do
      it "returns assignments in position order" do
        @assignment.update! position: 2
        assignment2 = @course.assignments.create! name: "a2", assignment_group: @group, position: 1

        expect(
          @group_type.resolve("assignmentsConnection { nodes { _id } }")
        ).to eq [assignment2.id.to_s, @assignment.id.to_s]
      end

      it "doesn't include assignments from other groups" do
        expect(
          @group_type.resolve("assignmentsConnection { nodes { _id } }")
        ).not_to include @other_assignment.id.to_s
      end
    end

    describe Types::AssignmentGroupRulesType do
      before do
        @group.rules_hash = {
          drop_highest: 1,
          drop_lowest: 3,
          never_drop: [@assignment.id],
        }.with_indifferent_access
        @group.save!
      end

      it "works" do
        expect(@group_type.resolve("rules { dropHighest }")).to eq 1
        expect(@group_type.resolve("rules { dropLowest }")).to eq 3
        expect(@group_type.resolve("rules { neverDrop { _id } }")).to eq [@assignment.id.to_s]
      end
    end

    context "sis field" do
      before(:once) do
        @group.update!(sis_source_id: "sisGroup")
      end

      let(:manage_admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false })}
      let(:read_admin) { account_admin_user_with_role_changes(role_changes: { manage_sis: false })}

      it "returns sis_id if you have read_sis permissions" do
        expect(
          CanvasSchema.execute(<<~GQL, context: { current_user: read_admin}).dig("data", "assignmentGroup", "sisId")
            query { assignmentGroup(id: "#{@group.id}") { sisId } }
          GQL
        ).to eq("sisGroup")
      end

      it "returns sis_id if you have manage_sis permissions" do
        expect(
          CanvasSchema.execute(<<~GQL, context: { current_user: manage_admin}).dig("data", "assignmentGroup", "sisId")
            query { assignmentGroup(id: "#{@group.id}") { sisId } }
          GQL
        ).to eq("sisGroup")
      end

      it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
        expect(
          CanvasSchema.execute(<<~GQL, context: { current_user: @student}).dig("data", "assignmentGroup", "sisId")
            query { assignmentGroup(id: "#{@group.id}") { sisId } }
          GQL
        ).to be_nil
      end
    end
  end
end
