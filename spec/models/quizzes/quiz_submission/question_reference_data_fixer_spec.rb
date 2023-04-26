# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe Quizzes::QuizSubmission::QuestionReferenceDataFixer do
  before(:once) do
    # make sure the sequences are nowhere near each other, so as to avoid
    # flickering failures due to colliding ids
    User.connection.execute "ALTER SEQUENCE public.assessment_questions_id_seq RESTART WITH 1000"
    User.connection.execute "ALTER SEQUENCE public.quiz_questions_id_seq RESTART WITH 2000"

    @course = course_model
    @bank = @course.assessment_question_banks.create!(title: "Test Bank")
    @aq = assessment_question_model({
                                      bank: @bank,
                                      question_data: {
                                        question_type: "multiple_choice_question",
                                        question_text: "Choose one! (Tip: A might be a good choice!)",
                                        answers: [
                                          { id: 1, text: "A", weight: 100 },
                                          { id: 2, text: "B" },
                                          { id: 3, text: "C" }
                                        ]
                                      }
                                    })

    @quiz = @course.quizzes.create
    @qq = @quiz.quiz_questions.create!(question_data: true_false_question_data)
  end

  before do
    @quiz.quiz_questions.generated.destroy_all
  end

  let :quiz_submission do
    @quiz.quiz_submissions.build.tap do |quiz_submission|
      quiz_submission.quiz_data = [
        @aq.data # #data() will include the AQ's ID
      ]

      quiz_submission.without_versioning(&:save!)
    end
  end

  let :generated_quiz_question do
    @quiz.quiz_questions.where(workflow_state: "generated").last
  end

  it "is a no-op for :settings_only submissions (has no quiz_data)" do
    quiz_submission.quiz_data = nil
    expect(subject.run!(quiz_submission)).to be_nil
  end

  it "is a no-op if the data fix has already been applied" do
    quiz_submission.quiz_data = []
    quiz_submission.question_references_fixed = true

    expect(subject.run!(quiz_submission)).to be_nil
  end

  it "creates missing questions" do
    expect(subject.run!(quiz_submission)).to be(true)

    expect(@quiz.quiz_questions.count).to eq(2),
                                          "it implicitly created a QuizQuestion"

    expect(generated_quiz_question).to be_present,
                                       'the created QuizQuestion has a workflow state of "generated"'
  end

  it "updates the IDs in quiz_data to point to newly created questions" do
    expect(subject.run!(quiz_submission)).to be(true)
    expect(quiz_submission.quiz_data[0][:id])
      .to eq(generated_quiz_question.id)
  end

  context "with a graded submission" do
    it "updates all grading records for affected questions" do
      quiz_submission.submission_data = [
        {
          question_id: @aq.id,
          correct: true,
          points: 1,
          answer_id: 1,
          text: "A"
        }
      ]

      expect(subject.run!(quiz_submission)).to be(true)
      expect(quiz_submission.submission_data[0][:question_id])
        .to eq(generated_quiz_question.id)
    end
  end # context: with a graded submission

  context "with a graded submission mixed with group and bank questions" do
    it "updates submission data to reflect new ids" do
      @quiz.add_assessment_questions([@aq])

      quiz_submission.submission_data = [
        {
          question_id: @aq.id,
          correct: true,
          points: 1,
          answer_id: 1,
          text: "A"
        }
      ]

      expect(subject.run!(quiz_submission)).to be(true)
      expect(quiz_submission.submission_data[0][:question_id])
        .not_to eq(@aq.id)
    end
  end

  context "with an active submission" do
    def run_with_submission_data(submission_data)
      quiz_submission.submission_data = submission_data
      subject.run!(quiz_submission)
    end

    let :submission_data do
      quiz_submission.submission_data.as_json
    end

    # question_xxx => question_yyy
    it "updates all answer records for affected questions" do
      run_with_submission_data({
                                 "question_#{@aq.id}" => "2",
                               })

      expect(submission_data).not_to include({
                                               "question_#{@aq.id}" => "2"
                                             })

      expect(submission_data).to include({
                                           "question_#{generated_quiz_question.id}" => "2",
                                         })
    end

    # question_xxx_marked => question_yyy_marked
    it 'updates the "marker"/flag records' do
      run_with_submission_data({
                                 "question_#{@aq.id}_marked" => true,
                               })

      expect(submission_data).not_to include({
                                               "question_#{@aq.id}_marked" => true,
                                             })

      expect(submission_data).to include({
                                           "question_#{generated_quiz_question.id}_marked" => true,
                                         })
    end

    # _question_xxx_read => _question_yyy_read
    it 'updates the "was read" records' do
      run_with_submission_data({
                                 "_question_#{@aq.id}_read" => true,
                               })

      expect(submission_data).not_to include({
                                               "_question_#{@aq.id}_read" => true,
                                             })

      expect(submission_data).to include({
                                           "_question_#{generated_quiz_question.id}_read" => true,
                                         })
    end

    it "does not touch irrelevant records" do
      run_with_submission_data({
                                 "question_5" => "don't touch me",
                                 "_question_5_read" => true,
                                 "validation_token" => "25ca2db4e88c8d2ef8e1429539689c45d8c7b14daa835dac5ef5a7f384c80015"
                               })

      expect(submission_data).to include({
                                           "question_5" => "don't touch me",
                                           "_question_5_read" => true,
                                           "validation_token" => "25ca2db4e88c8d2ef8e1429539689c45d8c7b14daa835dac5ef5a7f384c80015"
                                         })
    end

    context "OQAAT quizzes" do
      # next_question_path for OQAAT quizzes needs to be adjusted:
      #   /courses/.../questions/xxx => /courses/.../questions/yyy
      it 'adjusts the "next_question_path" record' do
        run_with_submission_data({
                                   "next_question_path" => "/courses/1/quizzes/1/take/questions/#{@aq.id}",
                                 })
        expect(submission_data).to include({
                                             "next_question_path" => "/courses/1/quizzes/1/take/questions/#{generated_quiz_question.id}"
                                           })
      end

      # ... but only if it's our question:
      it "does nothing for a QuizQuestion reference" do
        run_with_submission_data({
                                   "next_question_path" => "/courses/1/quizzes/1/take/questions/#{@qq.assessment_question_id}"
                                 })
        expect(submission_data).to include({
                                             "next_question_path" => "/courses/1/quizzes/1/take/questions/#{@qq.assessment_question_id}"
                                           })
      end
    end # context: OQAAT quizzes

    context "OQAAT + CantGoBack quizzes" do
      # last_question_id for OQAAT + CantGoBack needs to be adjusted as well:
      it 'adjusts "last_question_id"' do
        run_with_submission_data({
                                   "last_question_id" => @aq.id.to_s,
                                 })

        expect(submission_data).to include({
                                             "last_question_id" => generated_quiz_question.id.to_s
                                           })
      end

      it "does nothing for a QuizQuestion reference" do
        run_with_submission_data({
                                   "last_question_id" => @qq.assessment_question_id.to_s
                                 })
        expect(submission_data).to include({
                                             "last_question_id" => @qq.assessment_question_id.to_s
                                           })
      end
    end # context: OQAAT + CantGoBack quizzes

    context "with everything put together" do
      it "works" do
        run_with_submission_data({
                                   "question_#{@aq.id}" => "2",
                                   "question_#{@aq.id}_marked" => true,
                                   "_question_#{@aq.id}_read" => true,
                                   "question_5" => "don't touch me",
                                   "_question_5_read" => true,
                                   "last_question_id" => @aq.id.to_s,
                                   "next_question_path" => "/courses/1/quizzes/1/take/questions/#{@aq.id}",
                                   "validation_token" => "abcd"
                                 })

        expect(submission_data).to eq({
                                        "question_#{generated_quiz_question.id}" => "2",
                                        "question_#{generated_quiz_question.id}_marked" => true,
                                        "_question_#{generated_quiz_question.id}_read" => true,
                                        "question_5" => "don't touch me",
                                        "_question_5_read" => true,
                                        "last_question_id" => generated_quiz_question.id.to_s,
                                        "next_question_path" => "/courses/1/quizzes/1/take/questions/#{generated_quiz_question.id}",
                                        "validation_token" => "abcd"
                                      })
      end
    end # context: with everything put together
  end # context: with an active submission

  context "with multiple versions" do
    it "fixes previous versions just like the current one" do
      # this will be version 1
      quiz_submission.quiz_data = [@aq.data]
      quiz_submission.with_versioning { quiz_submission.save! }
      quiz_submission.reload
      expect(quiz_submission.versions.count).to eq(1)

      # this will be the current/latest version:
      quiz_submission.quiz_data = [@qq.data]
      quiz_submission.without_versioning { quiz_submission.save! }

      expect(subject.run!(quiz_submission)).to be(true)

      expect(quiz_submission.quiz_data[0][:id]).to eq(@qq.id)

      expect(quiz_submission.versions.get(1).model.quiz_data[0][:id])
        .to eq(generated_quiz_question.id)
    end
  end

  context "with an existing quiz question" do
    it "does not generate another, only link to the existing one" do
      @qq2 = @aq.create_quiz_question(@quiz.id)

      expect(subject.run!(quiz_submission)).to be(true)
      expect(@quiz.reload.quiz_questions.generated.count).to eq(1)
      expect(quiz_submission.quiz_data[0][:id]).to eq(@qq2.id)
    end
  end
end
