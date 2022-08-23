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

describe Loaders::CourseOutcomeAlignmentStatsLoader do
  before :once do
    outcome_alignment_stats_model
    @course.account.enable_feature!(:outcome_alignment_summary)
  end

  it "returns nil if course is invalid" do
    GraphQL::Batch.batch do
      Loaders::CourseOutcomeAlignmentStatsLoader.load(nil).then do |alignment_stats|
        expect(alignment_stats).to be_nil
      end
    end
  end

  it "returns nil if outcome alignment summary FF is disabled" do
    @course.account.disable_feature!(:outcome_alignment_summary)

    GraphQL::Batch.batch do
      Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |alignment_stats|
        expect(alignment_stats).to be_nil
      end
    end
  end

  it "returns outcome alignment stats" do
    GraphQL::Batch.batch do
      Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
        expect(stats).not_to be_nil
        expect(stats[:total_outcomes]).to eq 2
        expect(stats[:aligned_outcomes]).to eq 1
        expect(stats[:total_alignments]).to eq 3
        expect(stats[:total_artifacts]).to eq 4
        expect(stats[:aligned_artifacts]).to eq 2
        expect(stats[:artifact_alignments]).to eq 2
      end
    end
  end

  context "when an outcome is aligned to a question bank" do
    before do
      assessment_question_bank_with_questions
      @outcome3 = outcome_model(context: @course, title: "outcome 3 - aligned to question bank")
      @outcome3.align(@bank, @bank.context)
    end

    it "returns correct outcome alignment stats" do
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 3
          expect(stats[:aligned_outcomes]).to eq 2
          expect(stats[:total_alignments]).to eq 4
          expect(stats[:total_artifacts]).to eq 4
          expect(stats[:aligned_artifacts]).to eq 2
          expect(stats[:artifact_alignments]).to eq 2
        end
      end
    end
  end
end
