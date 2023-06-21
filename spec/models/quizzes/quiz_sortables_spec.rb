# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Quizzes::QuizSortables do
  describe ".initialize" do
    it "assigns the quiz" do
      quiz = Quizzes::Quiz.new
      sortables = Quizzes::QuizSortables.new(quiz:, order: [])

      expect(sortables.quiz).to eq quiz
    end

    it "assigns the group and quiz" do
      quiz  = double
      group = double(quiz:)

      sortables = Quizzes::QuizSortables.new(group:, order: [])

      expect(sortables.group).to eq group
      expect(sortables.quiz).to  eq quiz
    end

    it "builds the list of items" do
      group = Quizzes::QuizGroup.new
      group.id = 234
      groups = [group]

      question = Quizzes::QuizQuestion.new
      question.id = 123
      questions = double(active: [question])

      quiz = double(quiz_groups: groups, quiz_questions: questions)

      order = [{ "type" => "group",    "id" => "234" },
               { "type" => "question", "id" => "123" }]

      sortables = Quizzes::QuizSortables.new(quiz:, order:)
      expect(sortables.items).to eq [group, question]
    end

    it "ignores items that dont have valid ids" do
      groups = [Quizzes::QuizGroup.new]
      questions = double(active: [Quizzes::QuizQuestion.new])

      quiz = double(quiz_groups: groups, quiz_questions: questions)

      order = [{ "type" => "group",    "id" => "234" },
               { "type" => "question", "id" => "123" }]

      sortables = Quizzes::QuizSortables.new(quiz:, order:)
      expect(sortables.items).to eq []
    end
  end

  describe "#reorder!" do
    context "for group questions" do
      before do
        @question1 = Quizzes::QuizQuestion.new
        @question1.id = 123

        @question2 = Quizzes::QuizQuestion.new
        @question2.id = 234

        @quiz = double(quiz_groups: [],
                       quiz_questions: double(active: [@question1, @question2]),
                       mark_edited!: true)
        @group = Group.new
        allow(@group).to receive_messages(quiz: @quiz, id: 999)

        @order = [{ "type" => "question", "id" => "234" },
                  { "type" => "question", "id" => "123" }]
        @sortables = Quizzes::QuizSortables.new(group: @group, order: @order)
        expect(@sortables).to receive(:update_object_positions!)
      end

      it "updates quiz_group_ids of group questions" do
        expect(@question1).to receive(:quiz_group_id=).with(@group.id)
        expect(@question2).to receive(:quiz_group_id=).with(@group.id)
        @sortables.reorder!
      end
    end

    context "for quiz items" do
      before do
        @group = Quizzes::QuizGroup.new
        @group.id = 234

        @question = Quizzes::QuizQuestion.new
        @question.id = 123

        @quiz = double(quiz_groups: [@group],
                       quiz_questions: double(active: [@question]),
                       mark_edited!: true)

        @order = [{ "type" => "group",    "id" => "234" },
                  { "type" => "question", "id" => "123" }]
        @sortables = Quizzes::QuizSortables.new(quiz: @quiz, order: @order)
        expect(@sortables).to receive(:update_object_positions!)
      end

      it "updates positions attribute of questions" do
        expect(@group).to receive(:position=).with(1)
        expect(@question).to receive(:position=).with(2)

        @sortables.reorder!
      end

      it "updates quiz_group_ids of quiz questions" do
        expect(@question).to receive(:quiz_group_id=).with(nil)
        @sortables.reorder!
      end

      it "marks quiz as edited" do
        expect(@quiz).to receive(:mark_edited!)
        @sortables.reorder!
      end
    end
  end
end
