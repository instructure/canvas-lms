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
# @model QuizReport
#     {
#       "id": "QuizReport",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the quiz report",
#           "example": 5,
#           "type": "integer"
#         },
#         "quiz_id": {
#           "description": "the ID of the quiz",
#           "example": 4,
#           "type": "integer"
#         },
#         "report_type": {
#           "description": "which type of report this is possible values: 'student_analysis', 'item_analysis'",
#           "example": "student_analysis",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "student_analysis",
#               "item_analysis"
#             ]
#           }
#         },
#         "readable_type": {
#           "description": "a human-readable (and localized) version of the report_type",
#           "example": "Student Analysis",
#           "type": "string"
#         },
#         "includes_all_versions": {
#           "description": "boolean indicating whether the report represents all submissions or only the most recent ones for each student",
#           "example": true,
#           "type": "boolean"
#         },
#         "anonymous": {
#           "description": "boolean indicating whether the report is for an anonymous survey. if true, no student names will be included in the csv",
#           "example": false,
#           "type": "boolean"
#         },
#         "generatable": {
#           "description": "boolean indicating whether the report can be generated, which is true unless the quiz is a survey one",
#           "example": true,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "when the report was created",
#           "example": "2013-05-01T12:34:56-07:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "when the report was last updated",
#           "example": "2013-05-01T12:34:56-07:00",
#           "type": "datetime"
#         },
#         "url": {
#           "description": "the API endpoint for this report",
#           "example": "http://canvas.example.com/api/v1/courses/1/quizzes/1/reports/1",
#           "type": "string"
#         },
#         "file": {
#           "description": "if the report has finished generating, a File object that represents it. refer to the Files API for more information about the format",
#           "$ref": "File"
#         },
#         "progress_url": {
#           "description": "if the report has not yet finished generating, a URL where information about its progress can be retrieved. refer to the Progress API for more information (Note: not available in JSON-API format)",
#           "type": "string"
#         },
#         "progress": {
#           "description": "if the report is being generated, a Progress object that represents the operation. Refer to the Progress API for more information about the format. (Note: available only in JSON-API format)",
#           "$ref": "Progress"
#         }
#       }
#     }
#
class Quizzes::QuizReportsController < ApplicationController
  include Filters::Quizzes

  before_filter :require_context, :require_quiz

  # @API Retrieve all quiz reports
  #
  # Returns a list of all available reports.
  #
  # @argument includes_all_versions [Boolean]
  #   Whether to retrieve reports that consider all the submissions or only
  #   the most recent. Defaults to false, ignored for item_analysis reports.
  #
  # @returns [ QuizReport ]
  def index
    if authorized_action(@quiz, @current_user, :read_statistics)
      all_versions = value_to_boolean(params[:includes_all_versions])

      stats = Quizzes::QuizStatistics::REPORTS.map do |report_type|
        @quiz.current_statistics_for(report_type, {
          includes_all_versions: all_versions
        })
      end

      expose stats, %w[ file progress ]
    end
  end

  # @API Create a quiz report
  #
  # Create and return a new report for this quiz. If a previously
  # generated report matches the arguments and is still current (i.e.
  # there have been no new submissions), it will be returned.
  #
  # @argument quiz_report[report_type] [Required, String, "student_analysis"|"item_analysis"]
  #   The type of report to be generated.
  #
  # @argument quiz_report[includes_all_versions] [Boolean]
  #   Whether the report should consider all submissions or only the most
  #   recent. Defaults to false, ignored for item_analysis.
  #
  # @argument include [String[], "file"|"progress"]
  #   Whether the output should include documents for the file and/or progress
  #   objects associated with this report. (Note: JSON-API only)
  #
  # @returns QuizReport
  def create
    authorized_action(@quiz, @current_user, :read_statistics)

    p = if accepts_jsonapi?
      (params[:quiz_reports] || [])[0] || {}
    else
      params[:quiz_report] || {}
    end

    unless Quizzes::QuizStatistics::REPORTS.include?(p[:report_type])
      return render({
        json: { errors: { report_type: "invalid" } },
        status: :bad_request
      })
    end

    stats = @quiz.statistics_csv(p[:report_type], {
      async: true,
      includes_all_versions: value_to_boolean(p[:includes_all_versions])
    })

    expose stats, backward_compatible_includes
  end

  # @API Get a quiz report
  #
  # Returns the data for a single quiz report.
  #
  # @argument include [String[], "file"|"progress"]
  #   Whether the output should include documents for the file and/or progress
  #   objects associated with this report. (Note: JSON-API only)
  #
  # @returns QuizReport
  def show
    if authorized_action(@quiz, @current_user, :read_statistics)
      expose @quiz.quiz_statistics.find(params[:id]), backward_compatible_includes
    end
  end

  private

  def expose(stats, includes=[])
    stats = [ stats ] unless stats.is_a?(Array)

    json = if accepts_jsonapi?
      serialize_jsonapi(stats, includes)
    else
      serialize_json(stats, includes)
    end

    render json: json
  end

  def serialize_json(stats, includes=[])
    serialized_set = stats.map do |report_stats|
      Quizzes::QuizReportSerializer.new(report_stats, {
        controller: self,
        root: false,
        include_root: false,
        scope: @current_user,
        includes: includes
      }).as_json
    end

    serialized_set.length == 1 ? serialized_set[0] : serialized_set
  end

  def serialize_jsonapi(stats, includes)
    serialized_set = Canvas::APIArraySerializer.new(stats, {
      each_serializer: Quizzes::QuizReportSerializer,
      controller: self,
      scope: @current_user,
      root: false,
      include_root: false,
      includes: includes,
      meta: {
        primaryCollection: 'quiz_reports'
      }
    }).as_json

    { quiz_reports: serialized_set }
  end

  # The non-JSONAPI endpoint used to return only the progress_url, but the new
  # one can embed it.
  def backward_compatible_includes
    if accepts_jsonapi?
      Array(params[:include]).map(&:to_s) & %w[ file progress ]
    else
      %w[ file ]
    end
  end
end
