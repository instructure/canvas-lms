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

class UnreadCommentCountLoader < GraphQL::Batch::Loader
  def initialize(current_user)
    @current_user = current_user
  end

  def perform(submissions)
    unread_count_hash = Submission.
      where(id: submissions).
      joins(:submission_comments).
      where(
        'NOT EXISTS (?)',
        ViewedSubmissionComment.
          where('viewed_submission_comments.submission_comment_id=submission_comments.id').
          where(:user_id => @current_user)
      ).
      group(:submission_id).
      count

    submissions.each { |s| fulfill(s, unread_count_hash[s.id] || 0) }
  end
end

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

  field :unread_comment_count, Integer, null: false
  def unread_comment_count
    Promise.all([
      load_association(:content_participations),
      load_association(:assignment)
    ]).then do
      next 0 if object.read?(current_user)
      UnreadCommentCountLoader.for(current_user).load(object)
    end
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
    argument :filter, Types::SubmissionCommentFilterInputType, required: false, default_value: {}
  end
  def comments_connection(filter:)
    filter = filter.to_h
    all_comments, for_attempt = filter.values_at(:all_comments, :for_attempt)

    load_association(:assignment).then do
      scope = submission.comments_for(current_user).published
      unless all_comments
        target_attempt = for_attempt || submission.attempt || 0
        if target_attempt <= 1
          target_attempt = [nil, 0, 1] # Submission 0 and 1 share comments
        end
        scope = scope.where(attempt: target_attempt)
      end
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
  field :posted, Boolean, method: :posted?, null: false
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

  field :grading_status, Types::SubmissionGradingStatusType, null: true
  field :late_policy_status, LatePolicyStatusType, null: true
  field :late, Boolean, method: :late?, null: true
  field :missing, Boolean, method: :missing?, null: true
  field :grade_matches_current_submission, Boolean,
    'was the grade given on the current submission (resubmission)', null: true

  field :attachments, [Types::FileType], null: true
  def attachments
    Loaders::IDLoader.for(Attachment).load_many(object.attachment_ids_for_version)
  end

  field :submission_draft, Types::SubmissionDraftType, null: true
  def submission_draft
    load_association(:submission_drafts).then do |drafts|
      # Submission.attempt can be in either 0 or nil which mean the same thing
      target_attempt = (object.attempt || 0) + 1
      drafts.select { |draft| draft.submission_attempt == target_attempt }.first
    end
  end
end
