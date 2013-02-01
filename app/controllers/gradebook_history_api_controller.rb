#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Gradebook History
# @beta
#
# API for accessing the versioned history of student submissions along with their
# grade changes, organized by the date of the submission.
#
#
# @object Grader
#     {
#       // the user_id of the user who graded the contained submissions
#       id: 27
#
#       // the name of the user who graded the contained submissions
#       name: 'Some User'
#
#       // the assignment groups for all submissions in this response that were
#       // graded by this user.  The details are not nested inside here, but the
#       // fact that an assignment is present here means that the grader did grade
#       // submissions for this assignment on the contextual date. You can
#       // use the id of a grader and of an assignment to make another API
#       // call to find all submissions for a grader/assignment combination on 
#       // a given date.
#       assignments: [Assignment]
#     }
#
#
# @object Day
#     {
#       // the date represented by this entry
#       date: '8/9/1986'
#
#       // an array of the graders who were responsible for the submissions in this response.
#       // the submissions are grouped according to the person who graded them and the
#       // assignment they were submitted for.
#       graders: [Grader]
#     }
#
#
# @object SubmissionVersion
#     {
#       // the id of the assignment this submissions is for
#       assignment_id: 22604
#
#       // the name of the assignment this submission is for
#       assignment_name: "some assignment"
#
#       // the id of the primary attachment
#       attachment_id: null
#
#       // other attachment ids
#       attachment_ids: null
#
#       // the body text of the submission
#       body: "text from the submission"
#
#       // the id of the course to which this submission belongs
#       course_id: 27955
#
#       // timestamp for the creation of this submission version
#       created_at: "2013-01-31T18:16:31Z"
#
#       // the most up to date grade for the current version of this submission
#       current_grade: "100"
#
#       // the latest time stamp for the grading of this submission
#       current_graded_at: "2013-01-31T18:16:31Z"
#
#       // the name of the most recent grader for this submission
#       current_grader: "Grader Name"
#
#       // boolean indicating whether the grade is equal to the current submission grade
#       grade_matches_current_submission: true
#
#       // time stamp for the grading of this version of the submission
#       graded_at: "2013-01-31T18:16:31Z"
#
#       // date on which this version of the submission was graded
#       graded_on: "2013-01-31"
#
#       // the name of the user who graded this version of the submission
#       grader: "Grader Name"
#
#       // the user id of the user who graded this version of the submission
#       grader_id: 67379
#
#       // the id of the group to which this submission belongs
#       group_id: null
#
#       // alias for submission_id, the id of the submission of which this is a version
#       id: 11607
#
#       // the updated grade provided in this version of the submission
#       new_grade: "100"
#
#       // the timestamp for the grading of this version of the submission (alias for graded_at)
#       new_graded_at: "2013-01-31T18:16:31Z"
#
#       // alias for 'grader'
#       new_grader: "Grader Name"
#
#       // the grade for the submission version immediately preceding this one
#       previous_grade: "90"
#
#       // the timestamp for the grading of the submission version immediately preceding this one
#       previous_graded_at: "2013-01-29T12:12:12Z"
#
#       // the name of the grader who graded the version of this submission immediately preceding this one
#       previous_grader: "Graded on submission"
#
#       // the number of attempts at processing this submission
#       process_attempts: 1
#
#       // whether the submission was processed or not (boolean)
#       processed: false
#
#       // the final grade retained for publishing in the gradebook
#       published_grade: "100"
#
#       // the final score retained for publishing in the gradebook
#       published_score: 100
#
#       // the grader id (which will be 0 if there isn't one available)
#       safe_grader_id:=>67379
#
#       // the score for this version of the submission
#       score: 100
#
#       // the score entered by the student
#       student_entered_score: null
#
#       // the user ID of the student who created this submission
#       student_user_id: 67376
#
#       // the ID of the submission of which this is a version
#       submission_id: 11607
#
#       // the name of the student who created this submission
#       student_name: "student@example.com"
#
#       // the type of submission
#       submission_type: 'online'
#
#       // the time stamp of the most recent update to this record
#       updated_at: "2013-01-31T18:16:31Z"
#
#       // the url of the submission, if there is one
#       url: null
#
#       // alias for 'student_user_id'
#       user_id: 67376
#
#       // the state of the submission at this version
#       workflow_state: "unsubmitted"
#     }
#
#
# @object SubmissionHistory
#     {
#       // the id of the submission
#       submission_id: 4
#
#       // an array of all the versions of this submission
#       versions: [SubmissionVersion]
#     }
#
#
#

class GradebookHistoryApiController < ApplicationController
  before_filter :require_context

  include Api::V1::GradebookHistory

  # @API Days in gradebook history for this course
  # Returns a map of dates to grader/assignment groups
  #
  # @argument course_id [Integer]
  #   The id of the contextual course for this API call
  #
  # @returns [Day]
  def days
    if authorized_action(@context, @current_user, :manage_grades)
      days_hash = days_json(@context, api_context(api_v1_gradebook_history_url(@context)))
      render :json => days_hash.to_json
    end
  end

  # @API Details for a given date in gradebook history for this course
  # Returns the graders who worked on this day, along with the assignments they worked on.
  # More details can be obtained by selecting a grader and assignment and calling the
  # 'submissions' api endpoint for a given date.
  #
  # @argument course_id [Integer]
  #   The id of the contextual course for this API call
  #
  # @argument date [String]
  #   The date for which you would like to see detailed information
  #
  # @returns [Grader]
  def day_details
    if authorized_action(@context, @current_user, :manage_grades)
      date = Date.strptime(params[:date], '%Y-%m-%d').in_time_zone
      path = api_v1_gradebook_history_for_day_url(@context, params[:date])
      day_hash = json_for_date(date, @context, api_context(path))
      render :json => day_hash.to_json
    end
  end

  # @API Lists submissions
  # Gives a nested list of submission versions
  #
  # @argument course_id [Integer]
  #   The id of the contextual course for this API call
  #
  # @argument date [String]
  #   The date for which you would like to see submissions
  #
  # @argument grader_id [Integer]
  #   The ID of the grader for which you want to see submissions
  #
  # @argument assignment_id [Integer]
  #   The ID of the assignment for which you want to see submissions
  #
  # @returns [SubmissionHistory]
  def submissions
    if authorized_action(@context, @current_user, :manage_grades)
      date = Date.strptime(params[:date], '%Y-%m-%d').in_time_zone
      path = api_v1_gradebook_history_submissions_url(@context, params[:date], params[:grader_id], params[:assignment_id])
      submissions_hash = submissions_for(@context, api_context(path), date, params[:grader_id], params[:assignment_id])
      render :json => submissions_hash.to_json
    end
  end

  private
  def api_context(path)
    Api::V1::ApiContext.new(self, path, @current_user, session, params.slice(:page))
  end
end
