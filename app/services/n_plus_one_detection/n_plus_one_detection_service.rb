# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class NPlusOneDetection::NPlusOneDetectionService < SiteAdminReportingService
  HEADER_MESSAGE = "N+1 Detection Report\nIf this file is empty, no N+1 queries were detected.\n\n"
  class NoBlockError < StandardError; end
  class NonSiteAdminUser < StandardError; end

  private

  def create_report(file)
    file.write(HEADER_MESSAGE)
    # If we've gotten this far, we know we're in production, as this service is only
    # used in production mode. Avoid cluttering the logs.
    Prosopite.rails_logger = false
    Prosopite.prosopite_logger = false
    Prosopite.custom_logger = Logger.new(file)

    Prosopite.scan
    block.call
  ensure
    Prosopite.finish
  end

  def content_type
    "text/plain"
  end

  def report_type
    "n_plus_one_detection"
  end

  def attachment_folder
    user.n_plus_one_detection_folder
  end
end
