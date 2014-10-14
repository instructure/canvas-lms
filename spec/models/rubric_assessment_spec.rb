#
# Copyright (C) 2011 Instructure, Inc.
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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe RubricAssessment do
  before :once do
    assignment_model
    @teacher = user(:active_all => true)
    @course.enroll_teacher(@teacher).accept
    @student = user(:active_all => true)
    @course.enroll_student(@student).accept
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
  end

  it "should htmlify the rating comments" do
    comment = "Hi, please see www.example.com.\n\nThanks."
    @assessment = @association.assess({
      :user => @student,
      :assessor => @teacher,
      :artifact => @assignment.find_or_create_submission(@student),
      :assessment => {
        :assessment_type => 'grading',
        :criterion_crit1 => {
          :points => 5,
          :comments => comment,
        }
      }
    })
    expect(@assessment.data.first[:comments]).to eq comment
    t = Class.new
    t.extend HtmlTextHelper
    # data has been round-tripped through YAML, and syck doesn't preserve carriage returns
    expect(@assessment.data.first[:comments_html]).to eq t.format_message(comment).first.gsub("\r", '')
  end

  context "grading" do
    it "should update scores if used for grading" do
      @assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })
      expect(@assessment).not_to be_nil
      expect(@assessment.user).to eql(@student)
      expect(@assessment.assessor).to eql(@teacher)
      expect(@assessment.artifact).not_to be_nil
      expect(@assessment.artifact).to be_is_a(Submission)
      expect(@assessment.artifact.user).to eql(@student)
      expect(@assessment.artifact.grader).to eql(@teacher)
      expect(@assessment.artifact.score).to eql(5.0)
      expect(@assessment.data.first[:comments_html]).to be_nil
    end
    
    it "should not update scores if not used for grading" do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => false)
      @assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })
      expect(@assessment).not_to be_nil
      expect(@assessment.user).to eql(@student)
      expect(@assessment.assessor).to eql(@teacher)
      expect(@assessment.artifact).not_to be_nil
      expect(@assessment.artifact).to be_is_a(Submission)
      expect(@assessment.artifact.user).to eql(@student)
      expect(@assessment.artifact.grader).to eql(nil)
      expect(@assessment.artifact.score).to eql(nil)
    end
    
    it "should not update scores if not a valid grader" do
      @student2 = user(:active_all => true)
      @course.enroll_student(@student2).accept
      @assessment = @association.assess({
        :user => @student,
        :assessor => @student2,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })
      expect(@assessment).not_to be_nil
      expect(@assessment.user).to eql(@student)
      expect(@assessment.assessor).to eql(@student2)
      expect(@assessment.artifact).not_to be_nil
      expect(@assessment.artifact).to be_is_a(Submission)
      expect(@assessment.artifact.user).to eql(@student)
      expect(@assessment.artifact.grader).to eql(nil)
      expect(@assessment.artifact.score).to eql(nil)
    end
  end
end
