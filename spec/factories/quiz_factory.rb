# coding: utf-8
#
# Copyright (C) 2011 Instructure, Inc.
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

def quiz_model(opts={})
  @context ||= opts.delete(:course) || course_model(:reusable => true)
  @quiz = @context.quizzes.build(valid_quiz_attributes.merge(opts))
  @quiz.published_at = Time.now
  @quiz.workflow_state = 'available'
  @quiz.save!
  @quiz
end

def valid_quiz_attributes
  {
    :title => "Test Quiz",
    :description => "Test Quiz Description"
  }
end

def quiz_with_submission(complete_quiz = true)
  test_data = [{:correct_comments=>"", :assessment_question_id=>nil, :incorrect_comments=>"", :question_name=>"Question 1", :points_possible=>1, :question_text=>"Which book(s) are required for this course?", :name=>"Question 1", :id=>128, :answers=>[{:weight=>0, :text=>"A", :comments=>"", :id=>1490}, {:weight=>0, :text=>"B", :comments=>"", :id=>1020}, {:weight=>0, :text=>"C", :comments=>"", :id=>7051}], :question_type=>"multiple_choice_question"}]
  @course ||= course_model(:reusable => true)
  @student ||= user_model
  @course.enroll_student(@student).accept
  @quiz = @course.quizzes.create
  @quiz.workflow_state = "available"
  @quiz.quiz_data = test_data
  @quiz.save!
  @quiz
  @qsub = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
  @qsub.quiz_data = test_data
  @qsub.submission_data = complete_quiz ? [{:points=>0, :text=>"7051", :question_id=>128, :correct=>false, :answer_id=>7051}] : test_data.first
  # {"context_id"=>"3", "text_after_answers"=>"", "context_type"=>"Course", "attempt"=>1, "user_id"=>"3", "controller"=>"quiz_submissions", "cnt"=>1, "course_id"=>"3", "quiz_id"=>"6", "question_text"=>"<p>true?</p>"}
  @qsub.workflow_state = 'complete' if complete_quiz
  @qsub.with_versioning(true) do
    @qsub.save!
  end
  @qsub
end

def multiple_choice_question_data
  {"name"=>"Question", "correct_comments"=>"", "question_type"=>"multiple_choice_question", "assessment_question_id"=>4, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>50.0, "answers"=>[{"comments"=>"", "weight"=>0, "text"=>"a", "id"=>2405}, {"comments"=>"", "weight"=>0, "text"=>"b", "id"=>8544}, {"comments"=>"", "weight"=>100, "text"=>"c", "id"=>1658}, {"comments"=>"", "weight"=>0, "text"=>"d", "id"=>2903}], "question_text"=>"<p>test</p>", "id" => 1}.with_indifferent_access
end

def true_false_question_data
  {"name"=>"Question", "correct_comments"=>"", "question_type"=>"true_false_question", "assessment_question_id"=>8197062, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>45, "answers"=>[{"comments"=>"", "weight"=>0, "text"=>"True", "id"=>8403}, {"comments"=>"", "weight"=>100, "text"=>"False", "id"=>8950}], "question_text"=>"<p>test</p>", "id" => 1}.with_indifferent_access
end

def short_answer_question_data
  {"name"=>"Question", "correct_comments"=>"", "question_type"=>"short_answer_question", "assessment_question_id"=>8197062, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>16.5, "answers"=>[{"comments"=>"", "weight"=>100, "text"=>"stupid", "id"=>7100}, {"comments"=>"", "weight"=>100, "text"=>"dumb", "id"=>2159}], "question_text"=>"<p>there's no such thing as a _____ question</p>", "id" => 1}.with_indifferent_access
end

def short_answer_question_data_one_blank
  {"name"=>"Question", "correct_comments"=>"", "question_type"=>"short_answer_question", "assessment_question_id"=>8197062, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>16.5, "answers"=>[{"comments"=>"", "weight"=>100, "text"=>"stupid", "id"=>7100}, {"comments"=>"", "weight"=>100, "text"=>"dumb", "id"=>2159}, {"comments"=>"", "weight"=>100, "text"=>"", "id"=>9090}], "question_text"=>"<p>there's no such thing as a _____ question</p>", "id" => 1}.with_indifferent_access
end

def essay_question_data
  {"name"=>"Question", "correct_comments"=>"", "question_type"=>"essay_question", "comments"=>nil, "assessment_question_id"=>8197062, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>13.6, "answers"=>[], "question_text"=>"<p>Please summarize the history of the world in 3 sentences</p>", "id" => 1}.with_indifferent_access
end

def text_only_question_data
  { "question_type" => "text_only_question", "id" => 3 }.with_indifferent_access
end

def multiple_dropdowns_question_data
  {"position"=>3, "correct_comments"=>"", "name"=>"Question 3", "question_type"=>"multiple_dropdowns_question", "assessment_question_id"=>1695442, "neutral_comments"=>"", "incorrect_comments"=>"", "id"=>1630873, "question_name"=>"Question 3", "points_possible"=>0.5, "original_question_text"=>"[structure1] [event1] [structure2] [structure3] [structure4] [structure5] [structure6] [event2] [structure7]",  "answers"=>[
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>4390, "blank_id"=>"structure1"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>1522, "blank_id"=>"structure1"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>7446, "blank_id"=>"structure1"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>279, "blank_id"=>"structure1"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>3390, "blank_id"=>"event1"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>5498, "blank_id"=>"event1"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>6955, "blank_id"=>"structure2"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>1228, "blank_id"=>"structure2"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>6578, "blank_id"=>"structure2"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>7676, "blank_id"=>"structure3"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>5213, "blank_id"=>"structure3"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>5988, "blank_id"=>"structure3"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>7604, "blank_id"=>"structure4"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>9532, "blank_id"=>"structure4"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>4772, "blank_id"=>"structure4"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>3353, "blank_id"=>"event2"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>599, "blank_id"=>"event2"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>9908, "blank_id"=>"structure5"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>878, "blank_id"=>"structure5"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>670, "blank_id"=>"structure5"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>4351, "blank_id"=>"structure5"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>6994, "blank_id"=>"structure6"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>1883, "blank_id"=>"structure6"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>4717, "blank_id"=>"structure6"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>7697, "blank_id"=>"structure6"},
    {"comments"=>"", "weight"=>100, "text"=>"y", "id"=>1121, "blank_id"=>"structure7"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>9570, "blank_id"=>"structure7"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>4764, "blank_id"=>"structure7"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>3477, "blank_id"=>"structure7"},
    {"comments"=>"", "weight"=>0, "text"=>"n", "id"=>461, "blank_id"=>"structure7"}
  ], "question_text"=>"[structure1] [event1] [structure2] [structure3] [structure4] [structure5] [structure6] [event2] [structure7]"}.with_indifferent_access
end

# @param [Hash] options
# @param [Boolean] options.answer_parser_compatibility
#   Set this to true if you want the fixture to be compatible with
#   QuizQuestion::AnswerParsers::Matching.
def matching_question_data(options = {})
  data = {"id" => 1, "name"=>"Question", "correct_comments"=>"", "question_type"=>"matching_question", "assessment_question_id"=>4, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>50.0, "matches"=>[{"match_id"=>6061, "text"=>"1"}, {"match_id"=>3855, "text"=>"2"}, {"match_id"=>1397, "text"=>"1"}, {"match_id"=>2369, "text"=>"3"}, {"match_id"=>6065, "text"=>"4"}, {"match_id"=>5779, "text"=>"5"}, {"match_id"=>3562, "text"=>"6"}, {"match_id"=>1500, "text"=>"7"}, {"match_id"=>8513, "text"=>"8"}, {"match_id" => 6067, "text" => "a2"}, {"match_id" => 6068, "text" => "a3"}, {"match_id" => 6069, "text" => "a4"}], "answers"=>[
    {"left"=>"a", "comments"=>"", "match_id"=>6061, "text"=>"a", "id"=>7396, "right"=>"1"},
    {"left"=>"b", "comments"=>"", "match_id"=>3855, "text"=>"b", "id"=>6081, "right"=>"2"},
    {"left"=>"ca", "comments"=>"", "match_id"=>1397, "text"=>"ca", "id"=>4224, "right"=>"1"},
    {"left"=>"a2", "comments"=>"", "match_id"=>6067, "text"=>"a", "id"=>7397, "right"=>"a2"},
    {"left"=>"a3", "comments"=>"", "match_id"=>6068, "text"=>"a", "id"=>7398, "right"=>"a3"},
    {"left"=>"a4", "comments"=>"", "match_id"=>6069, "text"=>"a", "id"=>7399, "right"=>"a4"},
  ], "question_text"=>"<p>Test Question</p>"}.with_indifferent_access

  if options[:answer_parser_compatibility]
    data['answers'].each do |record|
      record['answer_match_left'] = record['left']
      record['answer_match_text'] = record['text']
      record['answer_match_right'] = record['right']
      record['answer_comments'] = record['comments']

      %w[ left text right comments ].each { |k| record.delete k }
    end

    # match#1397 has a duplicate text with #7396 that needs to be adjusted
    i = data['matches'].index { |record| record['match_id'] == 1397 }
    data['matches'][i]['text'] = '_1'
    i = data['answers'].index { |record| record['match_id'] == 1397 }
    data['answers'][i]['text'] = '_1'
  end

  data
end

def numerical_question_data
  {"name"=>"Question", "correct_comments"=>"", "question_type"=>"numerical_question", "assessment_question_id"=>8197062, "neutral_comments"=>"", "incorrect_comments"=>"", "question_name"=>"Question", "points_possible"=>26.2, "answers"=>[
    {"exact"=>4, "comments"=>"", "numerical_answer_type"=>"exact_answer", "margin"=>0, "weight"=>100, "text"=>"", "id"=>9222},
    {"exact"=>-4, "comments"=>"", "numerical_answer_type"=>"exact_answer", "margin"=>0, "weight"=>100, "text"=>"", "id"=>997},
    {"comments"=>"", "numerical_answer_type"=>"range_answer", "weight"=>100, "text"=>"", "id"=>9370, "end"=>4.1, "start"=>3.9},
    {"exact"=>-4, "comments"=>"", "numerical_answer_type"=>"exact_answer", "margin"=>0.1, "weight"=>100, "text"=>"", "id"=>5450}
  ], "question_text"=>"<p>abs(x) = 4</p>", "id" => 1}.with_indifferent_access
end

def calculated_question_data
  {"name"=>"Question",
   "correct_comments"=>"",
   "answer_tolerance"=>0.02,
   "question_type"=>"calculated_question",
   "formulas"=>[{"formula"=>"5 + (x - y)"}],
   "assessment_question_id"=>8197062,
   "variables"=>
    [{"name"=>"x", "scale"=>2, "max"=>7, "min"=>2},
     {"name"=>"y", "scale"=>0, "max"=>23, "min"=>17}],
   "neutral_comments"=>"",
   "incorrect_comments"=>"",
   "question_name"=>"Question",
   "points_possible"=>26.2,
   "formula_decimal_places"=>2,
   "answers"=> [
     {"variables"=>[{"name"=>"x", "value"=>4.3}, {"name"=>"y", "value"=>21}],
      "weight"=>100,
      "id"=>6396,
      "answer"=>-11.7},
    ],
   "question_text"=>"<p>What is 5 plus [x] - [y]</p>",
   "id" => 1}.with_indifferent_access
end

# @param [Hash] options
# @param [Boolean] options.answer_parser_compatibility
#   Set this to true if you want the fixture to be compatible with
#   QuizQuestion::AnswerParsers::MultipleAnswers.
def multiple_answers_question_data(options = {})
  data = {"name"=>"Question",
   "correct_comments"=>"",
   "question_type"=>"multiple_answers_question",
   "assessment_question_id"=>8197062,
   "neutral_comments"=>"",
   "incorrect_comments"=>"",
   "question_name"=>"Question",
   "points_possible"=>50,
   "answers"=>
    [{"comments"=>"", "weight"=>100, "text"=>"5", "id"=>9761},
     {"comments"=>"", "weight"=>0, "text"=>"cat", "id"=>3079},
     {"comments"=>"", "weight"=>100, "text"=>"8", "id"=>5194},
     {"comments"=>"", "weight"=>100, "text"=>"37.5", "id"=>166},
     {"comments"=>"", "weight"=>0, "text"=>"airplane", "id"=>4739},
     {"comments"=>"", "weight"=>100, "text"=>"114", "id"=>2196},
     {"comments"=>"", "weight"=>100, "text"=>"869", "id"=>8982},
     {"comments"=>"", "weight"=>100, "text"=>"431", "id"=>9701},
     {"comments"=>"", "weight"=>0, "text"=>"schadenfreude", "id"=>7381}],
   "question_text"=>"<p>which of these are numbers?</p>", "id" => 1}.with_indifferent_access

  if options[:answer_parser_compatibility]
    data['answers'].each do |record|
      record['answer_weight'] = record['weight']
    end
  end

  data
end

def fill_in_multiple_blanks_question_data
  {:position=>1, :name=>"Question 1", :correct_comments=>"", :question_type=>"fill_in_multiple_blanks_question", :assessment_question_id=>7903, :incorrect_comments=>"", :neutral_comments=>"", :id=>1, :points_possible=>50, :question_name=>"Question 1", :answers=>[
    {:comments=>"", :text=>"control", :weight=>100, :id=>3950, :blank_id=>"answer1"},
    {:comments=>"", :text=>"controll", :weight=>100, :id=>9177, :blank_id=>"answer1"},
    {:comments=>"", :text=>"patrol", :weight=>100, :id=>9181, :blank_id=>"answer2"},
    {:comments=>"", :text=>"soul", :weight=>100, :id=>3733, :blank_id=>"answer3"},
    {:comments=>"", :text=>"tolls", :weight=>100, :id=>9756, :blank_id=>"answer4"},
    {:comments=>"", :text=>"toll", :weight=>100, :id=>7829, :blank_id=>"answer4"},
    {:comments=>"", :text=>"explode", :weight=>100, :id=>3046, :blank_id=>"answer5"},
    {:comments=>"", :text=>"assplode", :weight=>100, :id=>5301, :blank_id=>"answer5"},
    {:comments=>"", :text=>"old", :weight=>100, :id=>3367, :blank_id=>"answer6"}
  ], :question_text=>"<p><span>Ayo my quality [answer1], captivates your party [answer2]. </span>Your mind, body, and [answer3]. For whom the bell [answer4], let the rhythm [answer5]. Big, bad, and bold b-boys of [answer6].</p>"}.with_indifferent_access
end

def fill_in_multiple_blanks_question_one_blank_data
  { :name => "Question", :question_type => "fill_in_multiple_blanks_question", :id => 2, :points_possible => 3.75, :answers => [
    { :text => "stupid", :weight => 100, :id => 1234, :blank_id => "myblank" },
    { :text => "dumb", :weight => 100, :id => 1235, :blank_id => "myblank" },
  ], :question_text => "<p>there's no such thing as a [myblank] question</p>" }.with_indifferent_access
end
