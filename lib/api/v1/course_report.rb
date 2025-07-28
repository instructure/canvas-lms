# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Api::V1::CourseReport
  include Api::V1::Json
  include Api::V1::Attachment

  def course_reports_json(reports, user)
    reports.map do |f|
      course_report_json(f, user)
    end
  end

  def course_report_json(report, user)
    json = api_json(report, user, nil, only: %w[id parameters])
    json[:status] = report.workflow_state
    json[:report_type] = report.report_type
    json[:course_id] = report.course_id
    json[:created_at] = report.created_at&.iso8601
    json[:started_at] = report.start_at&.iso8601
    json[:ended_at] = report.end_at&.iso8601
    json[:file_url] = (report.attachment.nil? ? nil : verified_file_download_url(report.attachment, report.course))
    if report.attachment
      json[:attachment] = attachment_json(report.attachment, user)
    end
    json[:progress] = if report.progress
                        report.progress.completion.to_i
                      elsif report.complete?
                        100
                      else
                        0
                      end
    json
  end
end
