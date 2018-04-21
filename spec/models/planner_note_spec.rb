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
require_relative '../spec_helper'
describe PlannerNote do
  before :once do
    course_factory
    student_in_course
    teacher_in_course
    @student_planner_note = PlannerNote.create!(user_id: @student.id,
                                                        todo_date: 4.days.from_now,
                                                        title: "Student Test Assignment",
                                                        course_id: @course.id)
    @teacher_planner_note = PlannerNote.create!(user_id: @teacher.id,
                                                        todo_date: 4.days.from_now,
                                                        title: "Student Test Assignment",
                                                        details: "Students Need Grading",
                                                        course_id: @course.id)
  end

  describe "::planner_note_workflow_state" do

    it "returns 'deleted' for deleted note" do
      @teacher_planner_note.destroy!
      expect(@teacher_planner_note.workflow_state).to eq 'deleted'
    end

    it "returns 'active' for created note" do
      expect(@student_planner_note.workflow_state).to eq 'active'
    end
  end

  it "creates a note without a course" do
    note = PlannerNote.create!(user_id: @teacher.id,
                                                      todo_date: 4.days.from_now,
                                                      title: "Student Test Assignment",
                                                      details: "Students Need Grading")
    expect(note.workflow_state).to eq 'active'
  end

  describe ".before" do
    it "returns planner notes with to do dates before the given date" do
      expect(PlannerNote.before(5.days.from_now).order(:id)).to eq [@student_planner_note, @teacher_planner_note]
    end

    it "does not return planner notes with to do dates after the given date" do
      expect(PlannerNote.before(3.days.from_now).order(:id)).to eq []
    end
  end

  describe ".after" do
    it "returns planner notes with to do dates after the given date" do
      expect(PlannerNote.after(3.days.from_now).order(:id)).to eq [@student_planner_note, @teacher_planner_note]
    end

    it "does not return planner notes with to do dates before the given date" do
      expect(PlannerNote.after(5.days.from_now).order(:id)).to eq []
    end
  end
end
