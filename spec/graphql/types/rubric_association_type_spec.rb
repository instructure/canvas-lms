#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require_relative "../graphql_spec_helper"

describe Types::RubricAssociationType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(active_all: true, course: course).user }
  let_once(:student) { student_in_course(course: course, active_all: true).user }
  let_once(:assignment) { assignment_model(course: course) }
  let_once(:rubric) { rubric_for_course }
  let_once(:rubric_association) {
    rubric_association_model(
      context: course,
      rubric: rubric,
      association_object: assignment,
      purpose: 'grading'
    )
  }
  let_once(:rubric_assessment) {
    rubric_assessment_model(
      user: student,
      assessor: teacher,
      rubric_association: rubric_association,
      assessment_type: 'grading'
    )
  }
  let(:submission) { assignment.submissions.where(user: student).first }
  let(:submission_type) { GraphQLTypeTester.new(submission, current_user: teacher) }

  it 'works' do
    expect(
      submission_type.resolve('rubricAssessmentsConnection { nodes { rubricAssociation { _id } } }')
    ).to eq [rubric_association.id.to_s]
  end

  describe 'works for the field' do
    it 'hide_points' do
      expect(
        submission_type.resolve('rubricAssessmentsConnection { nodes { rubricAssociation { hidePoints } } }')
      ).to eq [rubric_association.hide_points]
    end

    it 'hide_score_total' do
      expect(
        submission_type.resolve('rubricAssessmentsConnection { nodes { rubricAssociation { hideScoreTotal } } }')
      ).to eq [false]
    end

    it 'use_for_grading' do
      expect(
        submission_type.resolve('rubricAssessmentsConnection { nodes { rubricAssociation { useForGrading } } }')
      ).to eq [false]
    end
  end
end
