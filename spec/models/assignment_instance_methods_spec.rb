# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Assignment do
  describe "#anonymous_student_identities" do
    before(:once) do
      @course = Course.create!
      @teacher = User.create!
      @first_student = User.create!
      @second_student = User.create!
      course_with_teacher(course: @course, user: @teacher, active_all: true)
      course_with_student(course: @course, user: @first_student, active_all: true)
      course_with_student(course: @course, user: @second_student, active_all: true)
      @assignment = @course.assignments.create!(anonymous_grading: true)
    end

    it "returns student identities, sorted by anonymous_id" do
      @assignment.submissions.find_by(user: @first_student).update!(anonymous_id: "a")
      @assignment.submissions.find_by(user: @second_student).update!(anonymous_id: "b")

      expect do
        @assignment.submissions.find_by(user: @first_student).update!(anonymous_id: "c")
      end.to change {
        Assignment.find(@assignment.id).anonymous_student_identities
      }.from({
               @first_student.id => "Student 1",
               @second_student.id => "Student 2"
             }).to({
                     @first_student.id => "Student 2",
                     @second_student.id => "Student 1"
                   })
    end

    it "performs a secondary sort on hashed ID" do
      sub1 = @assignment.submissions.find_by(user: @first_student)
      sub1.update!(anonymous_id: nil)
      sub2 = @assignment.submissions.find_by(user: @second_student)
      sub2.update!(anonymous_id: nil)
      initial_student_first = Digest::MD5.hexdigest(sub1.id.to_s) < Digest::MD5.hexdigest(sub2.id.to_s)
      expect(@assignment.anonymous_student_identities).to eq({
                                                               @first_student.id => initial_student_first ? "Student 1" : "Student 2",
                                                               @second_student.id => initial_student_first ? "Student 2" : "Student 1"
                                                             })
    end
  end
end
