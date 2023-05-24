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
#

describe AssessmentRequestHelper do
  include AssessmentRequestHelper
  include ApplicationHelper

  describe "submission_author_name_for" do
    def rubric_association_params_for_assignment(assign)
      ActiveSupport::HashWithIndifferentAccess.new({
                                                     hide_score_total: "0",
                                                     purpose: "grading",
                                                     skip_updating_points_possible: false,
                                                     update_if_existing: true,
                                                     use_for_grading: "1",
                                                     association_object: assign
                                                   })
    end

    before(:once) do
      course_with_teacher(active_all: true)
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      assignment_model(course: @course)
      @submission = @assignment.find_or_create_submission(@student)
      submission2 = @assignment.find_or_create_submission(@student2)
      @rubric = @course.rubrics.create! { |r| r.user = @teacher }
      ra_params = rubric_association_params_for_assignment(@assignment)
      @rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
      @rubric_assessment = RubricAssessment.create!({
                                                      artifact: @submission,
                                                      assessment_type: "peer_review",
                                                      assessor: @student2,
                                                      rubric: @rubric,
                                                      user: @student1,
                                                      rubric_association: @rubric_assoc
                                                    })
      @assessment_request = AssessmentRequest.create!(rubric_assessment: @rubric_assessment,
                                                      user: @student1,
                                                      asset: @submission,
                                                      assessor_asset: submission2,
                                                      assessor: @student2)
    end

    it "returns assessment user name" do
      @current_user = @student1
      expect(submission_author_name_for(@assessment_request)).to eq(@student1.short_name)
    end

    it "returns assessment user name for assessor when anonymous reviews are disabled" do
      @current_user = @student2
      expect(submission_author_name_for(@assessment_request)).to eq(@student1.short_name)
    end

    it "returns assessment user name when anonymous reviews are enabled and user has permission" do
      @assignment.update_attribute(:anonymous_peer_reviews, true)
      @assessment_request.reload
      @current_user = @student1
      expect(submission_author_name_for(@assessment_request)).to eq(@student1.short_name)
    end

    it "returns anonymous user when anonymous peer reviews are enabled" do
      @assignment.update_attribute(:anonymous_peer_reviews, true)
      @assessment_request.reload
      @current_user = @student2
      expect(submission_author_name_for(@assessment_request)).to eq(I18n.t(:anonymous_user, "Anonymous User"))
    end
  end
end
