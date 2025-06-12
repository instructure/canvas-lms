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

require_relative "../../spec_helper"

describe Outcomes::StudentOutcomeRollupCalculationService do
  let(:course) { course_model }
  let(:student) { user_model }

  describe ".call" do
    it "executes without raising an error" do
      # At this skeleton stage, we're just verifying the service can be called without errors
      expect do
        Outcomes::StudentOutcomeRollupCalculationService.call(course:, student:)
      end.not_to raise_error
    end
  end
end
