# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe ModeratedGrading::NullProvisionalGrade do
  describe "grade_attributes" do
    it "returns the proper format" do
      expect(ModeratedGrading::NullProvisionalGrade.new(nil, 1, false).grade_attributes).to eq({
                                                                                                 "provisional_grade_id" => nil,
                                                                                                 "grade" => nil,
                                                                                                 "score" => nil,
                                                                                                 "graded_at" => nil,
                                                                                                 "scorer_id" => 1,
                                                                                                 "graded_anonymously" => nil,
                                                                                                 "final" => false,
                                                                                                 "grade_matches_current_submission" => true
                                                                                               })

      expect(ModeratedGrading::NullProvisionalGrade.new(nil, 2, true).grade_attributes).to eq({
                                                                                                "provisional_grade_id" => nil,
                                                                                                "grade" => nil,
                                                                                                "score" => nil,
                                                                                                "graded_at" => nil,
                                                                                                "scorer_id" => 2,
                                                                                                "graded_anonymously" => nil,
                                                                                                "final" => true,
                                                                                                "grade_matches_current_submission" => true
                                                                                              })
    end
  end

  it "returns the original submission's submission comments" do
    sub = double
    comments = double
    expect(sub).to receive(:submission_comments).and_return(comments)
    expect(ModeratedGrading::NullProvisionalGrade.new(sub, 1, false).submission_comments).to eq(comments)
  end

  describe "scorer" do
    it "returns the associated scorer if scorer_id is present" do
      scorer = user_factory(active_user: true)
      scored_grade = ModeratedGrading::NullProvisionalGrade.new(nil, scorer.id, true)
      expect(scored_grade.scorer).to eq scorer
    end

    it "returns nil if scorer_id is nil" do
      scored_grade = ModeratedGrading::NullProvisionalGrade.new(nil, nil, true)
      expect(scored_grade.scorer).to be_nil
    end
  end
end
