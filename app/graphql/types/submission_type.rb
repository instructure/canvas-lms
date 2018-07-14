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
#

module Types
  class SubmissionType < ApplicationObjectType
    graphql_name "Submission"

    implements GraphQL::Relay::Node.interface
    implements Interfaces::TimestampInterface

    alias :submission :object

    # not doing a legacy canvas id since they aren't used in the rest api
    global_id_field :id

    field :assignment, AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :user, UserType, null: true
    def user
      load_association(:user)
    end

    def protect_submission_grades(attr)
      submission.user_can_read_grade?(current_user, session) ?
        submission.send(attr) :
        nil
    end
    private :protect_submission_grades

    field :score, Float, null: true
    def score
      protect_submission_grades(:score)
    end

    field :grade, String, null: true
    def grade
      protect_submission_grades(:grade)
    end

    field :entered_score, Float,
      "the submission score *before* late policy deductions were applied",
      null: true
    def entered_score
      protect_submission_grades(:entered_score)
    end

    field :entered_grade, String,
      "the submission grade *before* late policy deductions were applied",
      null: true
    def entered_grade
      protect_submission_grades(:entered_grade)
    end

    field :deducted_points, Float,
      "how many points are being deducted due to late policy",
      null: true
    def deducted_points
      protect_submission_grades(:points_deducted)
    end

    field :excused, Boolean,
      "excused assignments are ignored when calculating grades",
      method: :excused?, null: true

    field :submitted_at, DateTimeType, null: true
    field :graded_at, DateTimeType, null: true

    field :state, SubmissionStateType, method: :workflow_state, null: false

    field :submission_status, String, null: true
    def submission_status
      if submission.submission_type == "online_quiz"
        Loaders::AssociationLoader.for(Submission, :quiz_submission).
          load(submission).
          then { submission.submission_status }
      else
        submission.submission_status
      end
    end

    field :grading_status, String, null: true
  end
end
