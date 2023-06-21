# frozen_string_literal: true

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

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do
    provider_state "a quiz" do
      set_up do
        course = Pact::Canvas.base_state.course
        quiz_model(course:)
      end
    end

    provider_state "a migrated quiz" do
      set_up do
        course = Pact::Canvas.base_state.course
        quiz = quiz_model(course:)
        quiz.migration_id = "i09d7615b43e5f35589cc1e2647dd345f"
        quiz.save!
      end
    end

    # Student ID: 8 ("Mobile Student")
    # Course ID: 3
    # Quiz ID: 1
    # Quiz submission ID: 1
    provider_state "mobile course with quiz" do
      set_up do
        # Access our mobile course and student
        mcourse = Pact::Canvas.base_state.mobile_courses[1]
        mstudent = Pact::Canvas.base_state.mobile_student

        # create a quiz with three different types of questions
        quiz = quiz_model(course: mcourse, title: "mobile quiz", description: "a quiz for mobile tests", due_at: 1.week.from_now)
        quiz.workflow_state = "available"
        quiz.quiz_questions.create!({ question_data: MobileQuizQuestionData.mobile_multiple_choice_question_data })
        quiz.quiz_questions.create!({ question_data: MobileQuizQuestionData.mobile_true_false_question_data })
        quiz.quiz_questions.create!({ question_data: MobileQuizQuestionData.mobile_matching_question_data })
        quiz.generate_quiz_data
        quiz.published_at = 3.hours.ago
        quiz.time_limit = 300
        quiz.allowed_attempts = 3
        quiz.show_correct_answers = true
        quiz.show_correct_answers_at = 1.day.ago
        quiz.hide_correct_answers_at = 2.days.from_now
        quiz.points_possible = 145
        quiz.ip_filter = "192.168.1.10"
        quiz.unlock_at = 2.hours.from_now
        quiz.lock_at = 8.days.from_now
        quiz.access_code = "abcd"
        quiz.require_lockdown_browser_for_results = false
        quiz.require_lockdown_browser = false
        quiz.only_visible_to_overrides = false
        quiz.anonymous_submissions = false
        quiz.save!

        # Create a quiz submission
        qsub = Quizzes::SubmissionManager.new(quiz).find_or_create_submission(mstudent)
        qsub.quiz_data = [
          MobileQuizQuestionData.mobile_multiple_choice_question_data,
          MobileQuizQuestionData.mobile_true_false_question_data,
          MobileQuizQuestionData.mobile_matching_question_data
        ]
        qsub.started_at = 10.minutes.ago
        qsub.attempt = 1
        qsub.submission_data = [
          { points: 50, text: "c", question_id: 1, correct: true, answer_id: 1658 },
          { points: 45, text: "True", question_id: 2, correct: false, answer_id: 8403 },
          { points: 50, text: "", question_id: 3, correct: true, answer_7396: "6061", answer_6081: "3855" }
        ]
        qsub.score = 100
        qsub.finished_at = 5.minutes.ago
        qsub.workflow_state = "complete"
        qsub.end_at = 1.day.from_now
        qsub.extra_attempts = 0
        qsub.extra_time = 0
        qsub.score_before_regrade = 0
        qsub.manually_unlocked = false
        qsub.has_seen_results = true

        # Don't know exactly why this is necessary
        qsub.submission = quiz.assignment.find_or_create_submission(mstudent.id)
        qsub.submission.quiz_submission = qsub
        qsub.submission.submission_type = "online_quiz"
        qsub.submission.submitted_at = qsub.finished_at

        qsub.with_versioning(true) do
          qsub.save!
        end
      end
    end
  end
end

module MobileQuizQuestionData
  # Adapted from multiple_choice_question_data in quiz_factory
  def self.mobile_multiple_choice_question_data
    {
      "name" => "Question",
      "correct_comments" => "",
      "question_type" => "multiple_choice_question",
      "assessment_question_id" => 4,
      "neutral_comments" => "",
      "incorrect_comments" => "",
      "question_name" => "Question",
      "points_possible" => 50.0,
      "answers" => [
        { "comments" => "", "weight" => 0, "text" => "a", "html" => "html", "id" => 2405, "blank_id" => "blank_id" },
        { "comments" => "", "weight" => 0, "text" => "b", "html" => "html", "id" => 8544, "blank_id" => "blank_id" },
        { "comments" => "", "weight" => 100, "text" => "c", "html" => "html", "id" => 1658, "blank_id" => "blank_id" },
        { "comments" => "", "weight" => 0, "text" => "d", "html" => "html", "id" => 2903, "blank_id" => "blank_id" }
      ],
      "question_text" => "Which of these is the correct answer?",
      "id" => 1,
      "position" => 1
    }.with_indifferent_access
  end

  # Adapted from true_false_question_data in quiz_factory
  def self.mobile_true_false_question_data
    {
      "name" => "Question",
      "correct_comments" => "",
      "question_type" => "true_false_question",
      "assessment_question_id" => 8_197_062,
      "neutral_comments" => "",
      "incorrect_comments" => "",
      "question_name" => "Question",
      "points_possible" => 45,
      "answers" => [
        { "comments" => "", "weight" => 0, "text" => "True", "html" => "html", "id" => 8403, "blank_id" => "blank_id" },
        { "comments" => "", "weight" => 100, "text" => "False", "html" => "html", "id" => 8950, "blank_id" => "blank_id" }
      ],
      "question_text" => "4 is greater than 5",
      "id" => 2,
      "position" => 2
    }.with_indifferent_access
  end

  # Adapted from matching_question_data in quiz_factory
  def self.mobile_matching_question_data
    {
      "name" => "Question",
      "correct_comments" => "",
      "question_type" => "matching_question",
      "assessment_question_id" => 4,
      "neutral_comments" => "",
      "incorrect_comments" => "",
      "question_name" => "Question",
      "points_possible" => 50.0,
      "matches" => [
        { "match_id" => 6061, "text" => "1" },
        { "match_id" => 3855, "text" => "2" }
      ],
      "answers" => [
        { "left" => "a", "comments" => "", "match_id" => 6061, "text" => "a", "id" => 7396, "right" => "1", "html" => "html", "blank_id" => "blank_id" },
        { "left" => "b", "comments" => "", "match_id" => 3855, "text" => "b", "id" => 6081, "right" => "2", "html" => "html", "blank_id" => "blank_id" }
      ],
      "question_text" => "<p>Match these</p>",
      "id" => 3,
      "position" => 3
    }.with_indifferent_access
  end
end
