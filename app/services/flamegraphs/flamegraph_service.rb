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

class Flamegraphs::FlamegraphService < SiteAdminReportingService
  SAMPLING_INTERVAL_MICROSECONDS = 1_000

  private

  def create_report(file)
    report = Tempfile.create do |temp|
      StackProf.run(
        mode: :wall,
        raw: true,
        ignore_gc: true,
        out: temp,
        interval: SAMPLING_INTERVAL_MICROSECONDS,
        &@block
      )
      StackProf::Report.from_file(temp)
    end
    report.print_d3_flamegraph(file)
    file.rewind
    file
  end

  def report_type
    "flamegraph"
  end

  def content_type
    "text/html"
  end

  def attachment_folder
    user.flamegraphs_folder
  end
end
