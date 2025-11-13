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

describe Quizzes::QuizQuestionsController do
  def course_quiz(active = false)
    @quiz = @course.quizzes.create
    @quiz.workflow_state = "available" if active
    @quiz.save!
    @quiz
  end

  def quiz_question
    @question = @quiz.quiz_questions.build
    @question["question_data"] = { answers: [
      { id: 123_456, answer_text: "asdf", weight: 100 },
      { id: 654_321, answer_text: "jkl;", weight: 0 }
    ] }
    @question.save!
    @question
  end

  def quiz_group
    @quiz.quiz_groups.create
  end

  before :once do
    course_with_teacher(active_all: true)
    course_quiz
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { course_id: @course.id, quiz_id: @quiz, question: {} }
      assert_unauthorized
    end

    it "creates a quiz question" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               quiz_id: @quiz,
                               question: {
                                 question_type: "multiple_choice_question",
                                 answers: {
                                   "0" => {
                                     answer_text: "asdf",
                                     weight: 100
                                   },
                                   "1" => {
                                     answer_text: "jkl;",
                                     weight: 0
                                   }
                                 }
                               } }
      expect(assigns[:question]).not_to be_nil
      expect(assigns[:question].question_data).not_to be_nil
      expect(assigns[:question].question_data[:answers].length).to be(2)
      expect(assigns[:quiz]).to eql(@quiz)
    end

    it "preserves ids, if provided, on create" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               quiz_id: @quiz,
                               question: {
                                 question_type: "multiple_choice_question",
                                 answers: [
                                   {
                                     id: 123_456,
                                     answer_text: "asdf",
                                     weight: 100
                                   },
                                   {
                                     id: 654_321,
                                     answer_text: "jkl;",
                                     weight: 0
                                   },
                                   {
                                     id: 654_321,
                                     answer_text: "qwer",
                                     weight: 0
                                   }
                                 ]
                               } }
      expect(assigns[:question]).not_to be_nil
      expect(assigns[:question].question_data).not_to be_nil
      data = assigns[:question].question_data[:answers]

      expect(data.length).to be(3)
      expect(data[0][:id]).to be(123_456)
      expect(data[1][:id]).to be(654_321)
      expect(data[2][:id]).not_to eql(654_321)
    end

    it "bounces data thats too long" do
      long_data = "abcdefghijklmnopqrstuvwxyz"
      16.times do
        long_data = "#{long_data}abcdefghijklmnopqrstuvwxyz#{long_data}"
      end
      user_session(@teacher)
      post "create",
           params: { course_id: @course.id,
                     quiz_id: @quiz,
                     question: {
                       question_text: long_data
                     } },
           xhr: true
      expect(response.body).to match(/max length is 16384/)
    end

    it "strips the origin from local URLs in answers" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               quiz_id: @quiz,
                               question: {
                                 question_type: "multiple_choice_question",
                                 answers: {
                                   "0" => {
                                     answer_html: "<a href='https://test.host:80/courses/#{@course.id}/files/27'>home</a>",
                                     comment_html: "<a href='https://test.host:80/courses/#{@course.id}/assignments'>home</a>",
                                   }
                                 }
                               } }
      expect(assigns[:question].question_data[:answers][0][:html]).not_to match(%r{https://test.host})
      expect(assigns[:question].question_data[:answers][0][:html]).to match(%r{href=['"]/courses/#{@course.id}/files/27})
    end

    it "strips the origin from local URLs in answers when they are provided as an array" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               quiz_id: @quiz,
                               question: {
                                 question_type: "multiple_choice_question",
                                 answers: [{
                                   answer_html: "<a href='https://test.host:80/courses/#{@course.id}/files/27'>home</a>",
                                   comment_html: "<a href='https://test.host:80/courses/#{@course.id}/assignments'>home</a>",
                                 }]
                               } }
      expect(assigns[:question].question_data[:answers][0][:html]).not_to match(%r{https://test.host})
      expect(assigns[:question].question_data[:answers][0][:html]).to match(%r{href=['"]/courses/#{@course.id}/files/27})
    end

    it "sets updating_user when creating a quiz question" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id,
                               quiz_id: @quiz,
                               question: {
                                 question_type: "multiple_choice_question",
                                 answers: {
                                   "0" => {
                                     answer_text: "answer1",
                                     weight: 100
                                   }
                                 }
                               } }
      question = assigns[:question]
      expect(question).not_to be_nil
      expect(question.assessment_question).not_to be_nil
      expect(question.assessment_question.updating_user).to eq(@teacher)
    end

    context "when adding questions from a bank" do
      it "add_assessment_questions would create assessment with a cloned attachment" do
        @bank = @course.assessment_question_banks.create!(title: "Test Bank")
        @attachment = attachment_with_context(@course)
        @assessment_question = @bank.assessment_questions.create!(
          question_data: {
            question_type: "multiple_choice_question",
            question_name: "Test Question",
            question_text: "<p>File ref:<img src='/courses/#{@course.id}/files/#{@attachment.id}'></p>",
            points_possible: 1
          }
        )
        user_session(@teacher)
        post "create", params: {
          course_id: @course.id,
          quiz_id: @quiz,
          assessment_question_bank_id: @bank.id,
          assessment_questions_ids: @assessment_question.id.to_s,
          existing_questions: "1"
        }

        quiz_question = assigns[:questions]&.first
        expect(quiz_question).not_to be_nil
        expect(quiz_question.assessment_question).not_to be_nil
        expect(quiz_question.assessment_question.attachments).not_to be_nil
      end
    end
  end

  describe "PUT 'update'" do
    before(:once) { quiz_question }

    it "requires authorization" do
      put "update", params: { course_id: @course.id, quiz_id: @quiz, id: @question.id, question: {} }
      assert_unauthorized
    end

    it "updates a quiz question" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id,
                              quiz_id: @quiz,
                              id: @question.id,
                              question: {
                                question_type: "multiple_choice_question",
                                answers: {
                                  "0" => {
                                    answer_text: "asdf",
                                    weight: 100
                                  },
                                  "1" => {
                                    answer_text: "jkl;",
                                    weight: 0
                                  },
                                  "2" => {
                                    answert_text: "qwer",
                                    weight: 0
                                  }
                                }
                              } }
      expect(assigns[:question]).not_to be_nil
      expect(assigns[:question].question_data).not_to be_nil
      expect(assigns[:question].question_data[:answers].length).to be(3)
      expect(assigns[:quiz]).to eql(@quiz)
    end

    it "preserves ids, if provided, on update" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id,
                              quiz_id: @quiz,
                              id: @question.id,
                              question: {
                                question_type: "multiple_choice_question",
                                answers: {
                                  "0" => {
                                    id: 123_456,
                                    answer_text: "asdf",
                                    weight: 100
                                  },
                                  "1" => {
                                    id: 654_321,
                                    answer_text: "jkl;",
                                    weight: 0
                                  },
                                  "2" => {
                                    id: 654_321,
                                    answer_text: "qwer",
                                    weight: 0
                                  }
                                }
                              } }
      expect(assigns[:question]).not_to be_nil
      expect(assigns[:question].question_data).not_to be_nil
      data = assigns[:question].question_data[:answers]
      expect(data.length).to be(3)
      expect(data[0][:id]).to be(123_456)
      expect(data[1][:id]).to be(654_321)
      expect(data[2][:id]).not_to eql(654_321)
    end

    it "bounces data thats too long" do
      long_data = "abcdefghijklmnopqrstuvwxyz"
      16.times do
        long_data = "#{long_data}abcdefghijklmnopqrstuvwxyz#{long_data}"
      end
      user_session(@teacher)
      put "update",
          params: { course_id: @course.id,
                    quiz_id: @quiz,
                    id: @question.id,
                    question: {
                      question_text: long_data
                    } },
          xhr: true
      expect(response.body).to match(/max length is 16384/)
    end

    it "deletes non-html comments if needed" do
      bank = @course.assessment_question_banks.create!(title: "Test Bank")
      aq = bank.assessment_questions.create!(question_data: {
                                               question_type: "essay_question", correct_comments: "stuff", correct_comments_html: "stuff"
                                             })

      # add the first question directly onto the quiz, so it shouldn't get "randomly" selected from the group
      linked_question = @quiz.quiz_questions.build(question_data: aq.question_data)
      linked_question.assessment_question_id = aq.id
      linked_question.save!

      user_session(@teacher)
      put "update", params: { course_id: @course.id, quiz_id: @quiz, id: linked_question.id, question: { correct_comments_html: "" } }
      expect(response).to be_successful

      linked_question.reload
      expect(linked_question.question_data["correct_comments_html"]).to be_blank
      expect(linked_question.question_data["correct_comments"]).to be_blank
    end

    it "leaves assessment question verifiers" do
      @attachment = attachment_with_context(@course)
      bank = @course.assessment_question_banks.create!(title: "Test Bank")
      aq = bank.assessment_questions.create!(question_data: {
                                               question_type: "essay_question",
                                               question_text: "File ref:<img src=\"/courses/#{@course.id}/files/#{@attachment.id}/download\">"
                                             },
                                             updating_user: @teacher)

      translated_text = aq.reload.question_data["question_text"]
      expect(translated_text).to match %r{/assessment_questions/\d+/files/\d+}
      expect(translated_text).to match(/verifier=/)

      # add the first question directly onto the quiz, so it shouldn't get "randomly" selected from the group
      linked_question = @quiz.quiz_questions.build(question_data: aq.question_data, updating_user: @teacher)
      linked_question.assessment_question_id = aq.id
      linked_question.save!

      user_session(@teacher)
      put "update", params: { course_id: @course.id,
                              quiz_id: @quiz,
                              id: linked_question.id,
                              question: { question_text: translated_text } }
      expect(response).to be_successful

      linked_question.reload
      expect(linked_question.question_data["question_text"]).to eq translated_text # leave alone
    end

    context "when the quiz_question doesn't have an assessment_question and its workflow_state is not 'generated'" do
      before do
        @question.update!(question_data: { question_type: "multiple_choice_question" })
        @question.update_column(:assessment_question_id, nil)
      end

      it "generates an assessment_question for the quiz_question" do
        user_session(@teacher)
        expect do
          put "update", params: { course_id: @course.id,
                                  quiz_id: @quiz,
                                  id: @question.id,
                                  question: {
                                    neutral_comments_html: ""
                                  } }
          @question.reload
        end.to change { @question.assessment_question.present? }.from(false).to(true)
      end

      it "does not reset the question's data" do
        user_session(@teacher)
        expect do
          put "update", params: { course_id: @course.id,
                                  quiz_id: @quiz,
                                  id: @question.id,
                                  question: {
                                    neutral_comments_html: ""
                                  } }
          @question.reload
        end.not_to change { @question.question_data["question_type"] }
      end
    end

    context "when the quiz_question doesn't have an assessment_question and its workflow_state is 'generated'" do
      before do
        @question.update_column(:assessment_question_id, nil)
        allow_any_instance_of(Quizzes::QuizQuestion).to receive(:generated?).and_return(true)
      end

      it "does not generate an assessment_question for the quiz_question" do
        user_session(@teacher)
        expect do
          put "update", params: { course_id: @course.id,
                                  quiz_id: @quiz,
                                  id: @question.id,
                                  question: { neutral_comments_html: "" } }
          @question.reload
        end.not_to change { @question.assessment_question.present? }
      end
    end

    context "when the quiz_question has an assessment_question" do
      it "does not generates an assessment_question for the quiz_question" do
        user_session(@teacher)
        expect do
          put "update", params: { course_id: @course.id,
                                  quiz_id: @quiz,
                                  id: @question.id,
                                  question: { neutral_comments_html: "" } }
          @question.reload
        end.not_to change { @question.assessment_question }
      end
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { quiz_question }

    it "sets updating_user when destroying a quiz question" do
      user_session(@teacher)
      expect do
        delete "destroy", params: { course_id: @course.id, quiz_id: @quiz, id: @question.id }
      end.to change { Quizzes::QuizQuestion.active.count }.by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
