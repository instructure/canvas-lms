# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Quizzes::QuizQuestion do
  it "deserializes its json data" do
    answers = [{ "id" => 1 }, { "id" => 2 }]
    qd = { "name" => "test question", "question_type" => "multiple_choice_question", "answers" => answers }
    course_factory
    bank = @course.assessment_question_banks.create!
    a = bank.assessment_questions.create!
    q = Quizzes::QuizQuestion.create(question_data: qd, assessment_question: a)
    expect(q.question_data).not_to be_nil
    expect(q.question_data.class).to eq Quizzes::QuizQuestion::QuestionData
    expect(q.assessment_question_id).to eql(a.id)
    q.question_data = qd

    data = q.data
    expect(data[:assessment_question_id]).to eql(a.id)
    expect(data[:answers]).not_to be_empty
    expect(data[:answers].length).to be(2)
    expect(data[:answers][0][:weight]).to eq 100
    expect(data[:answers][1][:weight]).to be(0.0)
  end

  context "blank answers for fill_in[_multiple]_blank[s] questions" do
    before :once do
      answers = [{ "answer_text" => "True", "id" => 1, }, { "id" => 2, "answer_text" => "" }]
      course_with_teacher

      @quiz = @course.quizzes.create
      @short_answer_data = { question_name: "test question",
                             points_possible: "1",
                             question_type: "short_answer_question",
                             answers: }
      @question = @quiz.quiz_questions.create(question_data: @short_answer_data)
    end

    it "clears blanks before saving" do
      expect(@question.question_data.answers.size).to eq 1
      expect(@question.question_data.answers.first["text"]).to eq @short_answer_data[:answers].first["answer_text"]
    end
  end

  describe "#question_data=" do
    before do
      course_with_teacher

      @quiz = @course.quizzes.create

      @data = { question_name: "test question",
                points_possible: "1",
                question_type: "multiple_choice_question",
                answers: [{ "answer_text" => "1", "id" => 1 },
                          { "answer_text" => "2", "id" => 2 },
                          { "answer_text" => "3", "id" => 3 },
                          { "answer_text" => "4", "id" => 4 }] }

      @question = @quiz.quiz_questions.create(question_data: @data)
    end

    it "saves regrade if passed in regrade option in data hash" do
      expect(Quizzes::QuizQuestionRegrade.first).to be_nil

      Quizzes::QuizRegrade.create(quiz_id: @quiz.id, user_id: @user.id, quiz_version: @quiz.version_number)
      @question.question_data = @data.merge(regrade_option: "full_credit",
                                            regrade_user: @user)
      @question.save

      question_regrade = Quizzes::QuizQuestionRegrade.first
      expect(question_regrade).to be
      expect(question_regrade.regrade_option).to eq "full_credit"
    end

    it "sanitizes all the html" do
      question_data = {
        "id" => nil,
        "regrade_option" => "",
        "points_possible" => 1.0,
        "correct_comments_html" => "<img src=\"x\" onerror=\"alert(1)\">",
        "incorrect_comments_html" => "<img src=\"x\" onerror=\"alert(2)\">",
        "neutral_comments_html" => "<img src=\"x\" onerror=\"alert(3)\">",
        "question_type" => "multiple_choice_question",
        "question_name" => "Question",
        "name" => "Question",
        "question_text" => "<img src=\"x\" onerror=\"alert(4)\">",
        "answers" =>
        [
          {
            "id" => 8206,
            "html" => "<img src=\"x\" onerror=\"alert(5)\">",
            "comments_html" => "<img src=\"x\" onerror=\"alert(6)\">",
            "weight" => 100.0
          },
          {
            "id" => 6973,
            "html" => "<img src=\"x\" onerror=\"alert(7)\">",
            "comments_html" => "<img src=\"x\" onerror=\"alert(8)\">",
            "weight" => 0.0
          }
        ]
      }
      qq = @quiz.quiz_questions.create(question_data:)
      expect(qq.question_data["correct_comments_html"]).not_to include("onerror")
      expect(qq.question_data["incorrect_comments_html"]).not_to include("onerror")
      expect(qq.question_data["neutral_comments_html"]).not_to include("onerror")
      expect(qq.question_data["question_text"]).not_to include("onerror")
      expect(qq.question_data["answers"][0]["html"]).not_to include("onerror")
      expect(qq.question_data["answers"][0]["comments_html"]).not_to include("onerror")
      expect(qq.question_data["answers"][1]["html"]).not_to include("onerror")
      expect(qq.question_data["answers"][1]["comments_html"]).not_to include("onerror")
    end
  end

  describe ".update_all_positions" do
    def question_positions(object)
      object.quiz_questions.active.sort_by(&:position).map(&:id)
    end

    before :once do
      course_factory
      @quiz = @course.quizzes.create!(title: "some quiz")
      @question1 = @quiz.quiz_questions.create!(question_data: { "name" => "test question 1", "answers" => [{ "id" => 1 }, { "id" => 2 }] })
      @question2 = @quiz.quiz_questions.create!(question_data: { "name" => "test question 2", "answers" => [{ "id" => 3 }, { "id" => 4 }] })
      @question3 = @quiz.quiz_questions.create!(question_data: { "name" => "test question 3", "answers" => [{ "id" => 5 }, { "id" => 6 }] })
    end

    it "noops if list of items is empty" do
      group = @quiz.quiz_groups.create(name: "question group")
      group.quiz_questions = [@question1, @question2, @question3]
      before = question_positions(group)

      Quizzes::QuizQuestion.update_all_positions!([], group)
      expect(before).to eq question_positions(group)
    end

    it "updates positions for quiz questions within a group" do
      group = @quiz.quiz_groups.create(name: "question group")
      group.quiz_questions = [@question1, @question2, @question3]

      @question3.position = 1
      @question1.position = 2
      @question2.position = 3

      Quizzes::QuizQuestion.update_all_positions!([@question3, @question1, @question2], group)
      expect(question_positions(group)).to eq [@question3.id, @question1.id, @question2.id]
    end

    it "updates positions for quiz questions outside a group" do
      group = @quiz.quiz_groups.create(name: "question group")
      group.quiz_questions = [@question1, @question2]

      @question3.position = 1
      @question1.position = 2
      @question2.position = 3

      Quizzes::QuizQuestion.update_all_positions!([@question3, @question1, @question2], group)
      expect(question_positions(group)).to eq [@question3.id, @question1.id, @question2.id]
    end

    it "updates positions for quiz without a group" do
      @question3.position = 1
      @question1.position = 2
      @question2.position = 3

      Quizzes::QuizQuestion.update_all_positions!([@question3, @question1, @question2])
      expect(question_positions(@quiz)).to eq [@question3.id, @question1.id, @question2.id]
    end
  end

  describe "#destroy" do
    it "does not remove the record from the database, but changes workflow_state" do
      course_with_teacher
      course_quiz

      question = @quiz.quiz_questions.create!
      question.destroy
      question = Quizzes::QuizQuestion.find(question.id)

      expect(question).not_to be_nil
      expect(question).to be_deleted
    end
  end

  context "root_account_id" do
    before { quiz_with_graded_submission([]) }

    it "uses root_account value from account" do
      question = @quiz.quiz_questions.create!
      expect(question.root_account_id).to eq Account.default.id
    end
  end
end
