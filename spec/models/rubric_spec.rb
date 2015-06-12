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
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments(true)).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
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
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments(true)).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
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
      expect(@rubric.learning_outcome_alignments.active).to be_empty
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
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments(true)).not_to be_empty
      expect(@rubric.learning_outcome_alignments.map(&:learning_outcome_id).sort).to eql([@outcome.id, @outcome2.id].sort)
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
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments(true)).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments).not_to be_empty
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
      expect(@outcome.learning_outcome_results).not_to be_empty
      @result = @outcome.learning_outcome_results.first
      expect(@result.user_id).to eql(@user.id)
      expect(@result.score).to eql(2.0)
      expect(@result.possible).to eql(3.0)
      expect(@result.original_score).to eql(2.0)
      expect(@result.original_possible).to eql(3.0)
      expect(@result.mastery).to be_falsey
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
      expect(@result.version_number).to be > n
      expect(@result.score).to eql(3.0)
      expect(@result.possible).to eql(3.0)
      expect(@result.original_score).to eql(2.0)
      expect(@result.mastery).to be_truthy
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
      expect(@rubric2.data.first[:points]).to eql(0.5)
      expect(@rubric2.data.first[:ratings].first[:points]).to eql(0.5)
    end
  end

  it "should be cool about duplicate titles" do
    course_with_teacher

    r1 = Rubric.new :title => "rubric", :context => @course
    r1.save!
    expect(r1.title).to eql "rubric"

    r2 = Rubric.new :title => "rubric", :context => @course
    r2.save!
    expect(r2.title).to eql "rubric (1)"

    r1.destroy

    r3 = Rubric.create! :title => "rubric", :context => @course
    expect(r3.title).to eql "rubric"

    r3.title = "rubric"
    r3.save!
    expect(r3.title).to eql "rubric"
  end

  context "#update_with_association" do
    before :once do
      course_with_teacher
      @assignment = @course.assignments.create! title: "aaaaah",
                                                points_possible: 20
      @rubric = Rubric.new title: "r", context: @course
    end

    def test_rubric_associations(opts)
      expect(@rubric).to be_new_record
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
        expect(@rubric.points_possible).to eq 15
        expect(@assignment.reload.points_possible).to eq 20
      end
    end

    it "does update assignment points if you want it to" do
      test_rubric_associations(leave_different: false) do
        expect(@rubric.points_possible).to eq 15
        expect(@assignment.reload.points_possible).to eq 15
      end
    end
  end
end
