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

require_relative '../spec_helper.rb'

describe Moderation do
  subject(:test_moderation) do
    class TestModeration
      include Moderation
    end
    TestModeration.new
  end

  describe "create_moderation_selections_for_assignment" do
    before :once do
      @course = course_factory
      @assignment = @course.assignments.create!(title: "some assignment")
      @student = User.create!
    end

    it "does not create selections if moderated grading is false" do
      expect{ test_moderation.create_moderation_selections_for_assignment(@assignment.id, [@student.id], []) }.
        not_to change{ @assignment.moderated_grading_selections.count }
    end

    context "with moderated grading on" do
      before :once do
        @student2 = User.create!
        @student3 = User.create!

        @assignment.update!(moderated_grading: true, grader_count: 1)
      end

      it "creates moderated grading selections for each student" do
        expect{ test_moderation.create_moderation_selections_for_assignment(@assignment.id, [@student.id, @student2.id, @student3.id], []) }.
          to change{ @assignment.moderated_grading_selections.count }.from(0).to(3)
      end

      it "does not create moderated grading selections for students who already have one" do
        @assignment.moderated_grading_selections.create! student: @student
        expect{ test_moderation.create_moderation_selections_for_assignment(@assignment.id, [@student.id, @student2.id, @student3.id], []) }.
          to change{ @assignment.moderated_grading_selections.count }.from(1).to(3)
      end

      it "deletes moderated grading selections for students not in the set if given no context" do
        @assignment.moderated_grading_selections.create! student: @student
        @assignment.moderated_grading_selections.create! student: @student2
        expect{ test_moderation.create_moderation_selections_for_assignment(@assignment.id, [@student3.id], []) }.
          to change{ @assignment.moderated_grading_selections.count }.from(2).to(1)
      end

      it "deletes moderated grading selections for students not in the given students but in the student context" do
        @assignment.moderated_grading_selections.create! student: @student
        @assignment.moderated_grading_selections.create! student: @student2
        expect{ test_moderation.create_moderation_selections_for_assignment(@assignment.id, [], [@student.id]) }.
          to change{ @assignment.moderated_grading_selections.count }.from(2).to(1)
      end
    end
  end
end
