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

describe GradeCalculator do
  context "computing grades" do
    it "should compute grades without dying" do
      course_with_student
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment2 = @course.assignments.create!(:title => "Some Assignment2", :points_possible => 10, :assignment_group => @group)
      @submission = @assignment2.grade_student(@user, :grade => "5")
      @user.enrollments.first.computed_current_score.should eql(50.0)
      @user.enrollments.first.computed_final_score.should eql(25.0)
    end
    
    it "should recompute when an assignment's points_possible changes'" do
      course_with_student
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @submission = @assignment.grade_student(@user, :grade => "5")
      @user.enrollments.first.computed_current_score.should eql(50.0)
      @user.enrollments.first.computed_final_score.should eql(50.0)
      
      @assignment.points_possible = 5
      @assignment.save!
      
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(100.0)
    end
    
    it "should recompute when an assignment group's weight changes'" do
      course_with_student
      @course.group_weighting_scheme = "percent"
      @course.save
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 50)
      @group2 = @course.assignment_groups.create!(:name => "some group2", :group_weight => 50)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment.grade_student(@user, :grade => "10")
      @course.assignments.create! :points_possible => 1,
                                  :assignment_group => @group2
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(50.0)

      @group.group_weight = 60
      @group2.group_weight = 40
      @group.save!
      @group2.save!

      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(60.0)
    end

    def two_groups_two_assignments(g1_weight, a1_possible, g2_weight, a2_possible)
      course_with_student
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
        @user.enrollments.first.computed_current_score.should eql(nil)
        @user.enrollments.first.computed_final_score.should eql(0.0)
        @submission = @assignment.grade_student(@user, :grade => "5")
        @submission[0].score.should eql(5.0)
      end

      it "should ignore no grade for current grade calculation, even when weighted" do
        @course.group_weighting_scheme = "percent"
        @course.save!
        @user.reload
        @user.enrollments.first.computed_current_score.should eql(50.0)
        @user.enrollments.first.computed_final_score.should eql(25.0)
      end

      it "should ignore no grade for current grade but not final grade" do
        @user.reload
        @user.enrollments.first.computed_current_score.should eql(50.0)
        @user.enrollments.first.computed_final_score.should eql(25.0)
      end

      context "muted assignments" do
        before do
          @assignment2.mute!
        end

        it "should ignore muted assignments by default" do
          # should have same scores as previous spec despite having a grade
          @assignment2.grade_student(@user, :grade => "500")
          @user.reload
          @user.enrollments.first.computed_current_score.should eql(50.0)
          @user.enrollments.first.computed_final_score.should eql(25.0)
        end

        it "should ignore muted grade for current grade calculation, even when weighted" do
          # should have same scores as previous spec despite having a grade
          @assignment2.grade_student(@user, :grade => "500")
          @course.group_weighting_scheme = "percent"
          @course.save!
          @user.reload
          @user.enrollments.first.computed_current_score.should eql(50.0)
          @user.enrollments.first.computed_final_score.should eql(25.0)
        end

        it "should be possible to compute grades with muted assignments" do
          @assignment2.unmute!
          @assignment.mute!

          @course.update_attribute(:group_weighting_scheme, "percent")
          calc = GradeCalculator.new [@user.id],
                                     @course.id,
                                     :ignore_muted => false
          (current, _), (final, _) = calc.compute_scores.first
          current[:grade].should == 50
          final[:grade].should == 25
        end

        it "should be impossible to save grades that considered muted assignments" do
          @course.update_attribute(:group_weighting_scheme, "percent")
          calc = GradeCalculator.new [@user.id],
                                     @course.id,
                                     :ignore_muted => false
          lambda { calc.save_scores }.should raise_error
        end
      end
    end

    it "returns assignment group info" do
      two_groups_two_assignments(25, 10, 75, 10)
      @assignment.grade_student @user, grade: 5
      @assignment2.grade_student @user, grade: 10
      calc = GradeCalculator.new [@user.id], @course.id
      (_, current_group_info), (_, final_group_info) = calc.compute_scores.first
      current_group_info.should == final_group_info
      current_group_info[@group.id][:grade].should == 50
      current_group_info[@group2.id][:grade].should == 100
    end

    it "should compute a weighted grade when specified" do
      two_groups_two_assignments(50, 10, 50, 40)
      @user.enrollments.first.computed_current_score.should eql(nil)
      @user.enrollments.first.computed_final_score.should eql(0.0)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @user.enrollments.should_not be_empty
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @user.enrollments.first.computed_final_score.should eql(18.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @user.enrollments.first.computed_final_score.should eql(45.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(70.0)
      @user.enrollments.first.computed_final_score.should eql(70.0)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.0)
      @user.enrollments.first.computed_final_score.should eql(58.0)
    end
    
    it "should incorporate extra credit when the weighted total is more than 100%" do
      two_groups_two_assignments(50, 10, 60, 40)
      @user.enrollments.first.computed_current_score.should eql(nil)
      @user.enrollments.first.computed_final_score.should eql(0.0)
      @submission = @assignment.grade_student(@user, :grade => "10")
      @submission[0].score.should eql(10.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(20.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(50.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "40")
      @submission2[0].score.should eql(40.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(110.0)
      @user.enrollments.first.computed_final_score.should eql(110.0)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(100.0)
    end
    
    it "should incorporate extra credit when the total is more than the possible" do
      two_groups_two_assignments(50, 10, 60, 40)
      @user.enrollments.first.computed_current_score.should eql(nil)
      @user.enrollments.first.computed_final_score.should eql(0.0)
      @submission = @assignment.grade_student(@user, :grade => "11")
      @submission[0].score.should eql(11.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(110.0)
      @user.enrollments.first.computed_final_score.should eql(22.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(110.0)
      @user.enrollments.first.computed_final_score.should eql(55.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "45")
      @submission2[0].score.should eql(45.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(122.5)
      @user.enrollments.first.computed_final_score.should eql(122.5)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(112.0)
      @user.enrollments.first.computed_final_score.should eql(112.0)
    end
    
    it "should properly calculate the grade when total weight is less than 100%" do
      two_groups_two_assignments(50, 10, 40, 40)
      @submission = @assignment.grade_student(@user, :grade => "10")
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(55.6)
      
      @submission2 = @assignment2.grade_student(@user, :grade => "40")
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(100.0)
      @user.enrollments.first.computed_final_score.should eql(100.0)
    end

    it "should properly calculate the grade when there are 'not graded' assignments with scores" do
      course_with_student
      @group = @course.assignment_groups.create!(:name => "some group")
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => 10)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(:title => "Not graded assignment", :submission_types => 'not_graded')
      @assignment2.context = @course
      @assignment2.save!
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission2 = @assignment2.grade_student(@user, :grade => "1")
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @user.enrollments.first.computed_final_score.should eql(90.0)
    end
    
    def two_graded_assignments
      course_with_student
      @group = @course.assignment_groups.create!(:name => "some group")
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => 5)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(:title => "yet another", :points_possible => 5)
      @assignment2.context = @course
      @assignment2.save!
      @submission = @assignment.grade_student(@user, :grade => "2")
      @submission2 = @assignment2.grade_student(@user, :grade => "4")
      @course.save!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(60.0)
      @user.enrollments.first.computed_final_score.should eql(60.0)
    end
    
    it "should recalculate all cached grades when an assignment is deleted/restored" do
      two_graded_assignments
      @assignment2.destroy
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(40.0) # 2/5
      @user.enrollments.first.computed_final_score.should eql(40.0)
      
      @assignment2.restore
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(60.0)
      @user.enrollments.first.computed_final_score.should eql(60.0)
    end

    it "should recalculate all cached grades when an assignment is muted/unmuted" do
      two_graded_assignments
      @assignment2.mute!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(40.0) # 2/5
      @user.enrollments.first.computed_final_score.should eql(20.0) # 2/10

      @assignment2.unmute!
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(60.0)
      @user.enrollments.first.computed_final_score.should eql(60.0)
    end

    def nil_graded_assignment
      course_with_student
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

      @assignment_1.grade_student(@user, :grade => nil)
      @assignment_2.grade_student(@user, :grade => "1")
      @assignment2_1.grade_student(@user, :grade => "40")
    end

    it "should properly handle submissions with no score" do
      nil_graded_assignment

      @user.reload
      @user.enrollments.first.computed_current_score.should eql(93.2)
      @user.enrollments.first.computed_final_score.should eql(75.9)

      @course.group_weighting_scheme = "percent"
      @course.save!

      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.3)
      @user.enrollments.first.computed_final_score.should eql(48.4)
    end

    it "should treat muted assignments as if there is no submission" do
      # should have same scores as previous spec despite having a grade
      nil_graded_assignment

      @assignment_1.mute!
      @assignment_1.grade_student(@user, :grade => 500)
      
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(93.2)
      @user.enrollments.first.computed_final_score.should eql(75.9)

      @course.group_weighting_scheme = "percent"
      @course.save!

      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.3)
      @user.enrollments.first.computed_final_score.should eql(48.4)
    end

    context "draft state" do
      it "should not include unpublished assignments when draft state is enabled" do
        two_graded_assignments

        @course.account.enable_feature!(:draft_state)
        @assignment2.unpublish

        @user.reload
        @user.enrollments.first.computed_current_score.should eql(40.0)
        @user.enrollments.first.computed_final_score.should eql(40.0)
      end

      it "should include unpublished assignments when draft state is disabled" do
        two_graded_assignments

        @assignment2.unpublish

        @user.reload
        @user.enrollments.first.computed_current_score.should eql(60.0)
        @user.enrollments.first.computed_final_score.should eql(60.0)
      end
    end
  end

  it "should return grades in the order they are requested" do
    course_with_student
    @student1 = @student
    student_in_course
    @student2 = @student

    a = @course.assignments.create! :points_possible => 100
    a.grade_student @student1, :grade => 50
    a.grade_student @student2, :grade => 100

    calc = GradeCalculator.new([@student2.id, @student1.id], @course)
    grades = calc.compute_scores
    grades.shift.map { |g,_| g[:grade] }.should == [100, 100]
    grades.shift.map { |g,_| g[:grade] }.should == [50, 50]
  end

  it "returns point information for unweighted courses" do
    course_with_student
    a = @course.assignments.create! :points_possible => 50
    a.grade_student @student, :grade => 25
    calc = GradeCalculator.new([@student.id], @course)
    ((grade_info, _), _) = calc.compute_scores.first
    grade_info.should == {:grade => 50, :total => 25, :possible => 50}
  end

  # We should keep this in sync with GradeCalculatorSpec.coffee
  context "GradeCalculatorSpec.coffee examples" do
    before do
      course_with_student
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
        a.grade_student @student, :grade => score
      end
    end

    def check_grades(current, final)
      GradeCalculator.recompute_final_score(@student.id, @course.id)
      @enrollment.reload
      @enrollment.computed_current_score.should == current
      @enrollment.computed_final_score.should == final
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
      check_grades(56.0, 12.4)
    end

    it "should support drop_lowest" do
      set_default_grades
      @group.update_attribute(:rules, 'drop_lowest:1')
      check_grades(63.4, 56.0)

      @group.update_attribute(:rules, 'drop_lowest:2')
      check_grades(74.6, 63.4)
    end

    it "should really support drop_lowest" do
      set_grades [[30, nil], [30, nil], [30, nil], [31, 31], [21, 21],
                  [30, 30], [30, 30], [30, 30], [30, 30], [30, 30], [30, 30],
                  [30, 30], [30, 30], [30, 30], [30, 30], [29.3, 30], [30, 30],
                  [30, 30], [30, 30], [12, 0], [30, nil]]
      @group.update_attribute(:rules, 'drop_lowest:2')
      check_grades(132.1, 132.1)
    end

    it "should support drop_highest" do
      set_default_grades
      @group.update_attribute(:rules, 'drop_highest:1')
      check_grades(32.1, 5.0)

      @group.update_attribute(:rules, 'drop_highest:2')
      check_grades(18.3, 1.6)

      @group.update_attribute(:rules, 'drop_highest:3')
      check_grades(7.9, 0.3)
    end

    it "should really support drop_highest" do
      grades = [[0,10], [10,20], [28,50], [91,100]]
      set_grades(grades)

      @group.update_attribute(:rules, 'drop_highest:1')
      check_grades(47.5, 47.5)

      @group.update_attribute(:rules, 'drop_highest:2')
      check_grades(33.3, 33.3)

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
      check_grades(63.3, 56.0)

      Assignment.destroy_all
      Submission.destroy_all

      set_grades [[10,20], [5,10], [20,40], [0,100]]
      rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 0/100
      @group.update_attribute(:rules, rules)
      check_grades(18.8, 18.8)

      Assignment.destroy_all
      Submission.destroy_all

      set_grades [[10,20], [5,10], [20,40], [100,100]]
      rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 100/100
      @group.update_attribute(:rules, rules)
      check_grades(88.5, 88.5)

      Assignment.destroy_all
      Submission.destroy_all

      set_grades [[101.9,100], [105.65,100], [103.8,100], [0,0]]
      rules = "drop_lowest:1\nnever_drop:#{@assignments[2].id}" # 103.8/100
      @group.update_attribute(:rules, rules)
      check_grades(104.7, 104.7)
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
        grade = 76.7 # ((9/10)*50 + (5/10)*25) * (1/75)
        check_grades(grade, grade)
      end

      it "doesn't ignore them if the group_weighting_scheme is equal" do
        @course.update_attribute :group_weighting_scheme, 'equal'
        grade = 145.0 # ((9 + 5 + 10 + 5) / (10 + 10)) * 100
        check_grades(grade, grade)
      end
    end
  end
end
