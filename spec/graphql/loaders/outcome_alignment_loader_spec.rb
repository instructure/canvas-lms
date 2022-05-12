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

describe Loaders::OutcomeAlignmentLoader do
  before do
    course_model
    @assignment1 = assignment_model({
                                      course: @course,
                                      name: "Assignment 1",
                                      due_at: nil,
                                      points_possible: 10,
                                      submission_types: "online_text_entry,online_upload",
                                    })
    @assignment2 = assignment_model({
                                      course: @course,
                                      name: "Assignment 2",
                                      due_at: nil,
                                      points_possible: 20,
                                      submission_types: "online_text_entry",
                                    })
    @outcome = outcome_model(context: @course, title: "outcome")
    @alignment1 = @outcome.align(@assignment1, @course)
    @alignment2 = @outcome.align(@assignment2, @course)
    @course.account.enable_feature!(:outcome_alignment_summary)
  end

  it "resolves to nil if context id is invalid" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        "999999", "Course"
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to nil if context type is invalid" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "InvalidContextType"
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to nil if outcome alignment summary FF is disabled" do
    @course.account.disable_feature!(:outcome_alignment_summary)

    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "Course"
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves alignments properly" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "Course"
      ).load(@outcome).then do |alignment|
        expect(alignment.is_a?(Array)).to be_truthy
        expect(alignment.length).to eq 2

        expect(alignment[0].id).to eq @alignment1.id
        expect(alignment[0].content_type).to eq "Assignment"
        expect(alignment[0].content_id).to eq @assignment1.id
        expect(alignment[0].context_type).to eq "Course"
        expect(alignment[0].context_id).to eq @course.id
        expect(alignment[0].learning_outcome_id).to eq @outcome.id
        expect(alignment[0].title).to eq @assignment1.title
        expect(alignment[0].url).to eq "/courses/#{@course.id}/outcomes/#{@outcome.id}/alignments/#{@alignment1.id}"

        expect(alignment[1].id).to eq @alignment2.id
        expect(alignment[1].content_type).to eq "Assignment"
        expect(alignment[1].content_id).to eq @assignment2.id
        expect(alignment[1].context_type).to eq "Course"
        expect(alignment[1].context_id).to eq @course.id
        expect(alignment[1].learning_outcome_id).to eq @outcome.id
        expect(alignment[1].title).to eq @assignment2.title
        expect(alignment[1].url).to eq "/courses/#{@course.id}/outcomes/#{@outcome.id}/alignments/#{@alignment2.id}"
      end
    end
  end
end
