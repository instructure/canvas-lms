# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  context 'validations' do
    describe 'lengths' do
      it { is_expected.to validate_length_of(:description).is_at_most(described_class.maximum_text_length) }
      it { is_expected.to validate_length_of(:short_description).is_at_most(described_class.maximum_string_length) }
      it { is_expected.to validate_length_of(:vendor_guid).is_at_most(described_class.maximum_string_length) }
      it { is_expected.to validate_length_of(:display_name).is_at_most(described_class.maximum_string_length) }
    end

    describe 'nullable' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value(nil).for(:short_description) }
      it { is_expected.to allow_value(nil).for(:vendor_guid) }
      it { is_expected.to allow_value(nil).for(:display_name) }
    end

    describe 'blankable' do
      it { is_expected.to allow_value("").for(:description) }
      it { is_expected.not_to allow_value("").for(:short_description) }
      it { is_expected.to allow_value("").for(:vendor_guid) }
      it { is_expected.to allow_value("").for(:display_name) }
    end
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
          :learning_outcome_id => outcome.id
        }
      ]
      @rubric.save!
      @user = user_factory(active_all: true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher).first
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

    it "adding outcomes to a rubric should increment datadog counter" do
      expect(InstStatsd::Statsd).to receive(:increment).with('learning_outcome.align')
      expect(InstStatsd::Statsd).to receive(:increment).with("feature_flag_check", any_args).at_least(:once)
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
      @user = user_factory(active_all: true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments.count).to eql(1)
      expect(@assignment.rubric_association).not_to be_nil
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher).first
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
      @user = user_factory(active_all: true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments.count).to eql(1)
      expect(@assignment.learning_outcome_alignments.first).to eql(@alignment)
      expect(@assignment.learning_outcome_alignments.first).to have_rubric_association
      @alignment.reload
      expect(@alignment).to have_rubric_association

      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher).first
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
      @result = @outcome.learning_outcome_results.find{|r| r.artifact_type == 'RubricAssessment'}
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
      @user = user_factory(active_all: true)
      @e = @course.enroll_student(@user)
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      expect(@assignment.learning_outcome_alignments.count).to eql(1)
      @alignment = @assignment.learning_outcome_alignments.first
      expect(@alignment.learning_outcome).not_to be_deleted
      expect(@alignment).to have_rubric_association
      @assignment.reload
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher).first
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
      @result = @outcome.learning_outcome_results.find{|r| r.artifact_type == 'RubricAssessment'}
      expect(@result).not_to be_nil
      expect(@result.user_id).to eql(@user.id)
      expect(@result.score).to eql(2.0)
      expect(@result.possible).to eql(3.0)
      expect(@result.original_score).to eql(2.0)
      expect(@result.original_possible).to eql(3.0)
      expect(@result.mastery).to eql(false)
    end

    it "should not let you set the calculation_method to nil if it has been set to something else" do
      @outcome.calculation_method = 'latest'
      @outcome.save!
      expect(@outcome.calculation_method).to eq('latest')
      expect(@outcome).to have(:no).errors
      @outcome.reload
      @outcome.calculation_method = nil
      @outcome.save
      expect(@outcome).to have(1).error_on(:calculation_method)
      expect(@outcome).to have(1).error
      expect(outcome_errors(:calculation_method).first).to include("calculation_method must be one of")
      @outcome.reload
      expect(@outcome.calculation_method).to eq('latest')
    end

    context "should not let you set calculation_int to invalid values for certain calculation methods" do
      calc_method = [
        'decaying_average',
        'n_mastery'
      ]
      invalid_values = {
        decaying_average: [0, 100, 1000],
        n_mastery: [0, 10]
      }.with_indifferent_access

      calc_method.each do |method|
        invalid_values[method].each do |invalid_value|
          it "should not let you set calculation_int to #{invalid_value} if calculation_method is #{method}" do
            @outcome.calculation_method = method
            @outcome.calculation_int = 4
            @outcome.save!
            expect(@outcome.calculation_method).to eq(method)
            expect(@outcome.calculation_int).to eq(4)
            expect(@outcome).to have(:no).errors
            @outcome.calculation_int = invalid_value
            @outcome.save
            expect(@outcome).to have(1).error_on(:calculation_int)
            expect(@outcome).to have(1).errors
            expect(outcome_errors(:calculation_int).first).to include("is not a valid value for this calculation method")
            @outcome.reload
            expect(@outcome.calculation_method).to eq(method)
            expect(@outcome.calculation_int).to eq(4)
          end
        end
      end
    end

    context "should set calculation_int to default if the calculation_method is changed and calculation_int isn't set" do
      method_to_int = {
        "decaying_average" => { default: 65, testval: nil, altmeth: 'latest' },
        "n_mastery" => { default: 5, testval: nil, altmeth: 'highest' },
        "highest" => { default: nil, testval: 4, altmeth: 'n_mastery' },
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

    it "should destroy provided alignment" do
      @alignment = ContentTag.create({
        content: @outcome,
        context: @outcome.context,
        tag_type: 'learning_outcome'
      })
      @outcome.alignments << @alignment

      expect {
        @outcome.remove_alignment(@alignment.id, @outcome.context)
      }.to change {
        @outcome.alignments.count
      }.from(1).to(0)
    end

    it "returns points possible value set through rubric_criterion assessor" do
      @outcome.rubric_criterion[:points_possible] = 10
      expect(@outcome.rubric_criterion[:points_possible]).to eq 10
    end

    it "returns #data[:rubric_criterion] when #rubric_criterion is called" do
      @outcome.rubric_criterion = {
        description: "Thoughtful description",
        mastery_points: 5,
        ratings: [
          {
            description: "Strong work",
            points: 5
          },
          {
            description: "Weak sauce",
            points: 1
          }
        ],
      }
      mpoints = { mastery_points: 77 }
      expect(@outcome).to respond_to(:rubric_criterion)
      expect(@outcome.data).not_to be_nil
      expect(@outcome.rubric_criterion).to eq(@outcome.data[:rubric_criterion])
      expect {
        @outcome.rubric_criterion = @outcome.rubric_criterion.merge(mpoints)
      }.to change{@outcome.rubric_criterion}.to(@outcome.rubric_criterion.merge(mpoints))
    end

    it "should update aligned rubrics after save" do
      rubric = Rubric.create!(:context => @course)
      rubric.data = [
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
      rubric.save!

      @outcome.data[:rubric_criterion][:description] = 'New description'
      @outcome.save!

      rubric.reload
      expect(rubric.data.first[:ratings].map {|r| r[:description]}).to match_array([
        "Exceeds Expectations",
        "Meets Expectations",
        "Does Not Meet Expectations"
      ])
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
      expect(outcome_errors(:calculation_method).first).to include("calculation_method must be one of")

      @outcome = LearningOutcome.new(
        :title => 'outcome',
        :calculation_method => 'foo bar baz qux'
      )
      expect(@outcome).not_to be_valid
      expect(@outcome).to have(1).error
      expect(@outcome).to have(1).error_on(:calculation_method)
      expect(outcome_errors(:calculation_method).first).to include("calculation_method must be one of")
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
          invalid_value_error = 'not a valid value for this calculation method'
          unused_value_error = 'A calculation value is not used with this calculation method'

          it "should reject creation of a learning outcome with an illegal calculation_int for calculation_method of '#{method}'" do
            @outcome = @course.created_learning_outcomes.create(
              :title => 'outcome',
              :calculation_method => method,
              :calculation_int => '1500'
            )
            expect(@outcome).not_to be_valid
            expect(@outcome).to have(1).error
            expect(@outcome).to have(1).error_on(:calculation_int)
            if %w[highest latest].include?(method)
              expect(outcome_errors(:calculation_int).first).to include(unused_value_error)
            else
              expect(outcome_errors(:calculation_int).first).to include(invalid_value_error)
            end

            @outcome = LearningOutcome.new(
              :title => 'outcome',
              :calculation_method => method,
              :calculation_int => '1500'
            )
            expect(@outcome).not_to be_valid
            expect(@outcome).to have(1).error
            expect(@outcome).to have(1).error_on(:calculation_int)
            if %w[highest latest].include?(method)
              expect(outcome_errors(:calculation_int).first).to include(unused_value_error)
            else
              expect(outcome_errors(:calculation_int).first).to include(invalid_value_error)
            end
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
        @admin = double

        expect(Account.site_admin).to receive(:grants_right?).with(@admin, nil, :manage_global_outcomes).and_return(true)
        expect(@outcome.grants_right?(@admin, :update)).to be_truthy
        @outcome.clear_permissions_cache(@admin)

        expect(Account.site_admin).to receive(:grants_right?).with(@admin, nil, :manage_global_outcomes).and_return(false)
        expect(@outcome.grants_right?(@admin, :update)).to be_falsey
      end
    end

    context "non-global outcome" do
      before :once do
        course_factory(:active_course => 1)
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

      it "should not grant :update to users without :read_outcomes on the context" do
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
        expect(outcome_errors(:calculation_method).first).to include("calculation_method must be one of")
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
        expect(outcome_errors(:calculation_method).first).to include("calculation_method must be one of")
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
            if %w[highest latest].include? method
              expect(outcome_errors(:calculation_int).first).to include("A calculation value is not used with this calculation method")
            else
              expect(outcome_errors(:calculation_int).first).to include("not a valid value for this calculation method")
            end
            @outcome.reload
            expect(@outcome.calculation_method).to eq(method)
            expect(@outcome.calculation_int).to eq(int)
          end
        end
      end
    end

    context "default values" do
      it 'should default mastery points to 3' do
        @outcome = LearningOutcome.create!(:title => 'outcome')
        expect(@outcome.mastery_points).to be 3
      end

      it 'should default points possible to 5' do
        @outcome = LearningOutcome.create!(:title => 'outcome')
        expect(@outcome.points_possible).to be 5
      end

      it "should default calculation_method to decaying_average" do
        @outcome = LearningOutcome.create!(:title => 'outcome')
        expect(@outcome.calculation_method).to eql('decaying_average')
        expect(@outcome.calculation_int).to be 65
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
      it "should set calculation_method to decaying_average if the record is pre-existing and nil" do
        @outcome = LearningOutcome.create!(:title => 'outcome')
        @outcome.update_column(:calculation_method, nil)
        @outcome.reload
        expect(@outcome.calculation_method).to be_nil
        @outcome.description = "foo bar baz qux"
        @outcome.save!
        @outcome.reload
        expect(@outcome.description).to eq("foo bar baz qux")
        expect(@outcome.calculation_method).to eq('decaying_average')
      end
    end
  end

  context "root account ids" do
    let_once(:root_account) { account_model }
    let_once(:subaccount) { account_model parent_account: root_account }
    let_once(:course) { course_model account: subaccount }

    context 'sets root account ids on save' do
      it 'when context is account' do
        outcome = LearningOutcome.create! title:'outcome', context: subaccount
        expect(outcome.root_account_ids).to eq [root_account.id]
      end

      it 'when context is course' do
        outcome = LearningOutcome.create! title:'outcome', context: course
        expect(outcome.root_account_ids).to eq [root_account.id]
      end
    end

    it 'sets empty root account ids when context is nil' do
      outcome = LearningOutcome.create! title:'outcome', context: nil
      expect(outcome.root_account_ids).to eq []
    end

    it 'sets multiple root account ids based on associations' do
      second_root_account = account_model
      outcome = LearningOutcome.create! title: 'outcome'
      course.root_outcome_group.add_outcome(outcome)
      second_root_account.root_outcome_group.add_outcome(outcome)
      outcome.update! root_account_ids: nil
      expect(outcome.root_account_ids).to match_array [root_account.id, second_root_account.id]
      expect(outcome.global_root_account_ids).to match_array [root_account.global_id, second_root_account.global_id]
    end

    context 'add_root_account_id_for_context!' do
      it 'adds root account id for account' do
        outcome = LearningOutcome.create! title: 'outcome'
        outcome.add_root_account_id_for_context! subaccount
        expect(outcome.root_account_ids).to eq [root_account.id]
      end

      it 'adds root account id for course' do
        outcome = LearningOutcome.create! title: 'outcome'
        outcome.add_root_account_id_for_context! course
        expect(outcome.root_account_ids).to eq [root_account.id]
      end

      it 'does not add anything for outcome group' do
        outcome = LearningOutcome.create! title: 'outcome'
        outcome.add_root_account_id_for_context! LearningOutcomeGroup.global_root_outcome_group
        expect(outcome.root_account_ids).to eq []
      end

      it 'does not add anything when root accound id already present' do
        outcome = LearningOutcome.create! title: 'outcome', context: subaccount
        expect(outcome).not_to receive(:save)
        outcome.add_root_account_id_for_context! course
        expect(outcome.root_account_ids).to eq [root_account.id]
      end
    end
  end

  context "account level outcome" do
    let(:outcome) do
      LearningOutcome.create!(
        context: account.call,
        title: 'outcome',
        calculation_method: 'highest'
      )
    end

    let(:c1) { course_with_teacher; @course }
    let(:c2) { course_with_teacher; @course }

    let(:add_student) do
      ->(*courses) { courses.each { |c| student_in_course(course: c) } }
    end

    let(:account) { ->{ Account.all.find{|a| !a.site_admin? && a.root_account?} } }

    let(:create_rubric) do
      ->(outcome) do
        rubric = Rubric.create!(:context => outcome.context)
        rubric.data = [{
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
          :learning_outcome_id => outcome.id
        }]
        rubric.save!
        rubric
      end
    end

    let(:find_rubric) do
      ->(outcome) do
        # This is horribly inefficient, but there's not a good
        # way to query by learning outcome id because it's stored
        # in a serialized field :facepalm:.  When we do our outcomes
        # refactor we should get rid of the serialized field here also
        Rubric.all.each { |r| return r if r.data.first[:learning_outcome_id] == outcome.id }
        nil
      end
    end

    def add_or_get_rubric(outcome)
      @add_or_get_rubric_cache ||= Hash.new do |h, key|
        h[key] = find_rubric.call(outcome) || create_rubric.call(outcome)
      end
      @add_or_get_rubric_cache[outcome.id]
    end

    let(:assess_with) do
      ->(outcome, context) do
        assignment = assignment_model(context: context)
        rubric = add_or_get_rubric(outcome)
        user = user_factory(active_all: true)
        context.enroll_student(user)
        teacher = user_factory(active_all: true)
        context.enroll_teacher(teacher)
        a = rubric.associate_with(assignment, context, :purpose => 'grading')
        assignment.reload
        submission = assignment.grade_student(user, grade: "10", grader: teacher).first
        a.assess({
          :user => user,
          :assessor => user,
          :artifact => submission,
          :assessment => {
            :assessment_type => 'grading',
            :criterion_1 => {
              :points => 2,
              :comments => "cool, yo"
            }
          }
        })
        result = outcome.learning_outcome_results.first
        assessment = a.assess({
          :user => user,
          :assessor => user,
          :artifact => submission,
          :assessment => {
            :assessment_type => 'grading',
            :criterion_1 => {
              :points => 3,
              :comments => "cool, yo"
            }
          }
        })
        result.reload
        rubric.reload
        { assignment: assignment, assessment: assessment, rubric: rubric, result: result }
      end
    end

    context "learning outcome results" do
      before do
        add_student.call(c1, c2)
        add_or_get_rubric(outcome)
        [c1, c2].each { |c| outcome.align(nil, c, :mastery_type => "points") }
        @result = assess_with.call(outcome, c1)[:result]
      end

      it "properly reports whether assessed in a course" do
        expect(outcome).to be_assessed
        expect(outcome).to be_assessed(c1)
        expect(outcome).not_to be_assessed(c2)
      end

      it 'does not include deleted results when testing assessed' do
        @result.destroy
        expect(outcome).not_to be_assessed
        expect(outcome).not_to be_assessed(c1)
        expect(outcome).not_to be_assessed(c2)
      end
    end

    describe '#ensure_presence_in_context' do
      it 'adds active outcomes to a context if they are not present' do
        account = Account.default
        course_factory
        3.times do |i|
          LearningOutcome.create!(
            context: account,
            title: "outcome_#{i}",
            calculation_method: 'highest',
            workflow_state: i == 0 ? 'deleted' : 'active'
          )
        end
        outcome_ids = account.created_learning_outcomes.pluck(:id)
        LearningOutcome.ensure_presence_in_context(outcome_ids, @course)
        expect(@course.linked_learning_outcomes.count).to eq(2)
      end
    end

    it 'should de-dup outcomes linked multiple times' do
      account = Account.default
      course_factory
      lo = LearningOutcome.create!(context: @course, title: "outcome",
        calculation_method: 'highest', workflow_state: 'active')
      3.times do |i|
        group = @course.learning_outcome_groups.create!(:title => "groupage_#{i}")
        group.add_outcome(lo)
      end
      expect(@course.learning_outcome_links.count).to eq(3)
      expect(@course.linked_learning_outcomes.count).to eq(1) # not 3
    end

    describe '#align' do
      let(:assignment) { assignment_model }

      context 'context is course' do
        before do
          c1.root_outcome_group
        end

        it 'generates links to a learning outcome' do
          expect(c1.learning_outcome_links).to be_empty
          outcome.align(assignment, c1)
          c1.reload
          expect(c1.learning_outcome_links).not_to be_empty
        end

        it 'doesnt generates links when one exists' do
          expect(c1.learning_outcome_links).to be_empty
          outcome.align(assignment, c1)
          c1.reload
          expect(c1.learning_outcome_links.size).to eq 1

          outcome.align(assignment, c1)
          c1.reload
          expect(c1.learning_outcome_links.size).to eq 1
        end
      end

      context 'context is account' do
        it 'doesnt generate new links' do
          account1 = c1.account
          account1.root_outcome_group

          expect(account1.learning_outcome_links).to be_empty
          outcome.align(assignment, account1)
          account1.reload
          expect(account1.learning_outcome_links).to be_empty
        end
      end
    end
  end

  context 'propagate changes to aligned rubrics' do
    before :once do
      course_with_teacher(:active_course => true, :active_user => true)
    end

    it 'does not propagate on a new record' do
      lo = LearningOutcome.new
      lo.short_description = 'beta'
      expect(ContentTag).not_to receive(:learning_outcome_alignments)
      lo.save!
    end

    it 'does not propagate on assessed rubric' do
      assignment_model
      course_with_student_logged_in(:active_all => true)
      outcome_with_rubric mastery_points: 4.0
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
      @outcome.rubric_criterion = { mastery_points: 3.0 }
      @outcome.save!
      expect(@rubric.reload.criteria[0][:mastery_points]).to be 4.0
    end

    it 'propagates on data change' do
      outcome_with_rubric mastery_points: 4.0
      @outcome.rubric_criterion = { mastery_points: 3.0 }
      @outcome.save!
      expect(@rubric.reload.criteria[0][:mastery_points]).to be 3.0
    end

    it 'propagates on short description change' do
      outcome_with_rubric
      @outcome.short_description = 'beta'
      @outcome.save!
      expect(@rubric.reload.criteria[0][:description]).to eql 'beta'
    end

    it 'propagates on description change' do
      outcome_with_rubric
      @outcome.description = 'beta'
      @outcome.save!
      expect(@rubric.reload.criteria[0][:long_description]).to eql 'beta'
    end
  end

  context 'updateable rubrics' do
    before :once do
      course_with_teacher(:active_course => true, :active_user => true)
    end

    it 'returns unassessed rubric' do
      outcome_with_rubric
      expect(@outcome.updateable_rubrics.length).to eq 1
    end

    context 'one assessed assignment' do
      before do
        course_with_student_logged_in(:active_all => true)
        outcome_with_rubric
        a1 = assignment_model
        association = @rubric.associate_with(a1, @course, :purpose => 'grading', :use_for_grading => true)
        association.assess({
          :user => @student,
          :assessor => @teacher,
          :artifact => a1.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            :criterion_crit1 => {
              :points => 5
            }
          }
        })
      end

      it 'does not return assessed rubric' do
        expect(@outcome.updateable_rubrics.length).to eq 0
      end

      context 'plus one unassessed assignment' do
        before do
          a2 = assignment_model
          @rubric.associate_with(a2, @course, :purpose => 'grading', :use_for_grading => true)
        end

        it 'does not return assessed rubric' do
          expect(@outcome.updateable_rubrics.length).to eq 0
        end
      end
    end

    it 'does return course rubric referenced by single assignment' do
      outcome_with_rubric
      a1 = assignment_model
      a1.create_rubric_association(:rubric => @rubric,
                                   :purpose => 'grading',
                                   :use_for_grading => true,
                                   :context => @course)
      RubricAssociation.create!(
        :rubric => @rubric,
        :association_object => @course,
        :context => @course,
        :purpose => 'bookmark'
      )
      expect(@outcome.updateable_rubrics.length).to eq 1
    end

    it 'does not return rubric referenced by multiple assignments' do
      outcome_with_rubric
      a1 = assignment_model
      a2 = assignment_model
      a1.create_rubric_association(:rubric => @rubric,
                                   :purpose => 'grading',
                                   :use_for_grading => true,
                                   :context => @course)
      a2.create_rubric_association(:rubric => @rubric,
                                   :purpose => 'grading',
                                   :use_for_grading => true,
                                   :context => @course)
      expect(@outcome.updateable_rubrics.length).to eq 0
    end
  end
end
