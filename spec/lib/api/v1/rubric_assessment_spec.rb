# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

describe "Api::V1::RubricAssessment" do
  include Api::V1::RubricAssessment

  describe "#indexed_rubric_assessment_json" do
    before :once do
      assignment_model
      @teacher = user_factory(active_all: true)
      @course.enroll_teacher(@teacher).accept
      @student = user_factory(active_all: true)
      @course.enroll_student(@student).accept
      def criteria(id)
        {
          description: "Some criterion",
          points: 10,
          id:,
          ratings: [
            { description: "Good", points: 10, id: "rat1", criterion_id: id },
            { description: "Medium", points: 5, id: "rat2", criterion_id: id },
            { description: "Bad", points: 0, id: "rat3", criterion_id: id }
          ]
        }
      end
      rubric_model(data: %w[crit1 crit2 crit3 crit4].map { |n| criteria(n) })
      @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
    end

    it "includes rating ids for each criterion" do
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: 8,
                                             rating_id: "rat1"
                                           },
                                           criterion_crit2: {
                                             points: 8,
                                             rating_id: "rat1"
                                           },
                                           criterion_crit3: {
                                             points: 4,
                                             rating_id: "rat2"
                                           },
                                           criterion_crit4: {
                                             points: 0,
                                             rating_id: "rat3"
                                           }
                                         }
                                       })

      expect(indexed_rubric_assessment_json(assessment)).to eq({
                                                                 "crit1" => { points: 8, rating_id: "rat1", comments: nil },
                                                                 "crit2" => { points: 8, rating_id: "rat1", comments: nil },
                                                                 "crit3" => { points: 4, rating_id: "rat2", comments: nil },
                                                                 "crit4" => { points: 0, rating_id: "rat3", comments: nil }
                                                               })
    end
  end
end
