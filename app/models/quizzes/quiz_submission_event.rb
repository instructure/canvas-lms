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

    # @property [String] event_type
    #
    # The "action" this event describes. Right now the only supported event
    # is EVT_QUESTION_ANSWERED.
    :event_type,

    # @property [Hash|String|Nil] event_data
    #
    # The extra serialized data for this event.
    :event_data,

    # @property [DateTime] client_timestamp
    #
    # The timestamp at which the event was recorded at the client.
    :client_timestamp,

    # @property [DateTime] created_at
    #
    # The timestamp at which the event was recorded to the database.
    :created_at,

    # @property [AnswerRecord[]]
    # @alias event_data
    #
    # Set of answers to all quiz questions at the time the event was
    # recorded. See the relevant object for what's inside the :answer
    # field.
    #
    # This is present only for EVT_QUESTION_ANSWERED events.
    :answers
  ]

  # An event describing the student choosing an answer to a question.
  EVT_QUESTION_ANSWERED = "question_answered".freeze
  EVT_QUESTION_FLAGGED = "question_flagged".freeze
  # An event for every new submission created
  EVT_SUBMISSION_CREATED = "submission_created".freeze

  belongs_to :quiz_submission, class_name: 'Quizzes::QuizSubmission'

  serialize :event_data, JSON

  # for a more meaningful API when dealing with EVT_QUESTION_ANSWERED events:
  alias_attribute :answers, :event_data

  after_initialize do
    # We ALWAYS want this to be set, otherwise the event won't be stored in the
    # right partition.
    self.created_at ||= Time.now
  end

  # After optimizing an event, it could become "empty" as in it does not
  # represent any action that its predecessor isn't already.
  #
  # If this returns true, you can safely skip storing this event.
  def empty?
    case self.event_type
    when EVT_QUESTION_ANSWERED
      self.answers.nil? || self.answers.empty?
    else
      false
    end
  end
end
