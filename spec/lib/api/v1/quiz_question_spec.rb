# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class TestableApiQuizQuestion
  class << self
    include Api
    include Api::V1::QuizQuestion

    def api_user_content(html, context = @context, user = User.new, location: nil)
      super
    end

    def api_v1_course_attachment_url(_arg)
      "some url"
    end

    def api_v1_attachment_url(_arg)
      "api/v1/files/somefile/download"
    end
  end
end

describe Api::V1::QuizQuestion do
  describe ".question_json" do
    subject do
      TestableApiQuizQuestion.question_json(
        question, user, session, context:, includes:, censored:, quiz_data:, shuffle_answers:
      )
    end

    let(:answers) { [] }
    let(:account) { Account.create! }
    let(:course) { Course.create!(account:) }
    let(:question_data) { { "answers" => answers } }
    let(:question) { Quizzes::QuizQuestion.new(question_data:) }
    let(:user) { User.new }
    let(:session) { nil }
    let(:context) { Course.create!(account:) }
    let(:includes) { [] }
    let(:censored) { false }
    let(:quiz_data) { nil }
    let(:shuffle_answers) { false }

    before do
      TestableApiQuizQuestion.instance_variable_set(:@context, course)
    end

    it { is_expected.to include("question_name" => "Question") }
    it { is_expected.to include("question_type" => "text_only_question") }
    it { is_expected.to include("question_text" => "Question text") }
    it { is_expected.to include("points_possible") }
    it { is_expected.to include("correct_comments") }
    it { is_expected.to include("incorrect_comments") }
    it { is_expected.to include("neutral_comments") }
    it { is_expected.to include("correct_comments_html") }
    it { is_expected.to include("incorrect_comments_html") }
    it { is_expected.to include("neutral_comments_html") }
    it { is_expected.to include("answers") }
    it { is_expected.to include("variables") }
    it { is_expected.to include("formulas") }
    it { is_expected.to include("answer_tolerance") }
    it { is_expected.to include("formula_decimal_places") }
    it { is_expected.to include("matches") }
    it { is_expected.to include("matching_answer_incorrect_matches") }

    context "with bogus question data" do
      let(:question_data) do
        {
          "answers" => answers,
          "bogus" => "bogus"
        }
      end

      it { is_expected.not_to include("bogus") }
    end

    context "with quiz_data" do
      let(:quiz_data) do
        [{
          "id" => question[:id],
          "question_type" => "some_other_type",
          "answers" => answers,
          "position" => 4
        }]
      end

      it { is_expected.to include("question_type" => "some_other_type") }
      it { is_expected.to include("position" => 4) }
    end

    describe "with location tagging" do
      before do
        course_with_teacher
        @course.root_account.enable_feature!(:file_association_access)
        quiz_model(course: @course)
        @q_attachment = attachment_model(context: @course)
        image_tag = "<img src='/courses/#{@course.id}/files/#{@q_attachment.id}/preview'>"
        @question = @quiz.quiz_questions.create!(
          question_data: multiple_choice_question_data.merge(
            question_text: "Baz #{image_tag}",
            correct_comments_html: "<b>corr</b> #{image_tag}",
            incorrect_comments_html: "<i>inco</i> #{image_tag}",
            neutral_comments_html: "<i>neut</i> #{image_tag}",
            answers: [
              { comments: "", comments_html: "<b>tag</b> #{image_tag}", weight: 100, text: "", html: "das text #{image_tag}", id: 1658 },
              { comments: "", comments_html: "<i>tag</i> #{image_tag}", weight: 0, text: "", html: "<b>no image</b>", id: 2903 }
            ]
          ),
          saving_user: @teacher
        )
        @quiz.generate_quiz_data
        @quiz.save
        @submission = @quiz.generate_submission(@pupil)
        TestableApiQuizQuestion.instance_variable_set(:@context, @course)
        TestableApiQuizQuestion.instance_variable_set(:@domain_root_account, @course.root_account)
        @correct_location = "location=quiz_question_#{@question.id}"
        @correct_aq_location = "location=assessment_question_#{@question.assessment_question.id}"
        @correct_submission_location = "location=quiz_submission_#{@submission.id}"
      end

      it "sets location tag on texts where necessary" do
        subject = TestableApiQuizQuestion.question_json(
          @question, @teacher, session, context: @course, includes: [:assessment_question], censored: false, quiz_data: @quiz.quiz_data, location: "quiz_question_#{@question.id}"
        )
        expect(subject["question_text"]).to include(@correct_location)
        expect(subject["correct_comments_html"]).to include(@correct_location)
        expect(subject["incorrect_comments_html"]).to include(@correct_location)
        expect(subject["neutral_comments_html"]).to include(@correct_location)
        subject["answers"].each do |a|
          expect(a["comments_html"]).to include(@correct_location)
          expect(a["html"]).to include(@correct_location) if a["id"] == 1658
          expect(a["html"]).not_to include(@correct_location) if a["id"] == 2903
        end
        expect(subject["assessment_question"]["question_data"]["question_text"]).to include(@correct_aq_location)
        expect(subject["assessment_question"]["question_data"]["correct_comments_html"]).to include(@correct_aq_location)
        expect(subject["assessment_question"]["question_data"]["incorrect_comments_html"]).to include(@correct_aq_location)
        expect(subject["assessment_question"]["question_data"]["neutral_comments_html"]).to include(@correct_aq_location)
        subject["assessment_question"]["question_data"]["answers"].each do |a|
          expect(a["comments_html"]).to include(@correct_aq_location)
          expect(a["html"]).to include(@correct_aq_location) if a["id"] == 1658
          expect(a["html"]).not_to include(@correct_aq_location) if a["id"] == 2903
        end
      end

      it "sets location tag for student" do
        subject = TestableApiQuizQuestion.question_json(
          @question, @pupil, session, context: @course, censored: true, quiz_data: @quiz.quiz_data, location: "quiz_submission_#{@submission.id}"
        )
        expect(subject["question_text"]).to include(@correct_submission_location)
        subject["answers"].each do |a|
          expect(a["html"]).to include(@correct_submission_location) if a["id"] == 1658
        end
      end

      it "does not set location tag if FF is off" do
        @correct_location = "location="
        @course.root_account.disable_feature!(:file_association_access)
        subject = TestableApiQuizQuestion.question_json(
          @question, @teacher, session, context: @course, includes: [:assessment_question], censored: false, quiz_data: @quiz.quiz_data, location: "quiz_question_#{@question.id}"
        )
        expect(subject["question_text"]).not_to include(@correct_location)
        expect(subject["correct_comments_html"]).not_to include(@correct_location)
        expect(subject["incorrect_comments_html"]).not_to include(@correct_location)
        expect(subject["neutral_comments_html"]).not_to include(@correct_location)
        subject["answers"].each do |a|
          expect(a["comments_html"]).not_to include(@correct_location)
          expect(a["html"]).not_to include(@correct_location)
        end
      end
    end

    describe "when verifiers and asset location should be set" do
      let(:account) { Account.create! }
      let(:user) { User.create }
      let(:course) { Course.create!(account:) }
      let(:context) { course }

      before do
        allow_any_instance_of(UserContent::FilesHandler::ProcessedUrl).to receive(:in_app).and_return(false)
        TestableApiQuizQuestion.instance_variable_set(:@context, course)
        attachment_model(context: course)
        question_data = {
          "answers" => answers,
          "question_type" => "text_only_questions",
          "question_text" => "<img src='/courses/#{course.id}/files/#{@attachment.id}' >",
        }
        @question = Quizzes::QuizQuestion.new(question_data:)
        TestableApiQuizQuestion.instance_variable_set(:@domain_root_account, @attachment.root_account)
      end

      context "with a file attachment and double testing verifiers" do
        double_testing_with_disable_adding_uuid_verifier_in_api_ff do
          it "checks verifier string on attachment urls" do
            subject = TestableApiQuizQuestion.question_json(
              @question, user, session, context:, includes:, censored:, quiz_data:, shuffle_answers:
            )
            if disable_adding_uuid_verifier_in_api
              expect(subject["question_text"]).not_to include("verifier=#{@attachment.uuid}")
            else
              expect(subject["question_text"]).to include("verifier=#{@attachment.uuid}")
            end
          end
        end
      end
    end
  end

  describe "as a student" do
    subject { TestableApiQuizQuestion.question_json(question, user, session, context: nil, includes: [], censored: true) }

    let(:answers) { [] }
    let(:question) { Quizzes::QuizQuestion.new(question_data:) }
    let(:user) { User.new }
    let(:account) { Account.create! }
    let(:course) { Course.create!(account:) }
    let(:session) { nil }

    before do
      TestableApiQuizQuestion.instance_variable_set(:@context, course)
    end

    describe "text_only_questions" do
      let(:question_data) { { "answers" => answers, "question_type" => "text_only_questions" } }

      it { is_expected.not_to include("answers") }
      it { is_expected.not_to include("matching_answer_incorrect_matches") }
      it { is_expected.not_to include("points_possible") }
      it { is_expected.not_to include("correct_comments") }
      it { is_expected.not_to include("incorrect_comments") }
      it { is_expected.not_to include("neutral_comments") }
      it { is_expected.not_to include("correct_comments_html") }
      it { is_expected.not_to include("incorrect_comments_html") }
      it { is_expected.not_to include("neutral_comments_html") }
      it { is_expected.to include("variables") }
      it { is_expected.to include("answer_tolerance") }
      it { is_expected.to include("formula_decimal_places") }
      it { is_expected.to include("formulas") }
      it { is_expected.to include("question_name" => "Question") }
      it { is_expected.to include("question_type" => "text_only_questions") }
      it { is_expected.to include("question_text" => "Question text") }
      it { is_expected.to include("matches") }
    end

    describe "calculated_questions" do
      let(:question_data) { { "answers" => answers, "question_type" => "calculated_question" } }

      it { is_expected.to include("answers") }
      it { is_expected.to include("variables") }
      it { is_expected.to include("formulas") }
      it { is_expected.to include("answer_tolerance") }
      it { is_expected.to include("formula_decimal_places") }
    end

    describe "multiple_dropdowns_question" do
      let(:question_data) { { "answers" => answers, "question_type" => "multiple_dropdowns_question" } }

      it { is_expected.to include("answers") }
    end
  end

  describe "regrade_option" do
    let(:account) { Account.create! }
    let(:user) { User.create }
    let(:course) { Course.create!(account:) }
    let(:quiz) do
      quiz = course.quizzes.create!(title: "Quiz")
      quiz.publish!
      quiz
    end

    let(:question) do
      quiz.quiz_questions.create!(question_data: { "name" => "test question 1", "answers" => [{ "id" => 1 }, { "id" => 2 }], :position => 1 })
    end

    context "when a valid regrade_option is passed" do
      it "creates regrades with the regrade_option" do
        question.question_data = { regrade_option: "full_credit", regrade_user: user }
        expect(quiz.current_quiz_question_regrades.first.regrade_option).to eq "full_credit"
      end
    end

    context "when an invalid regrade_option is passed" do
      it "creates no regrades" do
        question.question_data = { regrade_option: "false", regrade_user: user }
        expect(quiz.current_quiz_question_regrades.count).to be 0
      end
    end
  end
end
