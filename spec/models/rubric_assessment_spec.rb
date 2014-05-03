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
  it "should htmlify the rating comments" do
    assignment_model
    rubric_model
    @student = user(:active_all => true)
    @course.enroll_student(@student).accept
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
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
    @assessment.data.first[:comments].should == comment
    t = Class.new
    t.extend HtmlTextHelper
    @assessment.data.first[:comments_html].should == t.format_message(comment).first
  end

  context "grading" do
    it "should update scores if used for grading" do
      assignment_model
      @teacher = user(:active_all => true)
      @course.enroll_teacher(@teacher).accept
      @student = user(:active_all => true)
      @course.enroll_student(@student).accept
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
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
      @assessment.should_not be_nil
      @assessment.user.should eql(@student)
      @assessment.assessor.should eql(@teacher)
      @assessment.artifact.should_not be_nil
      @assessment.artifact.should be_is_a(Submission)
      @assessment.artifact.user.should eql(@student)
      @assessment.artifact.grader.should eql(@teacher)
      @assessment.artifact.score.should eql(5.0)
      @assessment.data.first[:comments_html].should be_nil
    end
    
    it "should not update scores if not used for grading" do
      assignment_model
      @teacher = user(:active_all => true)
      @course.enroll_teacher(@teacher).accept
      @student = user(:active_all => true)
      @course.enroll_student(@student).accept
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
      @assessment.should_not be_nil
      @assessment.user.should eql(@student)
      @assessment.assessor.should eql(@teacher)
      @assessment.artifact.should_not be_nil
      @assessment.artifact.should be_is_a(Submission)
      @assessment.artifact.user.should eql(@student)
      @assessment.artifact.grader.should eql(nil)
      @assessment.artifact.score.should eql(nil)
    end
    
    it "should not update scores if not a valid grader" do
      assignment_model
      @teacher = user(:active_all => true)
      @course.enroll_teacher(@teacher).accept
      @student = user(:active_all => true)
      @course.enroll_student(@student).accept
      @student2 = user(:active_all => true)
      @course.enroll_student(@student2).accept
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
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
      @assessment.should_not be_nil
      @assessment.user.should eql(@student)
      @assessment.assessor.should eql(@student2)
      @assessment.artifact.should_not be_nil
      @assessment.artifact.should be_is_a(Submission)
      @assessment.artifact.user.should eql(@student)
      @assessment.artifact.grader.should eql(nil)
      @assessment.artifact.score.should eql(nil)
    end
  end
end
