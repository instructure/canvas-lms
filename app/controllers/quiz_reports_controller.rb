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

# @API Quiz Reports
# API for accessing and generating statistical reports for a quiz
#
# @object QuizReport
#     {
#       // the ID of the quiz report
#       "id": 5,
#
#       // the ID of the quiz
#       "quiz_id": 4,
#
#       // which type of report this is
#       // possible values: "student_analysis", "item_analysis"
#       "report_type": "student_analysis",
#
#       // boolean indicating whether the report represents all submissions or only the most recent ones for each student
#       "includes_all_versions": true,
#
#       // boolean indicating whether the report is for an anonymous
#       // survey. if true, no student names will be included in the csv
#       "anonymous": false,
#
#       // when the report was created
#       "created_at": "2013-05-01T12:34:56-07:00",
#
#       // when the report was last updated
#       "updated_at": "2013-05-01T12:34:56-07:00",
#
#       // if the report has finished generating, a File object that
#       // represents it. refer to the Files API for more information
#       // about the format
#       "file": {
#         "content-type": "text/csv",
#         "url": "http://www.example.com/files/123/download..."
#         // ...
#       },
#
#       // if the report has not yet finished generating, a URL
#       // where information about its progress can be retrieved.
#       // refer to the Progress API for more information
#       "progress_url": null
#     }
#
class QuizReportsController < ApplicationController
  before_filter :require_quiz

  include Api::V1::QuizStatistics

  # @API Create a quiz report
  #
  # Create and return a new report for this quiz. If a previously
  # generated report matches the arguments and is still current (i.e.
  # there have been no new submissions), it will be returned.
  #
  # @argument quiz_report[report_type] [String, "student_analysis"|"item_analysis"]
  #   The type of report to be generated.
  #
  # @argument quiz_report[includes_all_versions] [Optional, Boolean]
  #   Whether the report should consider all submissions or only the most
  #   recent. Defaults to false, ignored for item_analysis.
  #
  # @returns QuizReport

  def create
    if authorized_action(@quiz, @current_user, :read_statistics)
      if params[:quiz_report] && QuizStatistics::REPORTS.include?(params[:quiz_report][:report_type])
        stats = @quiz.statistics_csv(params[:quiz_report][:report_type], :async => true, :includes_all_versions => value_to_boolean(params[:quiz_report][:includes_all_versions]))
        render :json => quiz_statistics_json(stats, @current_user, session, :include => ['file', 'progress_url'])
      else
        render :json => {:errors => {:report_type => "invalid"}}, :status => :bad_request
      end
    end
  end

  # @API Get a quiz report
  #
  # Returns the data for a single quiz report.
  #
  # @returns QuizReport
  def show
    if authorized_action(@quiz, @current_user, :read_statistics)
      @stats = @quiz.quiz_statistics.find(params[:id])
      render :json => quiz_statistics_json(@stats, @current_user, session, :include => ['file', 'progress_url'])
    end
  end

  protected

  def require_quiz
    require_context
    @quiz = @context.quizzes.find(params[:quiz_id])
  end
end
