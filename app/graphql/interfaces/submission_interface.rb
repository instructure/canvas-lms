#
# Copyright (C) 2019 - present Instructure, Inc.
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
module Interfaces::SubmissionInterface
  include GraphQL::Schema::Interface
  description 'Types for submission or submission history'

  class LatePolicyStatusType < Types::BaseEnum
    graphql_name 'LatePolicyStatusType'
    value 'late'
    value 'missing'
    value 'none'
  end

  def submission
    object
  end
  private :submission

  def protect_submission_grades(attr)
    load_association(:assignment).then do
      if submission.user_can_read_grade?(current_user, session)
        submission.send(attr)
      end
    end
  end
  private :protect_submission_grades

  field :assignment, Types::AssignmentType, null: true
  def assignment
    load_association(:assignment)
  end

  field :user, Types::UserType, null: true
  def user
    load_association(:user)
  end

  field :attempt, Integer, null: false
  def attempt
    submission.attempt || 0 # Nil in database, make it 0 here for easier api
  end

  field :comments_connection, Types::SubmissionCommentType.connection_type, null: true do
    argument :filter, Types::SubmissionCommentFilterInputType, required: false
  end
  def comments_connection(filter: nil)
    filter ||= {}
    load_association(:assignment).then do
      scope = submission.comments_for(current_user).published
      scope = scope.where(attempt: submission.attempt || 0) unless filter[:all_comments]
      scope
    end
  end

  field :score, Float, null: true
  def score
    protect_submission_grades(:score)
  end

  field :grade, String, null: true
  def grade
    protect_submission_grades(:grade)
  end

  field :entered_score, Float,
    'the submission score *before* late policy deductions were applied',
    null: true
  def entered_score
    protect_submission_grades(:entered_score)
  end

  field :entered_grade, String,
    'the submission grade *before* late policy deductions were applied',
    null: true
  def entered_grade
    protect_submission_grades(:entered_grade)
  end

  field :deducted_points, Float,
    'how many points are being deducted due to late policy',
    null: true
  def deducted_points
    protect_submission_grades(:points_deducted)
  end

  field :excused, Boolean,
    'excused assignments are ignored when calculating grades',
    method: :excused?, null: true

  field :submitted_at, Types::DateTimeType, null: true
  field :graded_at, Types::DateTimeType, null: true
  field :posted_at, Types::DateTimeType, null: true
  field :state, Types::SubmissionStateType, method: :workflow_state, null: false

  field :submission_status, String, null: true
  def submission_status
    if submission.submission_type == 'online_quiz'
      Loaders::AssociationLoader.for(Submission, :quiz_submission).
        load(submission).
        then { submission.submission_status }
    else
      submission.submission_status
    end
  end

  field :grading_status, String, null: true
  field :late_policy_status, LatePolicyStatusType, null: true
end
