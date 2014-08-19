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

describe AssignmentOverrideApplicator do
  def create_group_override
    @category = group_category
    @group = @category.groups.create!(context: @course)

    @assignment.group_category = @category
    @assignment.save!

    @override = assignment_override_model(:assignment => @assignment)
    @override.set = @group
    @override.save!

    @membership = @group.add_user(@student)
  end

  def create_assignment(*args)
    # need to make sure it doesn't invalidate the cache right away
    Timecop.freeze(5.seconds.ago) do
      assignment_model(*args)
    end
  end

  describe "assignment_overridden_for" do
    before :each do
      student_in_course
      @assignment = create_assignment(:course => @course)
    end

    it "should note the user id for whom overrides were applied" do
      @adhoc_override = assignment_override_model(:assignment => @assignment)
      @override_student = @adhoc_override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!
      @adhoc_override.override_due_at(7.days.from_now)
      @adhoc_override.save!
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
    end

    it "should note the user id for whom overrides were not found" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
    end

    it "should apply new overrides if an overridden assignment is overridden for a new user" do
      @student1 = @student
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student1)
      @overridden_assignment.overridden_for_user.id.should == @student1.id
      student_in_course
      @student2 = @student
      AssignmentOverrideApplicator.expects(:overrides_for_assignment_and_user).with(@overridden_assignment, @student2).returns([])
      @reoverridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@overridden_assignment, @student2)
    end

    it "should not attempt to apply overrides if an overridden assignment is overridden for the same user" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
      AssignmentOverrideApplicator.expects(:overrides_for_assignment_and_user).never
      @reoverridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@overridden_assignment, @student)
    end

    context "give teachers the more lenient of override.due_at or assignment.due_at" do
      before do
        teacher_in_course
        @section = @course.course_sections.create! :name => "Overridden Section"
        student_in_section(@section)
        @student = @user
      end

      def override_section(section, due)
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(due)
        override.save!
      end

      def setup_overridden_assignments(section_due_at, assignment_due_at)
        override_section(@section, section_due_at)
        @assignment.update_attribute(:due_at, assignment_due_at)

        @students_assignment = AssignmentOverrideApplicator.
          assignment_overridden_for(@assignment, @student)
        @teachers_assignment = AssignmentOverrideApplicator.
          assignment_overridden_for(@assignment, @teacher)
      end

      it "assignment.due_at is more lenient" do
        section_due_at = 5.days.ago
        assignment_due_at = nil
        setup_overridden_assignments(section_due_at, assignment_due_at)
        @teachers_assignment.due_at.to_i.should == assignment_due_at.to_i
        @students_assignment.due_at.to_i.should == section_due_at.to_i
      end

      it "override.due_at is more lenient" do
        section_due_at = 5.days.from_now
        assignment_due_at = 5.days.ago
        setup_overridden_assignments(section_due_at, assignment_due_at)
        @teachers_assignment.due_at.to_i.should == section_due_at.to_i
        @students_assignment.due_at.to_i.should == section_due_at.to_i
      end

      it "ignores assignment.due_at if all sections have overrides" do
        section_due_at = 5.days.from_now
        assignment_due_at = 1.year.from_now

        override_section(@course.default_section, section_due_at)
        setup_overridden_assignments(section_due_at, assignment_due_at)

        @teachers_assignment.due_at.to_i.should == section_due_at.to_i
        @students_assignment.due_at.to_i.should == section_due_at.to_i
      end
    end
  end

  describe "overrides_for_assignment_and_user" do
    before :each do
      student_in_course
      @assignment = create_assignment(:course => @course, :due_at => 5.days.from_now)
    end

    context 'it works' do
      it "should be serializable" do
        override = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
        lambda { Marshal.dump(override) }.should_not raise_error(TypeError)
      end

      it "should cache by assignment and user" do
        enable_cache do
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          Rails.cache.expects(:write_entry).never
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        end
      end

      it "should distinguish cache by assignment" do
        enable_cache do
          overrides1 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          assignment = create_assignment
          Rails.cache.expects(:write_entry)
          overrides2 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, @student)
        end
      end

      it "should distinguish cache by assignment version" do
        Timecop.travel Time.now + 1.hour do
          @assignment.due_at = 7.days.from_now
          @assignment.save!
          @assignment.versions.count.should == 2
          enable_cache do
            AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
            Rails.cache.expects(:write_entry)
            AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.current.model, @student)
          end
        end
      end

      it "should distinguish cache by user" do
        enable_cache do
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          user = user_model
          Rails.cache.expects(:write_entry)
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, user)
        end
      end

      it "should order adhoc override before group override" do
        @category = group_category
        @group = @category.groups.create!(:context => @course)
        @membership = @group.add_user(@student)
        @assignment.group_category = @category
        @assignment.save!

        @group_override = assignment_override_model(:assignment => @assignment)
        @group_override.set = @group
        @group_override.save!

        @adhoc_override = assignment_override_model(:assignment => @assignment)
        @override_student = @adhoc_override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.size.should == 2
        overrides.first.should == @adhoc_override
        overrides.last.should == @group_override
      end

      it "should order group override before section overrides" do
        @category = group_category
        @group = @category.groups.create!(:context => @course)
        @membership = @group.add_user(@student)
        @assignment.group_category = @category
        @assignment.save!

        @section_override = assignment_override_model(:assignment => @assignment)
        @section_override.set = @course.default_section
        @section_override.save!

        @group_override = assignment_override_model(:assignment => @assignment)
        @group_override.set = @group
        @group_override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.size.should == 2
        overrides.first.should == @group_override
        overrides.last.should == @section_override
      end

      it "should order section overrides by position" # see TODO in implementation
    end

    context 'adhoc overrides' do
      before :each do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
      end

      describe 'for students' do
        it "should include adhoc override for the user" do
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          overrides.should == [@override]
        end

        it "should not include adhoc overrides that don't include the user" do
          new_student = student_in_course
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, new_student.user)
          overrides.should be_empty
        end

        it "finds the overrides for the correct student" do
          result = AssignmentOverrideApplicator::adhoc_override(@assignment, @student)
          result.assignment_override_id.should == @override.id
        end

        it "returns AssignmentOverrideStudent" do
          result = AssignmentOverrideApplicator::adhoc_override(@assignment, @student)
          result.should be_an_instance_of(AssignmentOverrideStudent)
        end
      end

      describe 'for teachers' do
        it "works" do
          teacher_in_course
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @teacher)
          overrides.should == [@override]
        end
      end

      describe 'for observers' do
        it "works" do
          course_with_observer({:course => @course, :active_all => true})
          @course.enroll_user(@observer, "ObserverEnrollment", {:associated_user_id => @student.id})
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          overrides.should == [@override]
        end
      end

      describe 'for admins' do
        it "works" do
          account_admin_user
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          overrides.should == [@override]
        end
      end
    end

    context 'group overrides' do
      before :each do
        create_group_override
      end

      describe 'for students' do
        it 'returns group overrides' do
          result = AssignmentOverrideApplicator.group_override(@assignment, @student)
          result.should == @override
        end

        it "should not include group override for groups other than the user's" do
          @override.set = @category.groups.create!(context: @course)
          @override.save!
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          overrides.should be_empty
        end

        it "should not include group override for deleted groups" do
          @group.destroy
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          overrides.should be_empty
        end

        it "should not include group override for deleted group memberships" do
          @membership.destroy
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          overrides.should be_empty
        end
      end

      describe 'for teachers' do
        it 'works' do
          teacher_in_course
          result = AssignmentOverrideApplicator.group_override(@assignment, @teacher)
          result.should == @override
        end
      end

      describe 'for observers' do
        it 'works' do
          course_with_observer({:course => @course, :active_all => true})
          @course.enroll_user(@observer, "ObserverEnrollment", {:associated_user_id => @student.id})
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          overrides.should == [@override]
        end
      end

      describe 'for admins' do
        it 'works' do
          account_admin_user
          user_session(@admin)
          result = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          result.should == [@override]
        end
      end
    end

    context 'section overrides' do
      before :each do
        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @course.default_section
        @override.save!
        @section2 = @course.course_sections.create!(:name => "Summer session")
        @override2 = assignment_override_model(:assignment => @assignment)
        @override2.set_type = 'CourseSection'
        @override2.set_id = @section2.id
        @override2.due_at = 7.days.from_now
        @override2.save!
        @student2 = student_in_section(@section2, {:active_all => true})
      end

      describe 'for students' do
        it "returns section overrides" do
          result = AssignmentOverrideApplicator::section_overrides(@assignment, @student2)
          result.length.should == 1
        end

        it "should include section overrides for sections with an active student enrollment" do
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          overrides.should == [@override2]
        end

        it "should not include section overrides for sections with deleted enrollments" do
          @student2.student_enrollments.first.destroy
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          overrides.should be_empty
        end

        it "should include all relevant section overrides" do
          @course.enroll_student(@student, :section => @override2.set, :allow_multiple_enrollments => true)
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          overrides.size.should == 2
          overrides.should include(@override)
          overrides.should include(@override2)
        end

        it "should work even if :read_roster is disabled" do
          RoleOverride.create!(:context => @course.root_account, :permission => 'read_roster',
                               :enrollment_type => "StudentEnrollment", :enabled => false)
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          overrides.should == [@override2]
        end

        it "should only use the latest due_date for student_view_student" do
          due_at = 3.days.from_now
          a = create_assignment(:course => @course)
          cs1 = @course.course_sections.create!
          override1 = assignment_override_model(:assignment => a)
          override1.set = cs1
          override1.override_due_at(due_at)
          override1.save!

          cs2 = @course.course_sections.create!
          override2 = assignment_override_model(:assignment => a)
          override2.set = cs2
          override2.override_due_at(due_at - 1.day)
          override2.save!

          @fake_student = @course.student_view_student
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(a, @fake_student)
          overrides.should include(override1, override2)
          AssignmentOverrideApplicator.collapsed_overrides(a, overrides)[:due_at].to_i.should == due_at.to_i
        end

        it "should not include section overrides for sections without an enrollment" do
          assignment = create_assignment(:course => @course, :due_at => 5.days.from_now)
          override = assignment_override_model(:assignment => assignment)
          override.set = @course.course_sections.create!
          override.save!
          overrides = AssignmentOverrideApplicator.section_overrides(assignment, @student)
          overrides.should be_empty
        end
      end

      describe 'for teachers' do
        it 'works' do
          teacher_in_course
          result = AssignmentOverrideApplicator.section_overrides(@assignment, @teacher)
          result.should include(@override, @override2)
        end
      end

      describe 'for observers' do
        it 'works' do
          course_with_observer({:course => @course, :active_all => true})
          @course.enroll_user(@observer, "ObserverEnrollment", {:associated_user_id => @student2.id})
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          overrides.should == [@override2]
        end
      end

      describe 'for admins' do
        it 'works' do
          account_admin_user
          result = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          result.should include(@override, @override2)
        end
      end
    end

    context '#observer_overrides' do
      it "returns all dates visible to observer" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
        course_with_observer({:course => @course, :active_all => true})
        @course.enroll_user(@observer, "ObserverEnrollment", {:associated_user_id => @student.id})

        @section2 = @course.course_sections.create!(:name => "Summer session")
        @override2 = assignment_override_model(:assignment => @assignment)
        @override2.set_type = 'ADHOC'
        @override2.due_at = 7.days.from_now
        @override2.save!
        @override2_student = @override2.assignment_override_students.build
        @student2 = student_in_section(@section2, {:active_all => true})
        @override2_student.user = @student2
        @override2_student.save!
        @course.enroll_user(@observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student2.id})
        result = AssignmentOverrideApplicator::observer_overrides(@assignment, @observer)
        result.length.should == 2
      end
    end

    context '#has_invalid_args?' do
      it "returns true with nil user" do
        result = AssignmentOverrideApplicator::has_invalid_args?(@assignment, nil)
        result.should be_true
      end

      it "returns true for assignments with no overrides" do
        result = AssignmentOverrideApplicator::has_invalid_args?(@assignment, @student)
        result.should be_true
      end

      it "returns false if user and overrides are valid" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        result = AssignmentOverrideApplicator::has_invalid_args?(@assignment, @student)
        result.should be_false
      end
    end

    context "versioning" do
      it "should use the appropriate version of an override" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        original_override_version_number = @override.version_number

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.override_due_at(5.days.from_now)
        @override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.first.version_number.should == @override.version_number

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides.first.version_number.should == original_override_version_number
      end

      it "should use the most-recent override version for the given assignment version" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        first_version = @override.version_number

        @override.override_due_at(7.days.from_now)
        @override.save!

        second_version = @override.version_number
        first_version.should_not == second_version

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.first.version_number.should == second_version
      end

      it "should exclude overrides that weren't created until a later assignment version" do
        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides.should be_empty
      end

      it "should exclude overrides that were deleted as of the assignment version" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should include now-deleted overrides that weren't deleted yet as of the assignment version" do
        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @course.default_section
        @override.save!

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides.should == [@override]
        overrides.first.should_not be_deleted
      end

      it "should include now-deleted overrides that weren't deleted yet as of the assignment version (with manage_courses permission)" do
        account_admin_user

        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @course.default_section
        @override.save!

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @admin)
        overrides.should == [@override]
        overrides.first.should_not be_deleted
      end

      context "overrides for an assignment for a quiz, where the overrides were created before the quiz was published" do
        context "without draft states" do
          it "skips versions of the override that have nil for an assignment version" do
            student_in_course
            expected_time = Time.zone.now
            quiz = @course.quizzes.create! :title => "VDD Quiz", :quiz_type => 'assignment'
            section = @course.course_sections.create! :name => "title"
            @course.enroll_user(@student,
                                'StudentEnrollment',
                                :section => section,
                                :enrollment_state => 'active',
                                :allow_multiple_enrollments => true)
            override = quiz.assignment_overrides.build
            override.quiz_id = quiz.id
            override.quiz = quiz
            override.set_type = 'CourseSection'
            override.set_id = section.id
            override.title = "Quiz Assignment override"
            override.due_at = expected_time
            override.save!
            quiz.publish!
            override = quiz.reload.assignment.assignment_overrides.first
            override.versions.length.should == 2
            override.versions[0].model.assignment_version.should_not be_nil
            override.versions[1].model.assignment_version.should be_nil
            # Assert that it won't call the "<=" method on nil
            expect do
              overrides = AssignmentOverrideApplicator.
                overrides_for_assignment_and_user(quiz.assignment, @student)
            end.to_not raise_error
          end
        end

        context "with draft states" do
          it "quiz should always have an assignment for overrides" do
            # with draft states quizzes always have an assignment.
            student_in_course
            course.root_account.enable_feature!(:draft_state)
            expected_time = Time.zone.now
            quiz = @course.quizzes.create! :title => "VDD Quiz", :quiz_type => 'assignment'
            section = @course.course_sections.create! :name => "title"
            @course.enroll_user(@student,
                                'StudentEnrollment',
                                :section => section,
                                :enrollment_state => 'active',
                                :allow_multiple_enrollments => true)
            override = quiz.assignment_overrides.build
            override.quiz_id = quiz.id
            override.quiz = quiz
            override.set_type = 'CourseSection'
            override.set_id = section.id
            override.title = "Quiz Assignment override"
            override.due_at = expected_time
            override.save!
            quiz.publish!
            override = quiz.reload.assignment.assignment_overrides.first
            override.versions.length.should == 1
            override.versions[0].model.assignment_version.should_not be_nil
            # Assert that it won't call the "<=" method on nil
            expect do
              overrides = AssignmentOverrideApplicator.
                overrides_for_assignment_and_user(quiz.assignment, @student)
            end.to_not raise_error
            course.root_account.disable_feature!(:draft_state)
          end
        end
      end
    end
  end

  describe "assignment_with_overrides" do
    before :each do
      Time.zone == 'Alaska'
      @assignment = create_assignment(
        :due_at => 5.days.from_now,
        :unlock_at => 4.days.from_now,
        :lock_at => 6.days.from_now,
        :title => 'Some Title')
      @override = assignment_override_model(:assignment => @assignment)
      @override.override_due_at(7.days.from_now)
      @overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [@override])
    end

    it "should return a new assignment object" do
      @overridden.class.should == @assignment.class
      @overridden.object_id.should_not == @assignment.object_id
    end

    it "should preserve assignment id" do
      @overridden.id.should == @assignment.id
    end

    it "should be new_record? iff the original assignment is" do
      @overridden.should_not be_new_record

      @assignment = Assignment.new
      @overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [])
      @overridden.should be_new_record
    end

    it "should apply overrides to the returned assignment object" do
      @overridden.due_at.should == @override.due_at
    end

    it "should not change the original assignment object" do
      @assignment.due_at.should_not == @overridden.due_at
    end

    it "should inherit other values from the original assignment object" do
      @overridden.title.should == @assignment.title
    end

    it "should return a readonly assignment object" do
      @overridden.should be_readonly
      lambda{ @overridden.save! }.should raise_exception ActiveRecord::ReadOnlyRecord
    end

    it "should cast datetimes to the active time zone" do
      @overridden.due_at.time_zone.should == Time.zone
      @overridden.unlock_at.time_zone.should == Time.zone
      @overridden.lock_at.time_zone.should == Time.zone
    end

    it "should not cast dates to zoned datetimes" do
      @overridden.all_day_date.class.should == Date
    end

    it "should copy pre-loaded associations" do
      @overridden.association(:context).loaded?.should == @assignment.association(:context).loaded?
      @overridden.association(:rubric).loaded?.should == @assignment.association(:rubric).loaded?
      @overridden.learning_outcome_alignments.loaded? == @assignment.learning_outcome_alignments.loaded?
    end
  end

  describe "collapsed_overrides" do
    it "should cache by assignment and overrides" do
      @assignment = create_assignment
      @override = assignment_override_model(:assignment => @assignment)
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
        Rails.cache.expects(:write_entry).never
        overrides2 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
      end
    end

    it "should distinguish cache by assignment" do
      @assignment1 = create_assignment
      @assignment2 = create_assignment
      @override = assignment_override_model(:assignment => @assignment1)
      enable_cache do
        AssignmentOverrideApplicator.collapsed_overrides(@assignment1, [@override])
        Rails.cache.expects(:write_entry)
        AssignmentOverrideApplicator.collapsed_overrides(@assignment2, [@override])
      end
    end

    it "should distinguish cache by assignment updated_at" do
      @assignment = create_assignment
      Timecop.travel Time.now + 1.hour do
        @assignment.due_at = 5.days.from_now
        @assignment.save!
        @assignment.versions.count.should == 2
        @override = assignment_override_model(:assignment => @assignment)
        enable_cache do
          @assignment.versions.first.updated_at.should_not == @assignment.versions.current.model.updated_at
          AssignmentOverrideApplicator.collapsed_overrides(@assignment.versions.first.model, [@override])
          Rails.cache.expects(:write_entry)
          AssignmentOverrideApplicator.collapsed_overrides(@assignment.versions.current.model, [@override])
        end
      end
    end

    it "should distinguish cache by overrides" do
      @assignment = create_assignment
      @override1 = assignment_override_model(:assignment => @assignment)
      @override2 = assignment_override_model(:assignment => @assignment)
      enable_cache do
        AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override1])
        Rails.cache.expects(:write_entry)
        AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override2])
      end
    end

    it "should have a collapsed value for each recognized field" do
      @assignment = create_assignment
      @override = assignment_override_model(:assignment => @assignment)
      overrides = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
      overrides.class.should == Hash
      overrides.keys.to_set.should == [:due_at, :all_day, :all_day_date, :unlock_at, :lock_at].to_set
    end

    it "should use raw UTC time for datetime fields" do
      Time.zone = 'Alaska'
      @assignment = create_assignment(
        :due_at => 5.days.from_now,
        :unlock_at => 6.days.from_now,
        :lock_at => 7.days.from_now)
      collapsed = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [])
      collapsed[:due_at].class.should == Time; collapsed[:due_at].should == @assignment.due_at.utc
      collapsed[:unlock_at].class.should == Time; collapsed[:unlock_at].should == @assignment.unlock_at.utc
      collapsed[:lock_at].class.should == Time; collapsed[:lock_at].should == @assignment.lock_at.utc
    end

    it "should not use raw UTC time for date fields" do
      Time.zone = 'Alaska'
      @assignment = create_assignment(:due_at => 5.days.from_now)
      collapsed = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [])
      collapsed[:all_day_date].class.should == Date
      collapsed[:all_day_date].should == @assignment.all_day_date
    end
  end

  describe "overrides_hash" do
    it "should be consistent for the same overrides" do
      overrides = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash1.should == hash2
    end

    it "should be unique for different overrides" do
      overrides1 = 5.times.map{ assignment_override_model }
      overrides2 = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides1)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides2)
      hash1.should_not == hash2
    end

    it "should be unique for different versions of the same overrides" do
      overrides = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      overrides.first.override_due_at(5.days.from_now)
      overrides.first.save!
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash1.should_not == hash2
    end

    it "should be unique for different orders of the same overrides" do
      overrides = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides.reverse)
      hash1.should_not == hash2
    end
  end

  def fancy_midnight(opts={})
    zone = opts[:zone] || Time.zone
    Time.use_zone(zone) do
      time = opts[:time] || Time.zone.now
      time.in_time_zone.midnight + 1.day - 1.minute
    end
  end

  describe "overridden_due_at" do
    before :each do
      @assignment = create_assignment(:due_at => 5.days.from_now)
      @override = assignment_override_model(:assignment => @assignment)
    end

    it "should use overrides that override due_at" do
      @override.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @override.due_at
    end

    it "should skip overrides that don't override due_at" do
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      due_at.should == @override2.due_at
    end

    it "should prefer most lenient override" do
      @override.override_due_at(6.days.from_now)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      due_at.should == @override2.due_at
    end

    it "should consider no due date as most lenient" do
      @override.override_due_at(nil)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      due_at.should == @override.due_at
    end

    it "should not consider empty original due date as more lenient than an override due date" do
      @assignment.due_at = nil
      @override.override_due_at(6.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @override.due_at
    end

    it "prefers overrides even when earlier when determining most lenient due date" do
      earlier = 6.days.from_now
      @assignment.due_at = 7.days.from_now
      @override.override_due_at(earlier)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == earlier
    end

    it "should fallback on the assignment's due_at" do
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @assignment.due_at
    end

    it "should recognize overrides with overridden-but-nil due_at" do
      @override.override_due_at(nil)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @override.due_at
    end
  end

  # specs for overridden_due_at cover all_day and all_day_date, since they're
  # pulled from the same assignment/override the due_at is

  describe "overridden_unlock_at" do
    before :each do
      @assignment = create_assignment(:unlock_at => 10.days.from_now)
      @override = assignment_override_model(:assignment => @assignment)
    end

    it "should use overrides that override unlock_at" do
      @override.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @override.unlock_at
    end

    it "should skip overrides that don't override unlock_at" do
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      unlock_at.should == @override2.unlock_at
    end

    it "should prefer most lenient override" do
      @override.override_unlock_at(7.days.from_now)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_unlock_at(6.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      unlock_at.should == @override2.unlock_at
    end

    it "should consider no unlock date as most lenient" do
      @override.override_unlock_at(nil)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      unlock_at.should == @override.unlock_at
    end

    it "should not consider empty original unlock date as more lenient than an override unlock date" do
      @assignment.unlock_at = nil
      @override.override_unlock_at(6.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @override.unlock_at
    end

    it "prefers overrides even when later when determining most lenient unlock date" do
      later = 7.days.from_now
      @assignment.unlock_at = 6.days.from_now
      @override.override_unlock_at(later)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == later
    end

    it "should fallback on the assignment's unlock_at" do
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @assignment.unlock_at
    end

    it "should recognize overrides with overridden-but-nil unlock_at" do
      @override.override_unlock_at(nil)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @override.unlock_at
    end
  end

  describe "overridden_lock_at" do
    before :each do
      @assignment = create_assignment(:lock_at => 5.days.from_now)
      @override = assignment_override_model(:assignment => @assignment)
    end

    it "should use overrides that override lock_at" do
      @override.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @override.lock_at
    end

    it "should skip overrides that don't override lock_at" do
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      lock_at.should == @override2.lock_at
    end

    it "should prefer most lenient override" do
      @override.override_lock_at(6.days.from_now)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      lock_at.should == @override2.lock_at
    end

    it "should consider no lock date as most lenient" do
      @override.override_lock_at(nil)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      lock_at.should == @override.lock_at
    end

    it "should not consider empty original lock date as more lenient than an override lock date" do
      @assignment.lock_at = nil
      @override.override_lock_at(6.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @override.lock_at
    end

    it "prefers overrides even when earlier when determining most lenient lock date" do
      earlier = 6.days.from_now
      @assignment.lock_at = 7.days.from_now
      @override.override_lock_at(earlier)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == earlier
    end

    it "should fallback on the assignment's lock_at" do
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @assignment.lock_at
    end

    it "should recognize overrides with overridden-but-nil lock_at" do
      @override.override_lock_at(nil)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @override.lock_at
    end
  end

  describe "Overridable#has_no_overrides" do
    before do
      student_in_course
      @assignment = create_assignment(:course => @course,
                                     :due_at => 1.week.from_now)
      o = assignment_override_model(:assignment => @assignment,
                                    :due_at => 1.week.ago)
      o.assignment_override_students.create! user: @student
    end

    it "makes assignment_overridden_for lie!" do
      truly_overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)

      @assignment.has_no_overrides = true
      fake_overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      fake_overridden_assignment.overridden.should be_true
      fake_overridden_assignment.due_at.should_not == truly_overridden_assignment.due_at
      fake_overridden_assignment.due_at.should == @assignment.due_at
    end
  end

  describe "without_overrides" do
    before :each do
      student_in_course
      @assignment = create_assignment(:course => @course)
    end

    it "should return an unoverridden copy of an overridden assignment" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
      @unoverridden_assignment = @overridden_assignment.without_overrides
      @unoverridden_assignment.overridden_for_user.should == nil
    end
  end

  it "should use the full stack" do
    student_in_course
    original_due_at = 3.days.from_now
    @assignment = create_assignment(:course => @course)
    @assignment.due_at = original_due_at
    @assignment.save!
    @assignment.reload

    @section_override = assignment_override_model(:assignment => @assignment)
    @section_override.set = @course.default_section
    @section_override.override_due_at(5.days.from_now)
    @section_override.save!
    @section_override.reload

    @adhoc_override = assignment_override_model(:assignment => @assignment)
    @override_student = @adhoc_override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @adhoc_override.override_due_at(7.days.from_now)
    @adhoc_override.save!
    @adhoc_override.reload
    @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
    @overridden_assignment.due_at.should == @adhoc_override.due_at

    @adhoc_override.clear_due_at_override
    @adhoc_override.save!

    @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
    @overridden_assignment.due_at.should == @section_override.due_at
  end
end
