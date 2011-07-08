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

describe LearningOutcome do
  context "outcomes" do
    it "should allow learning outcome rows in the rubric" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @rubric = Rubric.new(:context => @course)
      @rubric.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome.id
        }
      ]
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @rubric.should_not be_new_record
      @rubric.learning_outcome_tags.should_not be_empty
      @rubric.learning_outcome_tags.first.learning_outcome_id.should eql(@outcome.id)
    end
    
    it "should delete learning outcome tags when they no longer exist" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @rubric = Rubric.new(:context => @course)
      @rubric.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome.id
        }
      ]
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @rubric.should_not be_new_record
      @rubric.learning_outcome_tags.should_not be_empty
      @rubric.learning_outcome_tags.first.learning_outcome_id.should eql(@outcome.id)
      @rubric.data = [{
        :points => 5,
        :description => "Row",
        :id => 1,
        :ratings => [
          {
            :points => 5,
            :description => "Rockin'",
            :criterion_id => 1,
            :id => 2
          },
          {
            :points => 0,
            :description => "Lame",
            :criterion_id => 1,
            :id => 3
          }
        ]
      }]
      @rubric.save!
      @rubric.learning_outcome_tags.active.should be_empty
    end
    
    it "should create learning outcome associations for multiple outcome rows" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @outcome2 = @course.learning_outcomes.create!
      @rubric = Rubric.create!(:context => @course)
      @rubric.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome.id
        },
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome2.id
        }
      ]
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @rubric.should_not be_new_record
      @rubric.learning_outcome_tags.should_not be_empty
      @rubric.learning_outcome_tags.map(&:learning_outcome_id).sort.should eql([@outcome.id, @outcome2.id].sort)
    end
    
    it "should create outcome results when outcome-aligned rubrics are assessed" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @rubric = Rubric.create!(:context => @course)
      @rubric.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome.id
        }
      ]
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @rubric.should_not be_new_record
      @rubric.learning_outcome_tags.should_not be_empty
      @rubric.learning_outcome_tags.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @assignment.learning_outcome_tags.should_not be_empty
      @assignment.learning_outcome_tags.count.should eql(1)
      @submission = @assignment.grade_student(@user, :grade => "10").first
      @assessment = @a.assess({
        :user => @user,
        :assessor => @user,
        :artifact => @submission,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_1 => {
            :points => 2,
            :comments => "cool, yo"
          }
        }
      })
      @outcome.learning_outcome_results.should_not be_empty
      @result = @outcome.learning_outcome_results.first
      @result.user_id.should eql(@user.id)
      @result.score.should eql(2.0)
      @result.possible.should eql(3.0)
      @result.original_score.should eql(2.0)
      @result.original_possible.should eql(3.0)
      @result.mastery.should eql(nil)
      @result.versions.length.should eql(1)
      n = @result.version_number
      @assessment = @a.assess({
        :user => @user,
        :assessor => @user,
        :artifact => @submission,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_1 => {
            :points => 3,
            :comments => "cool, yo"
          }
        }
      })
      @result.reload
      @result.versions.length.should eql(2)
      @result.version_number.should > n
      @result.score.should eql(3.0)
      @result.possible.should eql(3.0)
      @result.original_score.should eql(2.0)
      @result.mastery.should eql(true)
    end
    
    it "should override non-rubric-based alignments with rubric-based alignments for the same assignment" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @tag = @outcome.align(@assignment, @course, :mastery_type => "points")
      @tag.should_not be_nil
      @tag.content.should eql(@assignment)
      @tag.context.should eql(@course)
      @rubric = Rubric.create!(:context => @course)
      @rubric.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome.id
        }
      ]
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @rubric.should_not be_new_record
      
      @rubric.learning_outcome_tags.should_not be_empty
      @rubric.learning_outcome_tags.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @assignment.learning_outcome_tags.count.should eql(1)
      @assignment.learning_outcome_tags.first.should eql(@tag)
      @assignment.learning_outcome_tags.first.rubric_association_id.should eql(@a.id)
      @tag.reload
      @tag.rubric_association_id.should eql(@a.id)

      @submission = @assignment.grade_student(@user, :grade => "10").first
      @outcome.learning_outcome_results.should be_empty
      @assessment = @a.assess({
        :user => @user,
        :assessor => @user,
        :artifact => @submission,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_1 => {
            :points => 2,
            :comments => "cool, yo"
          }
        }
      })
      @outcome.reload
      @outcome.learning_outcome_results.should_not be_empty
      @outcome.learning_outcome_results.length.should eql(1)
      @result = @outcome.learning_outcome_results.select{|r| r.artifact_type == 'RubricAssessment'}.first
      @result.should_not be_nil
      @result.user_id.should eql(@user.id)
      @result.score.should eql(2.0)
      @result.possible.should eql(3.0)
      @result.original_score.should eql(2.0)
      @result.original_possible.should eql(3.0)
      @result.mastery.should eql(nil)
      n = @result.version_number
    end
    it "should not override rubric-based alignments with non-rubric-based alignments for the same assignment" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @rubric = Rubric.create!(:context => @course)
      @rubric.data = [
        {
          :points => 3,
          :description => "Outcome row",
          :id => 1,
          :ratings => [
            {
              :points => 3,
              :description => "Rockin'",
              :criterion_id => 1,
              :id => 2
            },
            {
              :points => 0,
              :description => "Lame",
              :criterion_id => 1,
              :id => 3
            }
          ],
          :learning_outcome_id => @outcome.id
        }
      ]
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @rubric.should_not be_new_record
      
      @rubric.learning_outcome_tags.should_not be_empty
      @rubric.learning_outcome_tags.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.learning_outcome_tags.count.should eql(1)
      @tags = ContentTag.learning_outcome_tags_for(@assignment)
      @tags.length.should eql(1)
      @tags[0].rubric_association_id.should eql(@a.id)
      @assignment.reload
      @submission = @assignment.grade_student(@user, :grade => "10").first
      @assessment = @a.assess({
        :user => @user,
        :assessor => @user,
        :artifact => @submission,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_1 => {
            :points => 2,
            :comments => "cool, yo"
          }
        }
      })
      @outcome.learning_outcome_results.should_not be_empty
      @outcome.learning_outcome_results.length.should eql(1)
      @result = @outcome.learning_outcome_results.select{|r| r.artifact_type == 'RubricAssessment'}.first
      @result.should_not be_nil
      @result.user_id.should eql(@user.id)
      @result.score.should eql(2.0)
      @result.possible.should eql(3.0)
      @result.original_score.should eql(2.0)
      @result.original_possible.should eql(3.0)
      @result.mastery.should eql(nil)
      n = @result.version_number
    end
    it "should build an outcome result for a non-rubric alignment" do
      assignment_model
      @outcome = @course.learning_outcomes.create!
      @tag = @outcome.align(@assignment, @course, :mastery_type => "points")
      @tag.should_not be_nil
      @tag.content.should eql(@assignment)
      @tag.context.should eql(@course)

      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @tag.rubric_association_id.should eql(nil)
      @assignment.reload
      @assignment.learning_outcome_tags.should_not be_empty
      @assignment.learning_outcome_tags.length.should eql(1)
      @assignment.learning_outcome_tags.map(&:learning_outcome_id).uniq.should eql([@outcome.id])
      
      @submission = @assignment.grade_student(@user, :grade => "10").first
      @outcome.learning_outcome_results.should_not be_empty
      @outcome.learning_outcome_results.length.should eql(1)

      @result = @outcome.learning_outcome_results.select{|r| r.artifact_type == 'Submission'}.first
      @result.should_not be_nil
      @result.user_id.should eql(@user.id)
      @result.possible.should eql(1.5)
      @result.score.should eql(10.0)
      @result.original_score.should eql(10.0)
      @result.original_possible.should eql(1.5)
      @result.mastery.should eql(true)
    end
  end
end
