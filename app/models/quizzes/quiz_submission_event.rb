#
# Copyright (C) 2014 Instructure, Inc.
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

class Quizzes::QuizSubmissionEvent < ActiveRecord::Base
  include CanvasPartman::Concerns::Partitioned

  EXPORTABLE_ASSOCIATIONS = [ :quiz_submission ]
  EXPORTABLE_ATTRIBUTES = [
    :id,
    :quiz_submission_id,

    # @property [Integer] attempt
    #
    # The quiz submission attempt in which the event was recorded.
    :attempt,

    # @property [AnswerRecord[]]
    #
    # Set of answers to all quiz questions at the time the event was
    # recorded. See the relevant object for what's inside the :answer
    # field.
    :answers,

    # @property [String] event_type
    #
    # The "action" this event describes. Right now the only supported event
    # is EVT_ANSWERED.
    :event_type,

    # @property [Hash|String|Nil] data
    #
    # The extra serialized data for this event.
    :data,

    # @property [Integer] attempt
    #
    # The quiz submission attempt in which the event was recorded.
    :created_at
  ]

  # An event describing the student choosing an answer to a question.
  EVT_ANSWERED = 'answered'.freeze
  RE_QUESTION_ANSWER_FIELD = /^question_(\d+)_?/

  belongs_to :quiz_submission, class_name: 'Quizzes::QuizSubmission'

  serialize :answers, JSON

  scope :predecessor_of, ->(event) {
    where('quiz_submission_id=:id AND attempt=:attempt AND created_at < :created_at', {
      id: event.quiz_submission_id,
      attempt: event.attempt,
      created_at: event.created_at
    }).order('created_at DESC').limit(1)
  }

  partitioned do |t, table_name|
    index_ns = table_name.sub('quiz_submission_events', 'qse')

    t.index :created_at,
      name: "#{index_ns}_idx_on_created_at"

    t.index [ :quiz_submission_id, :attempt, :created_at ],
      name: "#{index_ns}_predecessor_locator_idx"

    t.foreign_key :quiz_submissions
  end

  after_initialize :set_defaults

  class << self
    # Main API for building a new event.
    #
    # @param [Hash] submission_data
    #
    #  Similar to what you pass for generating snapshots, which is the payload
    #  that gets sent by the quiz-taking front-end.
    #
    # @return [Quizzes::QuizSubmissionEvent]
    def build_from_submission_data(submission_data, quiz_data)
      submission_data.stringify_keys!

      self.new.tap do |event|
        event.attempt = submission_data['attempt']
        event.event_type = infer_event_type(submission_data)
        event.answers = extract_answers(submission_data, quiz_data)
        event.created_at = Time.now
      end
    end

    def infer_event_type(submission_data)
      # TODO: tell the difference between auto-submitted backups and backups
      # submitted when students changed an answer
      EVT_ANSWERED
    end

    def extract_answers(submission_data, quiz_data)
      quiz_questions = begin
        quiz_question_ids = submission_data.keys.map do |key|
          if key =~ RE_QUESTION_ANSWER_FIELD
            $1
          end
        end.compact.map(&:to_s).uniq

        quiz_data.select do |qq|
          quiz_question_ids.include?(qq['id'].to_s)
        end.map(&:symbolize_keys)
      end

      quiz_questions.reduce([]) do |answers, qq|
        serializer = ::Quizzes::QuizQuestion::AnswerSerializers.serializer_for(qq)
        serializer.override_question_data(qq)

        answer = serializer.deserialize(submission_data)

        if answer.present?
          answers << {
            "quiz_question_id" => qq[:id].to_s,
            "answer" => answer
          }
        end

        answers
      end
    end
  end

  def set_defaults
    self.answers ||= []
    self.created_at ||= Time.now
  end

  # Given another event (should be one that has happened before this one),
  # try to optimize the answer records tracked by this event by removing what
  # has already been tracked by the predecessor, keeping only what was really
  # modified.
  def optimize_answers(previous_event=self.predecessor)
    if previous_event.blank?
      return false
    end

    original_record_count = self.answers.length

    self.answers.keep_if do |answer_record|
      previous_answer_record = previous_event.answers.detect do |previous_answer_record|
        previous_answer_record['quiz_question_id'] == answer_record['quiz_question_id']
      end

      if previous_answer_record.blank? # newly answered question
        true
      else # we don't want identical answers in:
        !identical_answer_records?(answer_record, previous_answer_record)
      end
    end

    original_record_count != self.answers.length
  end

  # After optimizing an event, it could become "empty" as in it does not
  # represent any action that its predecessor isn't already.
  #
  # If this returns true, you can safely skip storing this event.
  def empty?
    case self.event_type
    when EVT_ANSWERED
      self.answers.blank?
    else
      false
    end
  end

  # Use this to figure out whether two events are identical, and if they are,
  # then you don't need to store both and could save some space.
  def ==(rhs)
    return false if self.event_type != rhs.event_type

    case self.event_type
    when EVT_ANSWERED
      answers.length == rhs.answers.length &&
      answers.to_json == rhs.answers.to_json
    else
      super(rhs)
    end
  end

  # Attempt to locate the event that was recorded right before this one so that
  # we can optimize against.
  def predecessor
    self.class.predecessor_of(self).first
  end

  private

  def identical_answer_records?(a,b)
    a['answer'].to_json == b['answer'].to_json
  end
end
