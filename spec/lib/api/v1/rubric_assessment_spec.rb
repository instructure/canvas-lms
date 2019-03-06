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

require_relative '../../../spec_helper'

describe "Api::V1::RubricAssessment" do
  include Api::V1::RubricAssessment

  describe "#rubric_assessment_json" do
    before :once do
      assignment_model
      @teacher = user_factory(active_all: true)
      @course.enroll_teacher(@teacher).accept
      @student = user_factory(active_all: true)
      @course.enroll_student(@student).accept
      def criteria(id)
        {
          :description => "Some criterion",
          :points => 10,
          :id => id,
          :ratings => [
            {:description => "Good", :points => 10, :id => 'rat1', :criterion_id => id},
            {:description => "Medium", :points => 5, :id => 'rat2', :criterion_id => id},
            {:description => "Bad", :points => 0, :id => 'rat3', :criterion_id => id}
          ]
        }
      end
      rubric_model(data: %w[crit1 crit2 crit3 crit4].map { |n| criteria(n) })
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    end

    it 'rounds the final score to avoid floating-point arithmetic issues' do
      # in an ideal world these would be stored using the DECIMAL type, but we
      # don't live in that world
      assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 1.2,
            :rating_id => 'rat2'
          },
          :criterion_crit2 => {
            :points => 1.2,
            :rating_id => 'rat2'
          },
          :criterion_crit3 => {
            :points => 1.2,
            :rating_id => 'rat2'
          },
          :criterion_crit4 => {
            :points => 0.4,
            :rating_id => 'rat2'
          }
        }
      })

      expect(rubric_assessment_json(assessment, @teacher, nil)[:score]).to eq(4.0)
    end
  end
end
