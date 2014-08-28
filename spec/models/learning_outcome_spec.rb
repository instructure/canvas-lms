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
    before :once do
      assignment_model
      @outcome = @course.created_learning_outcomes.create!(:title => 'outcome')
    end

    it "should allow learning outcome rows in the rubric" do
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
      @rubric.save!
      @rubric.should_not be_new_record
      @rubric.reload
      @rubric.learning_outcome_alignments.should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
    end

    it "should delete learning outcome alignments when they no longer exist" do
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
      @rubric.save!
      @rubric.should_not be_new_record
      @rubric.reload
      @rubric.learning_outcome_alignments.should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
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
      @rubric.reload
      @rubric.learning_outcome_alignments.active.should be_empty
    end

    it "should create learning outcome associations for multiple outcome rows" do
      @outcome2 = @course.created_learning_outcomes.create!(:title => 'outcome2')
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
      @rubric.save!
      @rubric.reload
      @rubric.should_not be_new_record
      @rubric.learning_outcome_alignments.should_not be_empty
      @rubric.learning_outcome_alignments.map(&:learning_outcome_id).sort.should eql([@outcome.id, @outcome2.id].sort)
    end

    it "should create outcome results when outcome-aligned rubrics are assessed" do
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
      @rubric.save!
      @rubric.reload
      @rubric.should_not be_new_record
      @rubric.learning_outcome_alignments.should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @assignment.learning_outcome_alignments.count.should eql(1)
      @assignment.rubric_association.should_not be_nil
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
      @result.mastery.should eql(false)
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
      @alignment = @outcome.align(@assignment, @course, :mastery_type => "points")
      @alignment.should_not be_nil
      @alignment.content.should eql(@assignment)
      @alignment.context.should eql(@course)
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
      @rubric.save!
      @rubric.reload
      @rubric.should_not be_new_record

      @rubric.learning_outcome_alignments.should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @assignment.learning_outcome_alignments.count.should eql(1)
      @assignment.learning_outcome_alignments.first.should eql(@alignment)
      @assignment.learning_outcome_alignments.first.should have_rubric_association
      @alignment.reload
      @alignment.should have_rubric_association

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
      @result.mastery.should eql(false)
      n = @result.version_number
    end

    it "should not override rubric-based alignments with non-rubric-based alignments for the same assignment" do
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
      @rubric.save!
      @rubric.reload
      @rubric.should_not be_new_record

      @rubric.learning_outcome_alignments.should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @assignment.learning_outcome_alignments.count.should eql(1)
      @alignment = @assignment.learning_outcome_alignments.first
      @alignment.learning_outcome.should_not be_deleted
      @alignment.should have_rubric_association
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
      @result.mastery.should eql(false)
      n = @result.version_number
    end
  end

  describe "permissions" do
    context "global outcome" do
      before :once do
        @outcome = LearningOutcome.create!(:title => 'global outcome')
      end

      it "should grant :read to any user" do
        @outcome.grants_right?(User.new, :read).should be_true
      end

      it "should not grant :read without a user" do
        @outcome.grants_right?(nil, :read).should be_false
      end

      it "should grant :update iff the site admin grants :manage_global_outcomes" do
        @admin = stub

        Account.site_admin.expects(:grants_right?).with(@admin, nil, :manage_global_outcomes).returns(true)
        @outcome.grants_right?(@admin, :update).should be_true
        @outcome.clear_permissions_cache(@admin)

        Account.site_admin.expects(:grants_right?).with(@admin, nil, :manage_global_outcomes).returns(false)
        @outcome.grants_right?(@admin, :update).should be_false
      end
    end

    context "non-global outcome" do
      before :once do
        course(:active_course => 1)
        @outcome = @course.created_learning_outcomes.create!(:title => 'non-global outcome')
      end

      it "should grant :read to users with :read_outcomes on the context" do
        student_in_course(:active_enrollment => 1)
        @outcome.grants_right?(@user, :read).should be_true
      end

      it "should not grant :read to users without :read_outcomes on the context" do
        @outcome.grants_right?(User.new, :read).should be_false
      end

      it "should grant :update to users with :manage_outcomes on the context" do
        teacher_in_course(:active_enrollment => 1)
        @outcome.grants_right?(@user, :update).should be_true
      end

      it "should not grant :read to users without :read_outcomes on the context" do
        student_in_course(:active_enrollment => 1)
        @outcome.grants_right?(User.new, :update).should be_false
      end
    end
  end
end
