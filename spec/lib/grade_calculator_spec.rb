#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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

describe GradeCalculator do
  before :once do
    course_with_student active_all: true
  end

  context "computing grades" do
    it "should compute grades without dying" do
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment2 = @course.assignments.create!(:title => "Some Assignment2", :points_possible => 10, :assignment_group => @group)
      @submission = @assignment2.grade_student(@user, grade: "5", grader: @teacher)
      expect(@user.enrollments.first.computed_current_score).to eql(50.0)
      expect(@user.enrollments.first.computed_final_score).to eql(25.0)
    end

    it "should recompute when an assignment's points_possible changes'" do
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @submission = @assignment.grade_student(@user, grade: "5", grader: @teacher)
      expect(@user.enrollments.first.computed_current_score).to eql(50.0)
      expect(@user.enrollments.first.computed_final_score).to eql(50.0)

      @assignment.points_possible = 5
      @assignment.save!

      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(100.0)
    end

    it "should recompute when an assignment group's weight changes'" do
      @course.group_weighting_scheme = "percent"
      @course.save
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 50)
      @group2 = @course.assignment_groups.create!(:name => "some group2", :group_weight => 50)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment.grade_student(@user, grade: "10", grader: @teacher)
      @course.assignments.create! :points_possible => 1,
                                  :assignment_group => @group2
      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(50.0)

      @group.group_weight = 60
      @group2.group_weight = 40
      @group.save!
      @group2.save!

      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(60.0)
    end

    it "recomputes when an assignment is flagged as omit from final grade" do
      @group = @course.assignment_groups.create!(name: "some group", group_weight: 100)
      assignment = @course.assignments.create!(
        title: "Some Assignment",
        points_possible: 10,
        assignment_group: @group
      )
      assignment2 = @course.assignments.create!(
        title: "Some Assignment2",
        points_possible: 10,
        assignment_group: @group,
        omit_from_final_grade: true
      )
      # grade first assignment for student
      assignment.grade_student(@user, grade: "5", grader: @teacher)

      # assert that at this point both current and final scores are 50%
      expect(@user.enrollments.first.computed_current_score).to eql(50.0)
      expect(@user.enrollments.first.computed_final_score).to eql(50.0)

      # grade second assignment for same student with a different score
      assignment2.grade_student(@user, grade: "10", grader: @teacher)

      # assert that current and final scores have not changed since second assignment
      # is flagged to be omitted from final grade
      expect(@user.enrollments.first.computed_current_score).to eql(50.0)
      expect(@user.enrollments.first.computed_final_score).to eql(50.0)
    end

    it "recomputes when an assignment changes assignment groups" do
      @course.update_attribute :group_weighting_scheme, "percent"
      ag1 = @course.assignment_groups.create! name: "Group 1", group_weight: 80
      ag2 = @course.assignment_groups.create! name: "Group 2", group_weight: 20
      a1 = ag1.assignments.create! points_possible: 10, name: "Assignment 1",
             context: @course
      a2 = ag2.assignments.create! points_possible: 10, name: "Assignment 2",
             context: @course

      a1.grade_student(@student, grade: 0, grader: @teacher)
      a2.grade_student(@student, grade: 10, grader: @teacher)

      enrollment = @student.enrollments.first

      expect(enrollment.computed_final_score).to eq 20

      a2.update_attributes assignment_group: ag1
      expect(enrollment.reload.computed_final_score).to eq 50
    end

    it "recomputes during #run_if_overrides_changed!" do
      a = @course.assignments.create! name: "Foo", points_possible: 10,
            context: @assignment
      a.grade_student(@student, grade: 10, grader: @teacher)

      e = @student.enrollments.first
      expect(e.computed_final_score).to eq 100

      Submission.update_all(score: 5, grade: 5)
      a.only_visible_to_overrides = true
      a.run_if_overrides_changed!
      expect(e.reload.computed_final_score).to eq 50
    end

    def two_groups_two_assignments(g1_weight, a1_possible, g2_weight, a2_possible)
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => g1_weight)
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => a1_possible)
      @assignment.context = @course
      @assignment.save!
      @group2 = @course.assignment_groups.create!(:name => "some other group", :group_weight => g2_weight)
      @assignment2 = @group2.assignments.build(:title => "some assignments", :points_possible => a2_possible)
      @assignment2.context = @course
      @assignment2.save!
    end

    describe "group with no grade or muted grade" do
      before(:each) do
        two_groups_two_assignments(50, 10, 50, 10)
        expect(@user.enrollments.first.computed_current_score).to eql(nil)
        expect(@user.enrollments.first.computed_final_score).to eql(0.0)
        @submission = @assignment.grade_student(@user, grade: "5", grader: @teacher)
        expect(@submission[0].score).to eql(5.0)
      end

      it "should ignore no grade for current grade calculation, even when weighted" do
        @course.group_weighting_scheme = "percent"
        @course.save!
        @user.reload
        expect(@user.enrollments.first.computed_current_score).to eql(50.0)
        expect(@user.enrollments.first.computed_final_score).to eql(25.0)
      end

      it "should ignore no grade for current grade but not final grade" do
        @user.reload
        expect(@user.enrollments.first.computed_current_score).to eql(50.0)
        expect(@user.enrollments.first.computed_final_score).to eql(25.0)
      end

      context "muted assignments" do
        before do
          @assignment2.mute!
        end

        it "should ignore muted assignments by default" do
          # should have same scores as previous spec despite having a grade
          @assignment2.grade_student(@user, grade: "500", grader: @teacher)
          @user.reload
          expect(@user.enrollments.first.computed_current_score).to eql(50.0)
          expect(@user.enrollments.first.computed_final_score).to eql(25.0)
        end

        it "should ignore muted grade for current grade calculation, even when weighted" do
          # should have same scores as previous spec despite having a grade
          @assignment2.grade_student(@user, grade: "500", grader: @teacher)
          @course.group_weighting_scheme = "percent"
          @course.save!
          @user.reload
          expect(@user.enrollments.first.computed_current_score).to eql(50.0)
          expect(@user.enrollments.first.computed_final_score).to eql(25.0)
        end

        it "should be possible to compute grades with muted assignments" do
          @assignment2.unmute!
          @assignment.mute!

          @course.update_attribute(:group_weighting_scheme, "percent")
          calc = GradeCalculator.new [@user.id],
                                     @course.id,
                                     :ignore_muted => false
          scores = calc.compute_scores.first
          expect(scores[:current][:grade]).to eq 50
          expect(scores[:final][:grade]).to eq 25
        end

        it "should be impossible to save grades that considered muted assignments" do
          @course.update_attribute(:group_weighting_scheme, "percent")
          calc = GradeCalculator.new [@user.id],
                                     @course.id,
                                     :ignore_muted => false
           # save_scores is a private method
          expect { calc.send(:save_scores) }.to raise_error("Can't save scores when ignore_muted is false")
        end
      end
    end

    it "returns assignment group info" do
      two_groups_two_assignments(25, 10, 75, 10)
      @assignment.grade_student @user, grade: 5, grader: @teacher
      @assignment2.grade_student @user, grade: 10, grader: @teacher
      calc = GradeCalculator.new [@user.id], @course.id

      computed_scores = calc.compute_scores.first
      current_groups  = computed_scores[:current_groups]
      final_groups    = computed_scores[:final_groups]

      expect(current_groups).to eq final_groups
      expect(current_groups[@group.id][:grade]).to eq 50
      expect(current_groups[@group2.id][:grade]).to eq 100
    end

    it "should compute a weighted grade when specified" do
      two_groups_two_assignments(50, 10, 50, 40)
      expect(@user.enrollments.first.computed_current_score).to eql(nil)
      expect(@user.enrollments.first.computed_final_score).to eql(0.0)
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      expect(@submission[0].score).to eql(9.0)
      expect(@user.enrollments).not_to be_empty
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(90.0)
      expect(@user.enrollments.first.computed_final_score).to eql(18.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(90.0)
      expect(@user.enrollments.first.computed_final_score).to eql(45.0)
      @submission2 = @assignment2.grade_student(@user, grade: "20", grader: @teacher)
      expect(@submission2[0].score).to eql(20.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(70.0)
      expect(@user.enrollments.first.computed_final_score).to eql(70.0)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(58.0)
      expect(@user.enrollments.first.computed_final_score).to eql(58.0)
    end

    it "should incorporate extra credit when the weighted total is more than 100%" do
      two_groups_two_assignments(50, 10, 60, 40)
      expect(@user.enrollments.first.computed_current_score).to eql(nil)
      expect(@user.enrollments.first.computed_final_score).to eql(0.0)
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher)
      expect(@submission[0].score).to eql(10.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(20.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(50.0)
      @submission2 = @assignment2.grade_student(@user, grade: "40", grader: @teacher)
      expect(@submission2[0].score).to eql(40.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(110.0)
      expect(@user.enrollments.first.computed_final_score).to eql(110.0)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(100.0)
    end

    it "should incorporate extra credit when the total is more than the possible" do
      two_groups_two_assignments(50, 10, 60, 40)
      expect(@user.enrollments.first.computed_current_score).to eql(nil)
      expect(@user.enrollments.first.computed_final_score).to eql(0.0)
      @submission = @assignment.grade_student(@user, grade: "11", grader: @teacher)
      expect(@submission[0].score).to eql(11.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(110.0)
      expect(@user.enrollments.first.computed_final_score).to eql(22.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(110.0)
      expect(@user.enrollments.first.computed_final_score).to eql(55.0)
      @submission2 = @assignment2.grade_student(@user, grade: "45", grader: @teacher)
      expect(@submission2[0].score).to eql(45.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(122.5)
      expect(@user.enrollments.first.computed_final_score).to eql(122.5)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(112.0)
      expect(@user.enrollments.first.computed_final_score).to eql(112.0)
    end

    it "should properly calculate the grade when total weight is less than 100%" do
      two_groups_two_assignments(50, 10, 40, 40)
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(55.56)

      @submission2 = @assignment2.grade_student(@user, grade: "40", grader: @teacher)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(100.0)
      expect(@user.enrollments.first.computed_final_score).to eql(100.0)
    end

    it "should properly calculate the grade when there are 'not graded' assignments with scores" do
      @group = @course.assignment_groups.create!(:name => "some group")
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => 10)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(:title => "Not graded assignment", :submission_types => 'not_graded')
      @assignment2.context = @course
      @assignment2.save!
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      @submission2 = @assignment2.grade_student(@user, grade: "1", grader: @teacher)
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(90.0)
      expect(@user.enrollments.first.computed_final_score).to eql(90.0)
    end

    def two_graded_assignments
      @group = @course.assignment_groups.create!(:name => "some group")
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => 5)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(:title => "yet another", :points_possible => 5)
      @assignment2.context = @course
      @assignment2.save!
      @submission = @assignment.grade_student(@user, grade: "2", grader: @teacher)
      @submission2 = @assignment2.grade_student(@user, grade: "4", grader: @teacher)
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(60.0)
      expect(@user.enrollments.first.computed_final_score).to eql(60.0)
    end

    it "should recalculate all cached grades when an assignment is deleted/restored" do
      two_graded_assignments
      @assignment2.destroy
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(40.0) # 2/5
      expect(@user.enrollments.first.computed_final_score).to eql(40.0)

      @assignment2.restore
      @assignment2.publish if @assignment2.unpublished?
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(60.0)
      expect(@user.enrollments.first.computed_final_score).to eql(60.0)
    end

    it "should recalculate all cached grades when an assignment is muted/unmuted" do
      two_graded_assignments
      @assignment2.mute!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(40.0) # 2/5
      expect(@user.enrollments.first.computed_final_score).to eql(20.0) # 2/10

      @assignment2.unmute!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(60.0)
      expect(@user.enrollments.first.computed_final_score).to eql(60.0)
    end

    def nil_graded_assignment
      @group = @course.assignment_groups.create!(:name => "group2", :group_weight => 50)
      @assignment_1 = @group.assignments.build(:title => "some assignments", :points_possible => 10)
      @assignment_1.context = @course
      @assignment_1.save!
      @assignment_2 = @group.assignments.build(:title => "some assignments", :points_possible => 4)
      @assignment_2.context = @course
      @assignment_2.save!
      @group2 = @course.assignment_groups.create!(:name => "assignments", :group_weight => 40)
      @assignment2_1 = @group2.assignments.build(:title => "some assignments", :points_possible => 40)
      @assignment2_1.context = @course
      @assignment2_1.save!

      @assignment_1.grade_student(@user, grade: nil, grader: @teacher)
      @assignment_2.grade_student(@user, grade: "1", grader: @teacher)
      @assignment2_1.grade_student(@user, grade: "40", grader: @teacher)
    end

    it "should properly handle submissions with no score" do
      nil_graded_assignment

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(93.18)
      expect(@user.enrollments.first.computed_final_score).to eql(75.93)

      @course.group_weighting_scheme = "percent"
      @course.save!

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(58.33)
      expect(@user.enrollments.first.computed_final_score).to eql(48.41)
    end

    it "should treat muted assignments as if there is no submission" do
      # should have same scores as previous spec despite having a grade
      nil_graded_assignment

      @assignment_1.mute!
      @assignment_1.grade_student(@user, grade: 500, grader: @teacher)

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(93.18)
      expect(@user.enrollments.first.computed_final_score).to eql(75.93)

      @course.group_weighting_scheme = "percent"
      @course.save!

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(58.33)
      expect(@user.enrollments.first.computed_final_score).to eql(48.41)
    end

    it "ignores pending_review submissions" do
      a1 = @course.assignments.create! name: "fake quiz", points_possible: 50
      a2 = @course.assignments.create! name: "assignment", points_possible: 50

      s1 = a1.grade_student(@student, grade: 25, grader: @teacher).first
      Submission.where(:id => s1.id).update_all(workflow_state: "pending_review")

      a2.grade_student(@student, grade: 50, grader: @teacher)

      enrollment = @student.enrollments.first.reload
      expect(enrollment.computed_current_score).to eq 100.0
      expect(enrollment.computed_final_score).to eq 75.0
    end

    it "should not include unpublished assignments" do
      two_graded_assignments
      @assignment2.unpublish

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to eql(40.0)
      expect(@user.enrollments.first.computed_final_score).to eql(40.0)
    end
  end

  describe '#compute_and_save_scores' do
    before(:once) do
      @first_period, @second_period = grading_periods(count: 2)
      first_assignment = @course.assignments.create!(
        due_at: 1.day.from_now(@first_period.start_date),
        points_possible: 100
      )
      second_assignment = @course.assignments.create!(
        due_at: 1.day.from_now(@second_period.start_date),
        points_possible: 100
      )
      first_assignment.grade_student(@student, grade: 25, grader: @teacher)
      second_assignment.grade_student(@student, grade: 75, grader: @teacher)
      # update_column to avoid callbacks on submission that would trigger score updates
      Submission.where(user: @student, assignment: first_assignment).first.update_column(:score, 100.0)
      Submission.where(user: @student, assignment: second_assignment).first.update_column(:score, 95.0)
    end

    let(:scores) { @student.enrollments.first.scores }
    let(:overall_course_score) { scores.where(grading_period_id: nil).first }

    it 'updates the overall course score' do
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
      expect(overall_course_score.current_score).to eq(97.5)
    end

    it 'updates all grading period scores' do
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
      grading_period_scores = scores.where.not(grading_period_id: nil).order(:current_score).pluck(:current_score)
      expect(grading_period_scores).to match_array([100.0, 95.0])
    end

    it 'does not update grading period scores if update_all_grading_period_scores is false' do
      GradeCalculator.new(@student.id, @course, update_all_grading_period_scores: false).compute_and_save_scores
      grading_period_scores = scores.where.not(grading_period_id: nil).order(:current_score).pluck(:current_score)
      expect(grading_period_scores).to match_array([25.0, 75.0])
    end

    context 'grading period is provided' do
      it 'updates the grading period score' do
        GradeCalculator.new(@student.id, @course, grading_period: @first_period).compute_and_save_scores
        score = scores.where(grading_period_id: @first_period).first
        expect(score.current_score).to eq(100.0)
      end

      it 'updates the overall course score' do
        GradeCalculator.new(@student.id, @course, grading_period: @first_period).compute_and_save_scores
        expect(overall_course_score.current_score).to eq(97.5)
      end

      it 'does not update scores for other grading periods' do
        GradeCalculator.new(@student.id, @course, grading_period: @first_period).compute_and_save_scores
        score = scores.where(grading_period_id: @second_period).first
        expect(score.current_score).to eq(75.0)
      end

      it 'does not update the overall course score if update_course_score is false' do
        GradeCalculator.new(
          @student.id, @course, grading_period: @first_period, update_course_score: false
        ).compute_and_save_scores
        expect(overall_course_score.current_score).to eq(50.0)
      end
    end
  end

  it "should return grades in the order they are requested" do
    @student1 = @student
    student_in_course
    @student2 = @student

    a = @course.assignments.create! :points_possible => 100
    a.grade_student @student1, grade: 50, grader: @teacher
    a.grade_student @student2, grade: 100, grader: @teacher

    calc = GradeCalculator.new([@student2.id, @student1.id], @course)
    grades = calc.compute_scores

    expect(grades.first[:current][:grade]).to eq 100
    expect(grades.first[:final][:grade]).to eq 100
    expect(grades.last[:current][:grade]).to eq 50
    expect(grades.last[:final][:grade]).to eq 50
  end

  it "returns point information for unweighted courses" do
    a = @course.assignments.create! :points_possible => 50
    a.grade_student @student, grade: 25, grader: @teacher
    calc = GradeCalculator.new([@student.id], @course)
    grade_info = calc.compute_scores.first[:current]
    expect(grade_info).to eq({:grade => 50, :total => 25, :possible => 50})
  end

  # We should keep this in sync with GradeCalculatorSpec.coffee
  context "GradeCalculatorSpec.coffee examples" do
    before do
      @group = @group1 = @course.assignment_groups.create!(:name => 'group 1')
    end

    def set_default_grades
      set_grades [[100,100], [42,91], [14,55], [3,38], [nil,1000]]
    end

    def set_grades(grades, group=@group1)
      @grades = grades
      @assignments = @grades.map do |score,possible|
        @course.assignments.create! :title => 'homework',
                                    :points_possible => possible,
                                    :assignment_group => group
      end
      @assignments.each_with_index do |a,i|
        score = @grades[i].first
        next unless score # don't grade nil submissions
        a.grade_student @student, grade: score, grader: @teacher
      end
    end

    def check_grades(current, final)
      GradeCalculator.recompute_final_score(@student.id, @course.id)
      @enrollment.reload
      expect(@enrollment.computed_current_score).to eq current
      expect(@enrollment.computed_final_score).to eq final
    end

    it "should work without assignments or submissions" do
      @group.assignments.clear
      check_grades(nil, nil)
    end

    it "should work without submissions" do
      @course.assignments.create! :title => 'asdf',
                                  :points_possible => 1,
                                  :assignment_group => @group
      check_grades(nil, 0)
    end

    it "should work with submissions that have 0 points possible" do
      set_grades [[10,0], [10,10], [10, 10], [nil,10]]
      check_grades(150.0, 100.0)

      @group.update_attribute(:rules, 'drop_lowest:1')
      check_grades(200.0, 150.0)
    end

    it 'should "work" when no submissions have points possible' do
      set_grades [[10,0], [5,0], [20,0], [0,0]]
      @group.update_attribute(:rules, 'drop_lowest:1')
      check_grades(nil, nil)
    end

    it "should work with no drop rules" do
      set_default_grades
      check_grades(55.99, 12.38)
    end

    it "should support drop_lowest" do
      set_default_grades
      @group.update_attribute(:rules, 'drop_lowest:1')
      check_grades(63.41, 55.99)

      @group.update_attribute(:rules, 'drop_lowest:2')
      check_grades(74.64, 63.41)
    end

    it "should really support drop_lowest" do
      set_grades [[30, nil], [30, nil], [30, nil], [31, 31], [21, 21],
                  [30, 30], [30, 30], [30, 30], [30, 30], [30, 30], [30, 30],
                  [30, 30], [30, 30], [30, 30], [30, 30], [29.3, 30], [30, 30],
                  [30, 30], [30, 30], [12, 0], [30, nil]]
      @group.update_attribute(:rules, 'drop_lowest:2')
      check_grades(132.12, 132.12)
    end

    it "should support drop_highest" do
      set_default_grades
      @group.update_attribute(:rules, 'drop_highest:1')
      check_grades(32.07, 4.98)

      @group.update_attribute(:rules, 'drop_highest:2')
      check_grades(18.28, 1.56)

      @group.update_attribute(:rules, 'drop_highest:3')
      check_grades(7.89, 0.29)
    end

    it "should really support drop_highest" do
      grades = [[0,10], [10,20], [28,50], [91,100]]
      set_grades(grades)

      @group.update_attribute(:rules, 'drop_highest:1')
      check_grades(47.5, 47.5)

      @group.update_attribute(:rules, 'drop_highest:2')
      check_grades(33.33, 33.33)

      @group.update_attribute(:rules, 'drop_highest:3')
      check_grades(0, 0)
    end

    it "should work with unreasonable drop rules" do
      set_grades([[10,10],[9,10],[8,10]])
      @group.update_attribute :rules, "drop_lowest:1000\ndrop_highest:1000"
      check_grades(100, 100)
    end

    it "should support never_drop" do
      set_default_grades
      rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 3/38
      @group.update_attribute(:rules, rules)
      check_grades(63.32, 55.99)

      Assignment.destroy_all
      Submission.destroy_all

      set_grades [[10,20], [5,10], [20,40], [0,100]]
      rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 0/100
      @group.update_attribute(:rules, rules)
      check_grades(18.75, 18.75)

      Assignment.destroy_all
      Submission.destroy_all

      set_grades [[10,20], [5,10], [20,40], [100,100]]
      rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 100/100
      @group.update_attribute(:rules, rules)
      check_grades(88.46, 88.46)

      Assignment.destroy_all
      Submission.destroy_all

      set_grades [[101.9,100], [105.65,100], [103.8,100], [0,0]]
      rules = "drop_lowest:1\nnever_drop:#{@assignments[2].id}" # 103.8/100
      @group.update_attribute(:rules, rules)
      check_grades(104.73, 104.73)
    end

    it "grade dropping should work even in ridiculous circumstances" do
      set_grades [[nil, 20], [3, 10], [nil, 10],
                  [nil, 100000000000000007629769841091887003294964970946560],
                  [nil, nil]]

      @group.update_attribute(:rules, 'drop_lowest:2')
      check_grades(30, 15)
    end

    context "assignment groups with 0 points possible" do
      before do
        @group1.update_attribute :group_weight, 50
        @group2 = @course.assignment_groups.create! :name => 'group 2',
                                                    :group_weight => 25
        @group3 = @course.assignment_groups.create! :name => 'empty group',
                                                    :group_weight => 25
        @group4 = @course.assignment_groups.create! :name => 'extra credit',
                                                    :group_weight => 10

        set_grades [[9, 10]], @group1
        set_grades [[5, 10]], @group2
        # @group3 is emtpy
        set_grades [[10, 0], [5, 0]], @group3
      end

      it "ignores them if the group_weighting_scheme is percent" do
        # NOTE: in addition to ignoring invalid assignment groups, we also
        # have to scale up the valid ones
        @course.update_attribute :group_weighting_scheme, 'percent'
        grade = 76.67 # ((9/10)*50 + (5/10)*25) * (1/75)
        check_grades(grade, grade)
      end

      it "doesn't ignore them if the group_weighting_scheme is equal" do
        @course.update_attribute :group_weighting_scheme, 'equal'
        grade = 145.0 # ((9 + 5 + 10 + 5) / (10 + 10)) * 100
        check_grades(grade, grade)
      end
    end

    context "grading periods" do
      before :once do
        student_in_course active_all: true
        @gp1, @gp2 = grading_periods count: 2
        @a1, @a2 = [@gp1, @gp2].map { |gp|
          @course.assignments.create! due_at: gp.start_date + 1,
            points_possible: 100
        }
        @a1.grade_student(@student, grade: 25, grader: @teacher)
        @a2.grade_student(@student, grade: 75, grader: @teacher)
      end

      it "can compute grades for a grading period" do
        gc = GradeCalculator.new([@student.id], @course, grading_period: @gp1)
        current = gc.compute_scores.first[:current]
        expect(current[:grade]).to eql 25.0

        gc = GradeCalculator.new([@student.id], @course, grading_period: @gp2)
        current = gc.compute_scores.first[:current]
        expect(current[:grade]).to eql 75.0
      end
    end

    context "differentiated assignments grade calculation" do
      def set_up_course_for_differentiated_assignments
          set_grades [[5, 20], [15, 20], [10,20], [nil, 20], [20, 20], [10,20], [nil, 20]]
          @assignments.each do |a|
            a.only_visible_to_overrides = true
            a.save!
          end
          @overridden_lowest = @assignments[0]
          @overridden_highest = @assignments[1]
          @overridden_middle = @assignments[2]
          @non_overridden_lowest = @assignments[3]
          @non_overridden_highest = @assignments[4]
          @non_overridden_middle = @assignments[5]
          @not_graded = @assignments.last

          @user.enrollments.each(&:destroy)
          @section = @course.course_sections.create!(name: "test section")
          student_in_section(@section, user: @user)

          create_section_override_for_assignment(@overridden_lowest, course_section: @section)
          create_section_override_for_assignment(@overridden_highest, course_section: @section)
          create_section_override_for_assignment(@overridden_middle, course_section: @section)
      end

      def final_grade_info(user, course)
        GradeCalculator.new([user.id], course.id).compute_scores.first[:final]
      end

      context "DA" do
        before do
          set_up_course_for_differentiated_assignments
        end
        it "should calculate scores based on visible assignments only" do
          # 5 + 15 + 10 + 20 + 10
          expect(final_grade_info(@user, @course)[:total]).to eq 60
          expect(final_grade_info(@user, @course)[:possible]).to eq 100
        end
        it "should drop the lowest visible when that rule is in place" do
          @group.update_attribute(:rules, 'drop_lowest:1')
          # 5 + 15 + 10 + 20 + 10 - 5
          expect(final_grade_info(@user, @course)[:total]).to eq 55
          expect(final_grade_info(@user, @course)[:possible]).to eq 80
        end
        it "should drop the highest visible when that rule is in place" do
          @group.update_attribute(:rules, 'drop_highest:1')
          # 5 + 15 + 10 + 20 + 10 - 20
          expect(final_grade_info(@user, @course)[:total]).to eq 40
          expect(final_grade_info(@user, @course)[:possible]).to eq 80
        end
        it "should not count an invisible assignment with never drop on" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          # 5 + 15 + 10 + 20 + 10 - 10 - 10
          expect(final_grade_info(@user, @course)[:total]).to eq 40
          expect(final_grade_info(@user, @course)[:possible]).to eq 60
        end
      end
    end

    context "excused assignments" do
      before :once  do
        student_in_course(active_all: true)
        @a1 = @course.assignments.create! points_possible: 10
        @a2 = @course.assignments.create! points_possible: 90
      end

      it "works" do
        enrollment = @student.enrollments.first
        @a1.grade_student(@student, grade: 10, grader: @teacher)
        expect(enrollment.reload.computed_final_score).to eql(10.0)

        @a2.grade_student(@student, excuse: 1, grader: @teacher)
        expect(enrollment.reload.computed_final_score).to eql(100.0)
      end
    end
  end
end
