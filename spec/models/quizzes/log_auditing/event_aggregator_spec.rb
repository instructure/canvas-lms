#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::LogAuditing::EventAggregator do
  def build_course_quiz_qs
    teacher_in_course
    @quiz = Quizzes::Quiz.create!(:title => 'quiz', :context => @course)
    @questions = 2.times.map do
      @quiz.quiz_questions.create!(:question_data => short_answer_question_data)
    end
    @qs = @quiz.generate_submission(student_in_course.user)
  end
  def build_an_event(event_type, event_data, time_step=0)
    Quizzes::QuizSubmissionEvent.create do |event|
      event.quiz_submission_id = @qs.id
      event.event_type = event_type
      event.event_data = event_data
      event.created_at = Time.now + time_step
      event.attempt = @qs.attempt
    end
  end
  def build_out_database_events
    event_types = [
      Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED,
      Quizzes::QuizSubmissionEvent::EVT_QUESTION_FLAGGED,
      # build an additional event types to ensure that we are properly filtering for submission_data events
      'page_blurred'
    ]
    event_data_examples = {
      'page_blurred' => [nil, nil, nil, nil],
      Quizzes::QuizSubmissionEvent::EVT_QUESTION_FLAGGED => [
        {"quiz_question_id" => @questions[0].id, 'flagged' => true},
        {"quiz_question_id" => @questions[0].id, 'flagged' => false},
        {"quiz_question_id" => @questions[1].id, 'flagged' => true},
        {"quiz_question_id" => @questions[1].id, 'flagged' => false},
      ],
      Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED => [
        { 'quiz_question_id'=> @questions[0].id, "answer"=> "hello" },
        { 'quiz_question_id'=> @questions[0].id, 'answer'=> "goodbye" },
        { 'quiz_question_id'=> @questions[1].id, "answer"=> "hello" },
        { 'quiz_question_id'=> @questions[1].id, "answer"=> "goodbye" },
      ]
    }
    # Build out each event in pairs to test that we are aggregating correctly
    event_types.each.with_index do |event_type,i|
      build_an_event(event_type, event_data_examples[event_type][0], i*2-1)
      build_an_event(event_type, event_data_examples[event_type][1], i*2)
    end
    @events = Quizzes::QuizSubmissionEvent.all
  end

  context "without events" do
    before :once do
      build_course_quiz_qs
    end
    it "returns no events gracefully" do
      @aggregated_submission_data = subject.run(@qs.id, @qs.attempt, Time.now)
      expect(@aggregated_submission_data).to be_a(Hash)
      expect(@aggregated_submission_data).to eq({})
    end
  end
  context "with set of events" do
    let(:latest_submission_data) { {"question_#{@questions[0].id}"=>"goodbye", "question_#{@questions[0].id}_marked"=>false} }
    before :once do
      build_course_quiz_qs
      build_out_database_events
    end
    it "reduces all events to submission_data" do
      @aggregated_submission_data = subject.run(@qs.id, @qs.attempt, @events.last.created_at)
      expect(@aggregated_submission_data).to eq(latest_submission_data)
    end
    it "builds submission_data up to the specified timestamp, inclusive" do
      submission_data = subject.run(@qs.id, @qs.attempt, @events[0].created_at)
      expect(submission_data).to eq ({"question_#{@questions[0].id}"=>"hello"})
    end
    it "replaces previous content in submission_data build" do
      submission_data = subject.run(@qs.id, @qs.attempt, @events[2].created_at)
      expect(submission_data).to eq ({"question_#{@questions[0].id}"=>"goodbye", "question_#{@questions[0].id}_marked"=>true})
    end
  end
end