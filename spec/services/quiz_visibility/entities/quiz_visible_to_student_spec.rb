# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

describe QuizVisibility::Entities::QuizVisibleToStudent do
  describe "testing DTO" do
    it "can be initialized" do
      quiz_visible_to_student = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student.quiz_id).to eq 7
    end

    it "raises error if passed nil course_id" do
      expect { QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: nil, quiz_id: 7) }.to raise_error(ArgumentError, "course_id cannot be nil")
    end

    it "raises error if passed nil user_id" do
      expect { QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: nil, course_id: 6, quiz_id: 7) }.to raise_error(ArgumentError, "user_id cannot be nil")
    end

    it "raises error if passed nil quiz_id" do
      expect { QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: nil) }.to raise_error(ArgumentError, "quiz_id cannot be nil")
    end

    it "equality is attribute based" do
      quiz_visible_to_student = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      quiz_visible_to_student_2 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student).to eq quiz_visible_to_student_2

      # with different user_ids
      quiz_visible_to_student_3 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 4, course_id: 6, quiz_id: 7)
      quiz_visible_to_student_4 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student_3).not_to eq quiz_visible_to_student_4

      # with different quiz_ids
      quiz_visible_to_student_5 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 3)
      quiz_visible_to_student_6 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student_5).not_to eq quiz_visible_to_student_6

      # with different course_ids
      quiz_visible_to_student_7 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 8, quiz_id: 7)
      quiz_visible_to_student_8 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student_7).not_to eq quiz_visible_to_student_8
    end

    it "hashcode is attribute based" do
      quiz_visible_to_student = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      quiz_visible_to_student_2 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student.hash).to eq quiz_visible_to_student_2.hash

      # with different user_ids
      quiz_visible_to_student_3 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 4, course_id: 6, quiz_id: 7)
      quiz_visible_to_student_4 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student_3.hash).not_to eq quiz_visible_to_student_4.hash

      # with different quiz_ids
      quiz_visible_to_student_5 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 3)
      quiz_visible_to_student_6 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student_5.hash).not_to eq quiz_visible_to_student_6.hash

      # with different course_ids
      quiz_visible_to_student_7 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 8, quiz_id: 7)
      quiz_visible_to_student_8 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      expect(quiz_visible_to_student_7.hash).not_to eq quiz_visible_to_student_8.hash
    end

    it "can be unioned in array (set operation)" do
      # 4 quiz_visible_to_student, one is a duplicate of another
      quiz_visible_to_student = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      quiz_visible_to_student_duplicate = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)

      quiz_visible_to_student_2 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 3, course_id: 4, quiz_id: 5)
      quiz_visible_to_student_3 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 8)

      array_1 = [quiz_visible_to_student, quiz_visible_to_student_2]
      array_2 = [quiz_visible_to_student_duplicate, quiz_visible_to_student_3]

      # union the two arrays
      union_array = array_1 | array_2

      # the duplicate should be removed
      expect(union_array.length).to eq 3
      expect(union_array).to include(quiz_visible_to_student)
      expect(union_array).to include(quiz_visible_to_student_2)
      expect(union_array).to include(quiz_visible_to_student_3)
    end

    it "can be removed from array (set operation)" do
      # 4 quiz_visible_to_student, one is a duplicate of another
      quiz_visible_to_student = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)
      quiz_visible_to_student_duplicate = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 7)

      quiz_visible_to_student_2 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 3, course_id: 4, quiz_id: 5)
      quiz_visible_to_student_3 = QuizVisibility::Entities::QuizVisibleToStudent.new(user_id: 5, course_id: 6, quiz_id: 8)

      array_1 = [quiz_visible_to_student, quiz_visible_to_student_2, quiz_visible_to_student_3]
      array_2 = [quiz_visible_to_student_duplicate]

      # remove all elements in array_2 from array_1
      array_with_removal = array_1 - array_2

      expect(array_with_removal.length).to eq 2

      expect(array_with_removal).not_to include(quiz_visible_to_student)
      expect(array_with_removal).not_to include(quiz_visible_to_student_duplicate)
      expect(array_with_removal).to include(quiz_visible_to_student_2)
      expect(array_with_removal).to include(quiz_visible_to_student_3)
    end
  end
end
