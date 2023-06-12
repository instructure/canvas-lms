# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::CourseOutcomeAlignmentStatsType do
  before :once do
    account_admin_user
    outcome_alignment_stats_model
    @course.account.enable_feature!(:improved_outcomes_management)
  end

  let(:graphql_context) { { current_user: @admin } }
  let(:course_type) { GraphQLTypeTester.new(@course, graphql_context) }

  describe "returns correct values for alignment stats fields" do
    it "total_outcomes" do
      expect(
        course_type.resolve("outcomeAlignmentStats { totalOutcomes }")
      ).to eq 2
    end

    it "aligned_outcomes" do
      expect(
        course_type.resolve("outcomeAlignmentStats { alignedOutcomes }")
      ).to eq 1
    end

    it "total_alignments" do
      expect(
        course_type.resolve("outcomeAlignmentStats { totalAlignments }")
      ).to eq 3
    end

    it "total_artifacts" do
      expect(
        course_type.resolve("outcomeAlignmentStats { totalArtifacts }")
      ).to eq 4
    end

    it "aligned_artifacts" do
      expect(
        course_type.resolve("outcomeAlignmentStats { alignedArtifacts }")
      ).to eq 2
    end

    it "artifact_alignments" do
      expect(
        course_type.resolve("outcomeAlignmentStats { artifactAlignments }")
      ).to eq 2
    end
  end
end
