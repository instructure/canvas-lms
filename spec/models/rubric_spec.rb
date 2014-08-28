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

describe Rubric do
  
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
      @rubric.learning_outcome_alignments(true).should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
    end
    
    it "should delete learning outcome tags when they no longer exist" do
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
      @rubric.learning_outcome_alignments(true).should_not be_empty
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
      @rubric.learning_outcome_alignments.active.should be_empty
    end

    it "should create learning outcome associations for multiple outcome rows" do
      @outcome2 = @course.created_learning_outcomes.create!(:title => 'outcome2')
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
      @rubric.should_not be_new_record
      @rubric.learning_outcome_alignments(true).should_not be_empty
      @rubric.learning_outcome_alignments.map(&:learning_outcome_id).sort.should eql([@outcome.id, @outcome2.id].sort)
    end

    it "should create outcome results when outcome-aligned rubrics are assessed" do
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
      @rubric.learning_outcome_alignments(true).should_not be_empty
      @rubric.learning_outcome_alignments.first.learning_outcome_id.should eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @assignment.learning_outcome_alignments.should_not be_empty
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
      @result.mastery.should be_false
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
      @result.version_number.should > n
      @result.score.should eql(3.0)
      @result.possible.should eql(3.0)
      @result.original_score.should eql(2.0)
      @result.mastery.should be_true
    end
  end

  context "fractional_points" do
    it "should allow fractional points" do
      course
      @rubric = Rubric.new(:context => @course)
      @rubric.data = [
        {
          :points => 0.5,
          :description => "Fraction row",
          :id => 1,
          :ratings => [
            {
              :points => 0.5,
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
        }
      ]
      @rubric.save!

      @rubric2 = Rubric.find(@rubric.id)
      @rubric2.data.first[:points].should eql(0.5)
      @rubric2.data.first[:ratings].first[:points].should eql(0.5)
    end
  end

  it "should be cool about duplicate titles" do
    course_with_teacher

    r1 = Rubric.new :title => "rubric", :context => @course
    r1.save!
    r1.title.should eql "rubric"

    r2 = Rubric.new :title => "rubric", :context => @course
    r2.save!
    r2.title.should eql "rubric (1)"

    r1.destroy

    r3 = Rubric.create! :title => "rubric", :context => @course
    r3.title.should eql "rubric"

    r3.title = "rubric"
    r3.save!
    r3.title.should eql "rubric"
  end

  context "#update_with_association" do
    before :once do
      course_with_teacher
      @assignment = @course.assignments.create! title: "aaaaah",
                                                points_possible: 20
      @rubric = Rubric.new title: "r", context: @course
    end

    def test_rubric_associations(opts)
      @rubric.should be_new_record
      # need to run the test 2x because the code path is different for new rubrics
      2.times do
        @rubric.update_with_association(@teacher, {
          id: @rubric.id,
          title: @rubric.title,
          criteria: {
            "0" => {
              description: "correctness",
              points: 15,
              ratings: {"0" => {points: 15, description: "asdf"}},
            },
          },
        }, @course, {
          association_object: @assignment,
          update_if_existing: true,
          use_for_grading: "1",
          purpose: "grading",
          skip_updating_points_possible: opts[:leave_different]
        })
        yield
      end
    end

    it "doesn't accidentally update assignment points" do
      test_rubric_associations(leave_different: true) do
        @rubric.points_possible.should == 15
        @assignment.reload.points_possible.should == 20
      end
    end

    it "does update assignment points if you want it to" do
      test_rubric_associations(leave_different: false) do
        @rubric.points_possible.should == 15
        @assignment.reload.points_possible.should == 15
      end
    end
  end
end
