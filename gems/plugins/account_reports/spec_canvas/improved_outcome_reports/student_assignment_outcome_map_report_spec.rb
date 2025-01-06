# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../report_spec_helper"
require_relative "shared/shared_examples"
require_relative "shared/improved_outcome_reports_spec_helpers"
require_relative "shared/setup"

describe "StudentAssignmentOutcomeMapReport" do
  include ReportSpecHelper

  describe "Student Competency report" do
    include ImprovedOutcomeReportsSpecHelpers

    include_context "setup"

    let(:report_type) { "student_assignment_outcome_map_csv" }
    let(:expected_headers) { AccountReports::ImprovedOutcomeReports::StudentAssignmentOutcomeMapReport::HEADERS }
    let(:all_values) { [user2_values, user1_values] }
    let(:order) { [0, 2, 3, 15] }

    before do
      Account.site_admin.enable_feature!(:improved_outcome_report_generation)
    end

    include_examples "common outcomes report behavior"
  end
end
