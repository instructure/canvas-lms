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

  def outcome_errors(prop)
    @outcome.errors[prop].map(&:to_s)
  end

  context "outcomes" do
    before :once do
      assignment_model
      @outcome = @course.created_learning_outcomes.create!(:title => 'outcome')
    end

    def assess_with(outcome=@outcome)
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
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
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
      @result = @outcome.learning_outcome_results.first
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
      @rubric.reload
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
      @rubric.reload
      expect(@rubric.learning_outcome_alignments).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
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
      expect(@rubric).not_to be_new_record
      @rubric.reload
      expect(@rubric.learning_outcome_alignments).not_to be_empty
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
      @rubric.reload
      expect(@rubric.learning_outcome_alignments.active).to be_empty
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
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments).not_to be_empty
      expect(@rubric.learning_outcome_alignments.map(&:learning_outcome_id).sort).to eql([@outcome.id, @outcome2.id].sort)
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
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments.count).to eql(1)
      expect(@assignment.rubric_association).not_to be_nil
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
      expect(@result.mastery).to eql(false)
      expect(@result.versions.length).to eql(1)
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
      expect(@result.versions.length).to eql(2)
      expect(@result.version_number).to be > n
      expect(@result.score).to eql(3.0)
      expect(@result.possible).to eql(3.0)
      expect(@result.original_score).to eql(2.0)
      expect(@result.mastery).to eql(true)
    end

    it "should override non-rubric-based alignments with rubric-based alignments for the same assignment" do
      @alignment = @outcome.align(@assignment, @course, :mastery_type => "points")
      expect(@alignment).not_to be_nil
      expect(@alignment.content).to eql(@assignment)
      expect(@alignment.context).to eql(@course)
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
      expect(@rubric).not_to be_new_record

      expect(@rubric.learning_outcome_alignments).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments.count).to eql(1)
      expect(@assignment.learning_outcome_alignments.first).to eql(@alignment)
      expect(@assignment.learning_outcome_alignments.first).to have_rubric_association
      @alignment.reload
      expect(@alignment).to have_rubric_association

      @submission = @assignment.grade_student(@user, :grade => "10").first
      expect(@outcome.learning_outcome_results).to be_empty
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
      expect(@outcome.learning_outcome_results).not_to be_empty
      expect(@outcome.learning_outcome_results.length).to eql(1)
      @result = @outcome.learning_outcome_results.select{|r| r.artifact_type == 'RubricAssessment'}.first
      expect(@result).not_to be_nil
      expect(@result.user_id).to eql(@user.id)
      expect(@result.score).to eql(2.0)
      expect(@result.possible).to eql(3.0)
      expect(@result.original_score).to eql(2.0)
      expect(@result.original_possible).to eql(3.0)
      expect(@result.mastery).to eql(false)
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
      expect(@rubric).not_to be_new_record

      expect(@rubric.learning_outcome_alignments).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      @user = user(:active_all => true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments.count).to eql(1)
      @alignment = @assignment.learning_outcome_alignments.first
      expect(@alignment.learning_outcome).not_to be_deleted
      expect(@alignment).to have_rubric_association
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
      expect(@outcome.learning_outcome_results).not_to be_empty
      expect(@outcome.learning_outcome_results.length).to eql(1)
      @result = @outcome.learning_outcome_results.select{|r| r.artifact_type == 'RubricAssessment'}.first
      expect(@result).not_to be_nil
      expect(@result.user_id).to eql(@user.id)
      expect(@result.score).to eql(2.0)
      expect(@result.possible).to eql(3.0)
      expect(@result.original_score).to eql(2.0)
      expect(@result.original_possible).to eql(3.0)
      expect(@result.mastery).to eql(false)
    end

    it "should not let you change calculation_method if it has been used to assess a student" do
      @outcome.calculation_method = 'latest'
      @outcome.save!
      expect(@outcome.calculation_method).to eq('latest')
      assess_with
      expect(@outcome).to have(:no).errors_on(:calculation_method)
      @outcome.calculation_method = 'n_mastery'
      @outcome.save
      expect(@outcome).to have(1).error_on(:calculation_method)
      expect(@outcome).to have(1).error
      expect(outcome_errors(:calculation_method).first).to include("outcome has been used to assess a student")
      @outcome.reload
      expect(@outcome.calculation_method).to eq('latest')
    end

    it "should not let you change calculation_int if it has been used to assess a student" do
      @outcome.calculation_method = 'decaying_average'
      @outcome.calculation_int = 24
      @outcome.save!
      expect(@outcome.calculation_int).to eq(24)
      assess_with
      expect(@outcome).to have(:no).errors
      @outcome.calculation_int = 71
      @outcome.save
      expect(@outcome).to have(1).error_on(:calculation_int)
      expect(@outcome).to have(1).error
      expect(outcome_errors(:calculation_int).first).to include("outcome has been used to assess a student")
      @outcome.reload
      expect(@outcome.calculation_int).to eq(24)
    end

    it "should not let you set the calculation_method to nil if it has been set to something else" do
      @outcome.calculation_method = 'latest'
      @outcome.save!
      expect(@outcome.calculation_method).to eq('latest')
      expect(@outcome).to have(:no).errors
      @outcome.calculation_method = nil
      @outcome.save
      expect(@outcome).to have(1).error_on(:calculation_method)
      expect(@outcome).to have(1).error
      expect(outcome_errors(:calculation_method).first).to include("is not included in the list")
      @outcome.reload
      expect(@outcome.calculation_method).to eq('latest')
    end

    context "should not let you set calculation_int to nil for certain calculation methods" do
      calc_method = [
        'decaying_average',
        'n_mastery'
      ]

      calc_method.each do |method|
        it "should not let you set calculation_int to nil if calculation_method is #{method}" do
          @outcome.calculation_method = method
          @outcome.calculation_int = 4
          @outcome.save!
          expect(@outcome.calculation_method).to eq(method)
          expect(@outcome.calculation_int).to eq(4)
          expect(@outcome).to have(:no).errors
          @outcome.calculation_int = nil
          @outcome.save
          expect(@outcome).to have(1).error_on(:calculation_int)
          expect(@outcome).to have(1).errors
          expect(outcome_errors(:calculation_int).first).to include("not a valid calculation_int")
          @outcome.reload
          expect(@outcome.calculation_method).to eq(method)
          expect(@outcome.calculation_int).to eq(4)
        end
      end
    end

    context "should set calculation_int to default if the calculation_method is changed and calculation_int isn't set" do
      method_to_int = {
        # "decaying_average" => { default: 75, testval: 4, altmeth: 'n_mastery' },
        # "n_mastery" => { default: 5, testval: nil, altmeth: 'highest' },
        "highest" => { default: nil, testval: nil, altmeth: 'latest' },
        "latest" => { default: nil, testval: 72, altmeth: 'decaying_average' },
      }

      method_to_int.each do |method, set|
        it "should set calculation_int to #{set[:default]} if the calculation_method is changed to #{method} and calculation_int isn't set" do
          @outcome.calculation_method = set[:altmeth]
          @outcome.calculation_int = set[:testval]
          @outcome.save!
          expect(@outcome.calculation_method).to eq(set[:altmeth])
          expect(@outcome.calculation_int).to eq(set[:testval])
          @outcome.calculation_method = method
          @outcome.save!
          @outcome.reload
          expect(@outcome.calculation_method).to eq(method)
          expect(@outcome.calculation_int).to eq(set[:default])
        end
      end
    end
  end

  context "Don't create outcomes with illegal values" do
    before :once do
      assignment_model
    end

    it "should reject creation of a learning outcome with an illegal calculation_method" do
      @outcome = @course.created_learning_outcomes.create(
        :title => 'outcome',
        :calculation_method => 'foo bar baz qux'
      )
      expect(@outcome).not_to be_valid
      expect(@outcome).to have(1).error
      expect(@outcome).to have(1).error_on(:calculation_method)
      expect(outcome_errors(:calculation_method).first).to include("is not included in the list")

      @outcome = LearningOutcome.new(
        :title => 'outcome',
        :calculation_method => 'foo bar baz qux'
      )
      expect(@outcome).not_to be_valid
      expect(@outcome).to have(1).error
      expect(@outcome).to have(1).error_on(:calculation_method)
      expect(outcome_errors(:calculation_method).first).to include("is not included in the list")
    end

    context "illegal calculation ints" do
      context "per method" do
        calc_method = [
          'decaying_average',
          'n_mastery',
          'highest',
          'latest'
        ]

        calc_method.each do |method|
          it "should reject creation of a learning outcome with an illegal calculation_int for calculation_method of '#{method}'" do
            @outcome = @course.created_learning_outcomes.create(
              :title => 'outcome',
              :calculation_method => method,
              :calculation_int => '1500'
            )
            expect(@outcome).not_to be_valid
            expect(@outcome).to have(1).error
            expect(@outcome).to have(1).error_on(:calculation_int)
            expect(outcome_errors(:calculation_int).first).to include("not a valid calculation_int")

            @outcome = LearningOutcome.new(
              :title => 'outcome',
              :calculation_method => method,
              :calculation_int => '1500'
            )
            expect(@outcome).not_to be_valid
            expect(@outcome).to have(1).error
            expect(@outcome).to have(1).error_on(:calculation_int)
            expect(outcome_errors(:calculation_int).first).to include("not a valid calculation_int")
          end
        end
      end
    end
  end

  describe "permissions" do
    context "global outcome" do
      before :once do
        @outcome = LearningOutcome.create!(:title => 'global outcome')
      end

      it "should grant :read to any user" do
        expect(@outcome.grants_right?(User.new, :read)).to be_truthy
      end

      it "should not grant :read without a user" do
        expect(@outcome.grants_right?(nil, :read)).to be_falsey
      end

      it "should grant :update iff the site admin grants :manage_global_outcomes" do
        @admin = stub

        Account.site_admin.expects(:grants_right?).with(@admin, nil, :manage_global_outcomes).returns(true)
        expect(@outcome.grants_right?(@admin, :update)).to be_truthy
        @outcome.clear_permissions_cache(@admin)

        Account.site_admin.expects(:grants_right?).with(@admin, nil, :manage_global_outcomes).returns(false)
        expect(@outcome.grants_right?(@admin, :update)).to be_falsey
      end
    end

    context "non-global outcome" do
      before :once do
        course(:active_course => 1)
        @outcome = @course.created_learning_outcomes.create!(:title => 'non-global outcome')
      end

      it "should grant :read to users with :read_outcomes on the context" do
        student_in_course(:active_enrollment => 1)
        expect(@outcome.grants_right?(@user, :read)).to be_truthy
      end

      it "should not grant :read to users without :read_outcomes on the context" do
        expect(@outcome.grants_right?(User.new, :read)).to be_falsey
      end

      it "should grant :update to users with :manage_outcomes on the context" do
        teacher_in_course(:active_enrollment => 1)
        expect(@outcome.grants_right?(@user, :update)).to be_truthy
      end

      it "should not grant :read to users without :read_outcomes on the context" do
        student_in_course(:active_enrollment => 1)
        expect(@outcome.grants_right?(User.new, :update)).to be_falsey
      end
    end
  end

  context "mastery values" do
    context "can be set" do
      before :once do
        @outcome = LearningOutcome.create!(
          :title => 'outcome',
          :calculation_method => 'highest',
          :calculation_int => nil
        )
      end

      it { is_expected.to respond_to(:calculation_method) }
      it { is_expected.to respond_to(:calculation_int) }

      it "should allow setting a calculation_method" do
        expect(@outcome.calculation_method).not_to eq('n_mastery')
        @outcome.calculation_method = 'n_mastery'
        @outcome.calculation_int = 5
        @outcome.save
        expect(@outcome).to have(:no).errors
        @outcome.reload
        expect(@outcome.calculation_method).to eq('n_mastery')
      end

      context "setting a calculation_int" do
        method_to_int = {
          "decaying_average" => 85,
          "n_mastery" => 2,
        }

        method_to_int.each do |method, int|
          it "should allow setting a calculation_int for #{method}" do
            expect(@outcome.calculation_int).not_to eq(85)
            @outcome.calculation_method = method
            @outcome.calculation_int = int
            @outcome.save
            expect(@outcome).to have(:no).errors
            @outcome.reload
            expect(@outcome.calculation_method).to eq(method)
            expect(@outcome.calculation_int).to eq(int)
          end
        end
      end

      it "should allow updating the calculation_int and calculation_method together" do
        @outcome.calculation_method = 'decaying_average'
        @outcome.calculation_int = 59
        @outcome.save
        expect(@outcome).to have(:no).errors
        @outcome.reload
        expect(@outcome.calculation_method).to eq('decaying_average')
        expect(@outcome.calculation_int).to eq(59)
        @outcome.calculation_method = 'n_mastery'
        @outcome.calculation_int = 3
        @outcome.save
        expect(@outcome).to have(:no).errors
        @outcome.reload
        expect(@outcome.calculation_method).to eq('n_mastery')
        expect(@outcome.calculation_int).to eq(3)
      end
    end

    context "reject illegal values" do
      before :once do
        @outcome = LearningOutcome.create!(
          :title => 'outcome',
          :calculation_method => 'highest',
          :calculation_int => nil
        )
      end

      it "should reject an illegal calculation_method" do
        expect(@outcome.calculation_method).not_to eq('foo bar baz qux')
        expect(@outcome.calculation_method).to eq('highest')
        @outcome.calculation_method = 'foo bar baz qux'
        @outcome.save
        expect(@outcome).to have(1).error_on(:calculation_method)
        expect(@outcome).to have(1).errors
        expect(outcome_errors(:calculation_method).first).to include("is not included in the list")
        @outcome.reload
        expect(@outcome.calculation_method).not_to eq('foo bar baz qux')
        expect(@outcome.calculation_method).to eq('highest')
      end

      it "should not let the calculation_method be set to nil" do
        expect(@outcome.calculation_method).to eq('highest')
        expect(@outcome).to have(:no).errors
        @outcome.calculation_method = nil
        @outcome.save
        expect(@outcome).to have(1).error
        expect(@outcome).to have(1).error_on(:calculation_method)
        expect(outcome_errors(:calculation_method).first).to include("is not included in the list")
        @outcome.reload
        expect(@outcome.calculation_method).not_to be_nil
        expect(@outcome.calculation_method).to eq('highest')
      end

      context "reject illegal calculation_int s" do
        method_to_int = {
          'decaying_average' => 68,
          'n_mastery' => 4,
          'highest' => nil,
          'latest' => nil,
        }

        method_to_int.each do |method, int|
          it "should reject an illegal calculation_int for #{method}" do
            @outcome.calculation_method = method
            @outcome.calculation_int = int
            @outcome.save
            expect(@outcome).to have(:no).errors
            @outcome.reload
            expect(@outcome.calculation_method).to eq(method)
            expect(@outcome.calculation_int).to eq(int)
            @outcome.calculation_int = 15000
            @outcome.save
            expect(@outcome).to have(1).error_on(:calculation_int)
            expect(@outcome).to have(1).errors
            expect(outcome_errors(:calculation_int).first).to include("not a valid calculation_int")
            @outcome.reload
            expect(@outcome.calculation_method).to eq(method)
            expect(@outcome.calculation_int).to eq(int)
          end
        end
      end
    end

    context "default values" do
      it "should default calculation_method to highest" do
        @outcome = LearningOutcome.create!(:title => 'outcome')
        expect(@outcome.calculation_method).to eql('highest')
      end

      it "should default calculation_int to nil for highest" do
        @outcome = LearningOutcome.create!(
          :title => 'outcome',
          :calculation_method => 'highest'
        )
        expect(@outcome.calculation_method).to eql('highest')
        expect(@outcome.calculation_int).to be_nil
      end

      it "should default calculation_int to nil for latest" do
        @outcome = LearningOutcome.create!(
          :title => 'outcome',
          :calculation_method => 'latest'
        )
        expect(@outcome.calculation_method).to eql('latest')
        expect(@outcome.calculation_int).to be_nil
      end

      # This is to prevent changing behavior of existing outcomes made before we added the
      # ability to set a calculation_method
      it "should set calculation_method to highest if the record is pre-existing and nil" do
        @outcome = LearningOutcome.create!(:title => 'outcome')
        @outcome.update_column(:calculation_method, nil)
        @outcome.reload
        expect(@outcome.calculation_method).to be_nil
        @outcome.description = "foo bar baz qux"
        @outcome.save!
        @outcome.reload
        expect(@outcome.description).to eq("foo bar baz qux")
        expect(@outcome.calculation_method).to eq('highest')
      end
    end
  end
end
