#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe Enrollment do
  before(:each) do
    @user = User.create!
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
  end

  it "should be valid" do
    @enrollment.should be_valid
  end

  it "should have an interesting state machine" do
    enrollment_model
    @user.stubs(:dashboard_messages).returns(Message.none)
    @enrollment.state.should eql(:invited)
    @enrollment.accept
    @enrollment.state.should eql(:active)
    @enrollment.reject
    @enrollment.state.should eql(:rejected)
    @enrollment.destroy!
    enrollment_model
    @enrollment.complete
    @enrollment.state.should eql(:completed)
    @enrollment.destroy!
    enrollment_model
    @enrollment.reject
    @enrollment.state.should eql(:rejected)
    @enrollment.destroy!
    enrollment_model
    @enrollment.accept
    @enrollment.state.should eql(:active)
  end

  it "should be pending if it is invited or creation_pending" do
    enrollment_model(:workflow_state => 'invited')
    @enrollment.should be_pending
    @enrollment.destroy!

    enrollment_model(:workflow_state => 'creation_pending')
    @enrollment.should be_pending
  end

  it "should have a context_id as the course_id" do
    @enrollment.course.id.should_not be_nil
    @enrollment.context_id.should eql(@enrollment.course.id)
  end

  it "should have a readable_type of Teacher for a TeacherEnrollment" do
    e = TeacherEnrollment.new
    e.type = 'TeacherEnrollment'
    e.readable_type.should eql('Teacher')
  end

  it "should have a readable_type of Student for a StudentEnrollment" do
    e = StudentEnrollment.new
    e.type = 'StudentEnrollment'
    e.readable_type.should eql('Student')
  end

  it "should have a readable_type of TaEnrollment for a TA" do
    e = TaEnrollment.new(valid_enrollment_attributes)
    e.type = 'TaEnrollment'
    e.readable_type.should eql('TA')
  end

  it "should have a defalt readable_type of Student" do
    e = Enrollment.new
    e.type = 'Other'
    e.readable_type.should eql('Student')
  end

  describe "sis_role" do
    it "should return role_name if present" do
      e = TaEnrollment.new
      e.role_name = 'Assistant Grader'
      e.sis_role.should == 'Assistant Grader'
    end

    it "should return the sis enrollment type otherwise" do
      e = TaEnrollment.new
      e.sis_role.should == 'ta'
    end
  end

  it "should not allow an associated_user_id on a non-observer enrollment" do
    observed = User.create!

    @enrollment.type = 'ObserverEnrollment'
    @enrollment.associated_user_id = observed.id
    @enrollment.should be_valid

    @enrollment.type = 'StudentEnrollment'
    @enrollment.should_not be_valid

    @enrollment.associated_user_id = nil
    @enrollment.should be_valid
  end

  it "should not allow read permission on a course if date inactive" do
    course_with_student(:active_all => true)
    @enrollment.start_at = 2.days.from_now
    @enrollment.end_at = 4.days.from_now
    @enrollment.workflow_state = 'active'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, :read).should eql(false)
    # post to forum comes from role_override; inactive enrollments should not
    # get any permissions form role_override
    @course.grants_right?(@enrollment.user, :post_to_forum).should eql(false)
  end

  it "should not allow read permission on a course if explicitly inactive" do
    course_with_student(:active_all => true)
    @enrollment.workflow_state = 'inactive'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, :read).should eql(false)
    @course.grants_right?(@enrollment.user, :post_to_forum).should eql(false)
  end

  it "should allow read, but not post_to_forum on a course if date completed" do
    course_with_student(:active_all => true)
    @enrollment.start_at = 4.days.ago
    @enrollment.end_at = 2.days.ago
    @enrollment.workflow_state = 'active'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, :read).should eql(true)
    # post to forum comes from role_override; completed enrollments should not
    # get any permissions form role_override
    @course.grants_right?(@enrollment.user, :post_to_forum).should eql(false)
  end

  it "should allow read, but not post_to_forum on a course if explicitly completed" do
    course_with_student(:active_all => true)
    @enrollment.workflow_state = 'completed'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, :read).should eql(true)
    @course.grants_right?(@enrollment.user, :post_to_forum).should eql(false)
  end

  context "typed_enrollment" do
    it "should allow StudentEnrollment" do
      Enrollment.typed_enrollment('StudentEnrollment').should eql(StudentEnrollment)
    end
    it "should allow TeacherEnrollment" do
      Enrollment.typed_enrollment('TeacherEnrollment').should eql(TeacherEnrollment)
    end
    it "should allow TaEnrollment" do
      Enrollment.typed_enrollment('TaEnrollment').should eql(TaEnrollment)
    end
    it "should allow ObserverEnrollment" do
      Enrollment.typed_enrollment('ObserverEnrollment').should eql(ObserverEnrollment)
    end
    it "should allow DesignerEnrollment" do
      Enrollment.typed_enrollment('DesignerEnrollment').should eql(DesignerEnrollment)
    end
    it "should allow not NothingEnrollment" do
      Enrollment.typed_enrollment('NothingEnrollment').should eql(nil)
    end
  end

  context "drop scores" do
    before(:each) do
      course_with_student
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 50, :rules => "drop_lowest:1")
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => 10)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(:title => "some assignment 2", :points_possible => 40)
      @assignment2.context = @course
      @assignment2.save!
    end

    it "should drop high scores for groups when specified" do
      @enrollment = @user.enrollments.first
      @group.update_attribute(:rules, "drop_highest:1")
      @enrollment.reload.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @enrollment.reload.computed_current_score.should eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @enrollment.reload.computed_current_score.should eql(50.0)
      @group.update_attribute(:rules, nil)
      @enrollment.reload.computed_current_score.should eql(58.0)
    end

    it "should drop low scores for groups when specified" do
      @enrollment = @user.enrollments.first
      @enrollment.reload.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @enrollment.reload.computed_current_score.should eql(90.0)
      @group.update_attribute(:rules, "")
      @enrollment.reload.computed_current_score.should eql(58.0)
    end

    it "should not drop the last score for a group, even if the settings say it should be dropped" do
      @enrollment = @user.enrollments.first
      @group.update_attribute(:rules, "drop_lowest:2")
      @enrollment.reload.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @enrollment.reload.computed_current_score.should eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @enrollment.reload.computed_current_score.should eql(90.0)
    end
  end

  context "notifications" do
    it "should send out invitations if the course is already published" do
      Notification.create!(:name => "Enrollment Registration")
      course_with_teacher(:active_all => true)
      user_with_pseudonym
      e = @course.enroll_student(@user)
      e.messages_sent.should be_include("Enrollment Registration")
    end

    it "should not send out invitations if the course is not yet published" do
      Notification.create!(:name => "Enrollment Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      e.messages_sent.should_not be_include("Enrollment Registration")
    end

    it "should send out invitations for previously-created enrollments when the course is published" do
      n = Notification.create(:name => "Enrollment Registration", :category => "Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      e.messages_sent.should_not be_include("Enrollment Registration")
      @user.pseudonym.should_not be_nil
      @course.offer
      e.reload
      e.should be_invited
      e.user.should_not be_nil
      e.user.pseudonym.should_not be_nil
      Message.last.should_not be_nil
      Message.last.notification.should eql(n)
      Message.last.to.should eql(@user.email)
    end
  end

  context "atom" do
    it "should use the course and user name to derive a title" do
      @enrollment.to_atom.title.should eql("#{@enrollment.user.name} in #{@enrollment.course.name}")
    end

    it "should link to the enrollment" do
      link_path = @enrollment.to_atom.links.first.to_s
      link_path.should eql("/courses/#{@enrollment.course.id}/enrollments/#{@enrollment.id}")
    end
  end

  context "permissions" do
    it "should be able to read grades if the course grants management rights to the enrollment" do
      @new_user = user_model
      @enrollment.grants_rights?(@new_user, :read_grades)[:read_grades].should be_false
      @course.enroll_teacher(@new_user)
      @enrollment.grants_rights?(@user, :read_grades).should be_true
    end

    it "should allow the user itself to read its own grades" do
      @enrollment.grants_rights?(@user, :read_grades).should be_true
    end
  end

  context "recompute_final_score_if_stale" do
    it "should only call recompute_final_score once within the cache window" do
      course_with_student
      Enrollment.expects(:recompute_final_score).once
      enable_cache do
        Enrollment.recompute_final_score_if_stale @course
        Enrollment.recompute_final_score_if_stale @course
      end
    end

    it "should yield iff it calls recompute_final_score" do
      course_with_student
      Enrollment.expects(:recompute_final_score).once
      count = 1
      enable_cache do
        Enrollment.recompute_final_score_if_stale(@course, @user){ count += 1 }
        Enrollment.recompute_final_score_if_stale(@course, @user){ count += 1 }
      end
      count.should eql 2
    end
  end

  context "recompute_final_scores" do
    it "should only recompute once per student, per course" do
      course_with_student(:active_all => true)
      @c1 = @course
      @s2 = @course.course_sections.create!(:name => 's2')
      @course.enroll_student(@user, :section => @s2, :allow_multiple_enrollments => true)
      @user.student_enrollments(true).count.should == 2
      course_with_student(:user => @user)
      @c2 = @course
      Enrollment.recompute_final_scores(@user.id)
      jobs = Delayed::Job.find_available(100).select { |j| j.tag == 'Enrollment.recompute_final_score' }
      # pull the course ids out of the job params
      jobs.map { |j| j.payload_object.args[1] }.sort.should == [@c1.id, @c2.id]
    end
  end

  context "date restrictions" do
    context "accept" do
      def enrollment_availability_test
        @enrollment.start_at = 2.days.ago
        @enrollment.end_at = 2.days.from_now
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:completed)
        @enrollment.accept.should be_false

        @enrollment.start_at = 2.days.from_now
        @enrollment.end_at = 4.days.from_now
        @enrollment.save!
        @enrollment.reload.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:invited)
        @enrollment.accept.should be_true
      end

      def course_section_availability_test(should_be_invited=false)
        @section = @course.course_sections.first
        @section.should_not be_nil
        @enrollment.course_section = @section
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @section.start_at = 2.days.ago
        @section.end_at = 2.days.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @section.start_at = 4.days.ago
        @section.end_at = 2.days.ago
        @section.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload.state.should eql(:invited)
        if should_be_invited
          @enrollment.state_based_on_date.should eql(:invited)
          @enrollment.accept.should be_true
        else
          @enrollment.state_based_on_date.should eql(:completed)
          @enrollment.accept.should be_false
        end

        @section.start_at = 2.days.from_now
        @section.end_at = 4.days.from_now
        @section.save!
        @enrollment.save!
        @enrollment.reload
        if should_be_invited
          @enrollment.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:active)
        else
          @enrollment.state.should eql(:invited)
          @enrollment.state_based_on_date.should eql(:invited)
          @enrollment.accept.should be_true
        end
      end

      def course_availability_test(state_based_state)
        @course.start_at = 2.days.ago
        @course.conclude_at = 2.days.from_now
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @course.start_at = 4.days.ago
        @course.conclude_at = 2.days.ago
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(state_based_state)

        @course.start_at = 2.days.from_now
        @course.conclude_at = 4.days.from_now
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:invited)
        @enrollment.accept.should be_true
      end

      def enrollment_term_availability_test
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.start_at = 2.days.ago
        @term.end_at = 2.days.from_now
        @term.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @term.start_at = 4.days.ago
        @term.end_at = 2.days.ago
        @term.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:invited)
        @enrollment.accept.should be_true
      end

      def enrollment_dates_override_test
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(:enrollment_type => @enrollment.type, :enrollment_term => @term)
        @override.start_at = 2.days.ago
        @override.end_at = 2.days.from_now
        @override.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @override.start_at = 4.days.ago
        @override.end_at = 2.days.ago
        @override.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.accept
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        @override.start_at = 2.days.from_now
        @override.end_at = 4.days.from_now
        @override.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:invited)
        @enrollment.accept.should be_true

        @enrollment.update_attribute(:workflow_state, 'active')
        @override.start_at = nil
        @override.end_at = nil
        @override.save!
        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        @enrollment.reload.state_based_on_date.should eql(@enrollment.admin? ? :active : :inactive)
      end

      context "as a student" do
        before do
          course_with_student(:active_all => true)
        end

        it "should accept into the right state based on availability dates on enrollment" do
          enrollment_availability_test
        end

        it "should accept into the right state based on availability dates on course_section" do
          course_section_availability_test
        end

        it "should accept into the right state based on availability dates on course" do
          course_availability_test(:completed)
        end

        it "should accept into the right state based on availability dates on enrollment_term" do
          enrollment_term_availability_test
        end

        it "should accept into the right state based on availability dates on enrollment_dates_override" do
          enrollment_dates_override_test
        end

        it "should have the correct state for a half-open past course" do
          @term = @course.enrollment_term
          @term.should_not be_nil
          @term.start_at = nil
          @term.end_at = 2.days.ago
          @term.save!

          @enrollment.workflow_state = 'invited'
          @enrollment.save!
          @enrollment.reload.state.should == :invited
          @enrollment.state_based_on_date.should == :completed
        end
      end

      context "as a teacher" do
        before do
          course_with_teacher(:active_all => true)
        end

        it "should accept into the right state based on availability dates on enrollment" do
          enrollment_availability_test
        end

        it "should accept into the right state based on availability dates on course_section" do
          course_section_availability_test(true)
        end

        it "should accept into the right state based on availability dates on course" do
          course_availability_test(:active)
        end

        it "should accept into the right state based on availability dates on enrollment_term" do
          enrollment_term_availability_test
        end

        it "should accept into the right state based on availability dates on enrollment_dates_override" do
          enrollment_dates_override_test
        end
      end
    end

    context 'student dates change' do
      before do
        enable_cache
        Timecop.freeze(10.minutes.ago) do
          course_with_student(active_all: true)
        end
      end

      describe 'enrollment dates' do
        it "should return active enrolmnet" do
          @enrollment.start_at = 2.days.ago
          @enrollment.end_at = 2.days.from_now
          @enrollment.workflow_state = 'active'
          @enrollment.save!
          @enrollment.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:active)
        end

        it "should return completed enrolmnet" do
          @enrollment.start_at = 4.days.ago
          @enrollment.end_at = 2.days.ago
          @enrollment.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:completed)
        end

        it "should return inactive enrolmnet" do
          @enrollment.start_at = 2.days.from_now
          @enrollment.end_at = 4.days.from_now
          @enrollment.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:inactive)
        end
      end

      describe 'section dates' do
        before do
          @section = @course.course_sections.first
          @section.should_not be_nil
          @section.restrict_enrollments_to_section_dates = true
        end

        it "should return active" do
          @section.start_at = 2.days.ago
          @section.end_at = 2.days.from_now
          @section.save!
          @enrollment.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:active)
        end

        it "should return completed" do
          @section.start_at = 4.days.ago
          @section.end_at = 2.days.ago
          @section.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:completed)
        end

        it "should return inactive" do
          @section.start_at = 2.days.from_now
          @section.end_at = 4.days.from_now
          @section.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:inactive)
        end
      end

      describe 'course dates' do
        before do
          @course.restrict_enrollments_to_course_dates = true
        end

        it "should return active" do
          @course.start_at = 2.days.ago
          @course.conclude_at = 2.days.from_now
          @course.save!
          @enrollment.workflow_state = 'active'
          @enrollment.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:active)
        end

        it "should return completed" do
          @course.start_at = 4.days.ago
          @course.conclude_at = 2.days.ago
          @course.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:completed)
        end

        it "should return inactive" do
          @course.start_at = 2.days.from_now
          @course.conclude_at = 4.days.from_now
          @course.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:inactive)
        end
      end

      describe 'term dates' do
        before do
          @term = @course.enrollment_term
          @term.should_not be_nil
        end

        it "should return active" do
          @term.start_at = 2.days.ago
          @term.end_at = 2.days.from_now
          @term.save!
          @enrollment.workflow_state = 'active'
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:active)
        end

        it "should return completed" do
          @term.start_at = 4.days.ago
          @term.end_at = 2.days.ago
          @term.reset_touched_courses_flag
          @term.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:completed)
        end

        it "should return inactive" do
          @term.start_at = 2.days.from_now
          @term.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @term.save!
          @enrollment.course.reload
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:inactive)
        end
      end

      describe 'enrollment_dates_override dates' do
        before do
          @term = @course.enrollment_term
          @term.should_not be_nil
          @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term)

        end

        it "should return active" do
          @override.start_at = 2.days.ago
          @override.end_at = 2.days.from_now
          @override.save!
          @enrollment.workflow_state = 'active'
          @enrollment.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:active)
        end

        it "should return completed" do
          @override.start_at = 4.days.ago
          @override.end_at = 2.days.ago
          @term.reset_touched_courses_flag
          @override.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:completed)
        end

        it "should return inactive" do
          @override.start_at = 2.days.from_now
          @override.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @override.save!
          @enrollment.reload.state.should eql(:active)
          @enrollment.state_based_on_date.should eql(:inactive)
        end
      end
    end

    it "should allow teacher access if both course and term have dates" do
      @teacher_enrollment = course_with_teacher(:active_all => 1)
      @student_enrollment = student_in_course(:active_all => 1)
      @term = @course.enrollment_term

      @teacher_enrollment.state.should == :active
      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Course dates completely before Term dates, now in course dates
      @course.start_at = 2.days.ago
      @course.conclude_at = 2.days.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @term.start_at = 4.days.from_now
      @term.end_at = 6.days.from_now
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Term dates completely before Course dates, now in course dates
      @term.start_at = 6.days.ago
      @term.end_at = 4.days.ago
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Terms dates superset of course dates, now in both
      @term.start_at = 4.days.ago
      @term.end_at = 4.days.from_now
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Course dates superset of term dates, now in both
      @course.start_at = 6.days.ago
      @course.conclude_at = 6.days.from_now
      @course.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Course dates superset of term dates, now in beginning non-overlap
      @term.start_at = 2.days.from_now
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Course dates superset of term dates, now in ending non-overlap
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :active

      # Term dates superset of course dates, now in beginning non-overlap
      @term.start_at = 6.days.ago
      @term.end_at = 6.days.from_now
      @term.save!
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!

      @teacher_enrollment.reload.state_based_on_date.should == :active
      @student_enrollment.reload.state_based_on_date.should == :inactive

      # Term dates superset of course dates, now in ending non-overlap
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      @teacher_enrollment.reload.state_based_on_date.should == :active
      @student_enrollment.reload.state_based_on_date.should == :completed

      # Course dates completely before term dates, now in term dates
      @course.start_at = 6.days.ago
      @course.conclude_at = 4.days.ago
      @course.save!
      @term.start_at = 2.days.ago
      @term.end_at = 2.days.from_now
      @term.save!

      @teacher_enrollment.reload.state_based_on_date.should == :active
      @student_enrollment.reload.state_based_on_date.should == :completed

      # Course dates completely after term dates, now in term dates
      @course.start_at = 4.days.from_now
      @course.conclude_at = 6.days.from_now
      @course.save!

      @teacher_enrollment.reload.state_based_on_date.should == :active
      @student_enrollment.reload.state_based_on_date.should == :inactive

      # Now between course and term dates, term first
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      @teacher_enrollment.reload.state_based_on_date.should == :completed
      @student_enrollment.reload.state_based_on_date.should == :inactive

      # Now after both dates
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      @teacher_enrollment.reload.state_based_on_date.should == :completed
      @student_enrollment.reload.state_based_on_date.should == :completed

      # Now before both dates
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!
      @term.start_at = 2.days.from_now
      @term.end_at = 4.days.from_now
      @term.save!

      @teacher_enrollment.reload.state_based_on_date.should == :active
      @student_enrollment.reload.state_based_on_date.should == :inactive

      # Now between course and term dates, course first
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      @teacher_enrollment.reload.state_based_on_date.should == :completed
      @student_enrollment.reload.state_based_on_date.should == :completed

    end

    it "should affect the active?/inactive?/completed? predicates" do
      course_with_student(:active_all => true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      @enrollment.active?.should be_true
      @enrollment.inactive?.should be_false
      @enrollment.completed?.should be_false

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.reload
      @enrollment.active?.should be_false
      @enrollment.inactive?.should be_false
      @enrollment.completed?.should be_true

      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      @enrollment.reload
      @enrollment.active?.should be_false
      @enrollment.inactive?.should be_true
      @enrollment.completed?.should be_false
    end

    it "should not affect the explicitly_completed? predicate" do
      course_with_student(:active_all => true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      @enrollment.explicitly_completed?.should be_false

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.explicitly_completed?.should be_false

      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      @enrollment.explicitly_completed?.should be_false

      @enrollment.workflow_state = 'completed'
      @enrollment.explicitly_completed?.should be_true
    end

    it "should affect the completed_at" do
      yesterday = 1.day.ago

      course_with_student(:active_all => true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.completed_at = nil
      @enrollment.save!

      @enrollment.completed_at.should be_nil
      @enrollment.completed_at = yesterday
      @enrollment.completed_at.should == yesterday

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.completed_at = nil
      @enrollment.save!
      @enrollment.reload

      @enrollment.completed_at.should == @enrollment.end_at
      @enrollment.completed_at = yesterday
      @enrollment.completed_at.should == yesterday
    end
  end

  context "audit_groups_for_deleted_enrollments" do
    it "should ungroup the user when the enrollment is deleted" do
      # set up course with two users in one section
      course_with_teacher(:active_all => true)
      user1 = user_model
      user2 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, 'StudentEnrollment')
      section1.enroll_user(user2, 'StudentEnrollment')

      # set up a group without a group category and put both users in it
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)

      # remove user2 from the section (effectively unenrolled from the course)
      user2.enrollments.first.destroy
      group.reload

      # he should be removed from the group
      group.users.size.should == 1
      group.users.should_not be_include(user2)
      group.should have_common_section
    end

    it "should ungroup the user when a changed enrollment causes conflict" do
      # set up course with two users in one section
      course_with_teacher(:active_all => true)
      user1 = user_model
      user2 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, 'StudentEnrollment')
      section1.enroll_user(user2, 'StudentEnrollment')

      # set up a group category in that course with restricted self sign-up and
      # put both users in one of its groups
      category = group_category
      category.configure_self_signup(true, true)
      category.save
      group = category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)
      category.should_not have_heterogenous_group

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user2.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should be removed from the group, keeping the group and the category
      # happily satisfying the self sign-up restriction.
      group.users.size.should == 1
      group.users.should_not be_include(user2)
      group.should have_common_section
      category.should_not have_heterogenous_group
    end

    it "should not ungroup the user when a the group doesn't care" do
      # set up course with two users in one section
      course_with_teacher(:active_all => true)
      user1 = user_model
      user2 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, 'StudentEnrollment')
      section1.enroll_user(user2, 'StudentEnrollment')

      # set up a group category in that course *without* restrictions on self
      # sign-up and put both users in one of its groups
      category = group_category
      category.configure_self_signup(true, false)
      category.save
      group = category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user2.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should still be in the group
      group.users.size.should == 2
      group.users.should be_include(user2)
    end

    it "should ungroup the user even when there's not another user in the group if the enrollment is deleted" do
      # set up course with only one user in one section
      course_with_teacher(:active_all => true)
      user1 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, 'StudentEnrollment')

      # set up a group category in that course with restricted self sign-up and
      # put the user in one of its groups
      category = group_category
      category.configure_self_signup(true, false)
      category.save
      group = category.groups.create(:context => @course)
      group.add_user(user1)

      # remove the user from the section (effectively unenrolled from the course)
      user1.enrollments.first.destroy
      group.reload
      category.reload

      # he should not be in the group
      group.users.size.should == 0
    end

    it "should not ungroup the user when there's not another user in the group" do
      # set up course with only one user in one section
      course_with_teacher(:active_all => true)
      user1 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, 'StudentEnrollment')

      # set up a group category in that course with restricted self sign-up and
      # put the user in one of its groups
      category = group_category
      category.configure_self_signup(true, false)
      category.save
      group = category.groups.create(:context => @course)
      group.add_user(user1)

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user1.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should still be in the group
      group.users.size.should == 1
      group.users.should be_include(user1)
    end

    it "should ignore previously deleted memberships" do
      # set up course with a user in one section
      course_with_teacher(:active_all => true)
      user = user_model
      section1 = @course.course_sections.create
      enrollment = section1.enroll_user(user, 'StudentEnrollment')

      # set up a group without a group category and put the user in it
      group = @course.groups.create
      group.add_user(user)

      # mark the membership as deleted
      membership = group.group_memberships.find_by_user_id(user.id)
      membership.workflow_state = 'deleted'
      membership.save!

      # delete the enrollment to trigger audit_groups_for_deleted_enrollments processing
      lambda {enrollment.destroy}.should_not raise_error

      # she should still be removed from the group
      group.users.size.should == 0
      group.users.should_not be_include(user)
    end
  end

  describe "for_email" do
    it "should return candidate enrollments" do
      course(:active_all => 1)

      user
      @user.update_attribute(:workflow_state, 'creation_pending')
      @user.communication_channels.create!(:path => 'jt@instructure.com')
      @course.enroll_user(@user)
      Enrollment.invited.for_email('jt@instructure.com').count.should == 1
    end

    it "should not return non-candidate enrollments" do
      course(:active_all => 1)
      # mismatched e-mail
      user
      @user.update_attribute(:workflow_state, 'creation_pending')
      @user.communication_channels.create!(:path => 'bob@instructure.com')
      @course.enroll_user(@user)
      # registered user
      user
      @user.communication_channels.create!(:path => 'jt@instructure.com')
      @user.register!
      @course.enroll_user(@user)
      # active e-mail
      user
      @user.update_attribute(:workflow_state, 'creation_pending')
      @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
      @course.enroll_user(@user)
      # accepted enrollment
      user
      @user.update_attribute(:workflow_state, 'creation_pending')
      @user.communication_channels.create!(:path => 'jt@instructure.com')
      @course.enroll_user(@user).accept
      # rejected enrollment
      user
      @user.update_attribute(:workflow_state, 'creation_pending')
      @user.communication_channels.create!(:path => 'jt@instructure.com')
      @course.enroll_user(@user).reject

      Enrollment.invited.for_email('jt@instructure.com').should == []
    end
  end

  describe "cached_temporary_invitations" do
    it "should uncache temporary user invitations when state changes" do
      enable_cache do
        course(:active_all => 1)
        user
        @user.update_attribute(:workflow_state, 'creation_pending')
        @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_user(@user)
        Enrollment.cached_temporary_invitations('jt@instructure.com').length.should == 1
        @enrollment.accept
        Enrollment.cached_temporary_invitations('jt@instructure.com').should == []
      end
    end

    it "should uncache user enrollments when rejected" do
      enable_cache do
        course_with_student(:active_course => 1)
        User.where(:id => @user).update_all(:updated_at => 1.year.ago)
        @user.reload
        @user.cached_current_enrollments.should == [@enrollment]
        @enrollment.reject!
        # have to get the new updated_at
        @user.reload
        @user.cached_current_enrollments.should == []
      end
    end

    it "should uncache user enrollments when deleted" do
      enable_cache do
        course_with_student(:active_course => 1)
        User.where(:id => @user).update_all(:updated_at => 1.year.ago)
        @user.reload
        @user.cached_current_enrollments.should == [@enrollment]
        @enrollment.destroy
        # have to get the new updated_at
        @user.reload
        @user.cached_current_enrollments.should == []
      end
    end

    context "sharding" do
      specs_require_sharding

      describe "limit_privileges_to_course_section!" do
        it "should use the right shard to find the enrollments" do
          @shard1.activate do
            account = Account.create!
            course_with_student(:active_all => true, :account => account)
          end

          @shard2.activate do
            Enrollment.limit_privileges_to_course_section!(@course, @user, true)
          end

          @enrollment.reload.limit_privileges_to_course_section.should be_true
        end
      end

      describe "cached_temporary_invitations" do
        before do
          Enrollment.stubs(:cross_shard_invitations?).returns(true)
          course(:active_all => 1)
          user
          @user.update_attribute(:workflow_state, 'creation_pending')
          @user.communication_channels.create!(:path => 'jt@instructure.com')
          @enrollment1 = @course.enroll_user(@user)
          @shard1.activate do
            account = Account.create!
            course(:active_all => 1, :account => account)
            user
            @user.update_attribute(:workflow_state, 'creation_pending')
            @user.communication_channels.create!(:path => 'jt@instructure.com')
            @enrollment2 = @course.enroll_user(@user)
          end

          pending "working CommunicationChannel.associated_shards" unless CommunicationChannel.associated_shards('jt@instructure.com').length == 2
        end

        it "should include invitations from other shards" do
          Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
          @shard1.activate do
            Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
          @shard2.activate do
            Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
        end

        it "should have a single cache for all shards" do
          enable_cache do
            @shard2.activate do
              Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
            end
            Shard.expects(:with_each_shard).never
            @shard1.activate do
              Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
            end
            Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
        end

        it "should invalidate the cache from any shard" do
          enable_cache do
            @shard2.activate do
              Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id).should == [@enrollment1, @enrollment2].sort_by(&:global_id)
              @enrollment2.reject!
            end
            @shard1.activate do
              Enrollment.cached_temporary_invitations('jt@instructure.com').should == [@enrollment1]
              @enrollment1.reject!
            end
            Enrollment.cached_temporary_invitations('jt@instructure.com').should == []
          end

        end
      end
    end
  end

  context "named scopes" do
    describe "ended" do
      it "should work" do
        course(:active_all => 1)
        user
        Enrollment.ended.should == []
        @enrollment = StudentEnrollment.create!(:user => @user, :course => @course)
        Enrollment.ended.should == []
        @enrollment.update_attribute(:workflow_state, 'active')
        Enrollment.ended.should == []
        @enrollment.update_attribute(:workflow_state, 'completed')
        Enrollment.ended.should == [@enrollment]
        @enrollment.update_attribute(:workflow_state, 'rejected')
        Enrollment.ended.should == [@enrollment]
      end
    end

    describe "future scope" do
      it "should include enrollments for future but not unpublished courses for students" do
        user
        future_course  = Course.create!(:name => 'future course', :start_at => Time.now + 2.weeks,
                                        :restrict_enrollments_to_course_dates => true)
        current_course = Course.create!(:name => 'current course', :start_at => Time.now - 2.weeks)

        current_unpublished_course  = Course.create!(:name => 'future course 2', :start_at => Time.now - 2.weeks)
        future_unpublished_course  = Course.create!(:name => 'future course 2', :start_at => Time.now + 2.weeks)
        future_unrestricted_course = Course.create!(:name => 'future course 3', :start_at => Time.now + 2.weeks)

        current_enrollment = StudentEnrollment.create!(:course => current_course, :user => @user)
        future_enrollment  = StudentEnrollment.create!(:course => future_course, :user => @user)
        current_unpublished_enrollment = StudentEnrollment.create!(:course => current_unpublished_course, :user => @user)
        future_unpublished_enrollment = StudentEnrollment.create!(:course => future_unpublished_course, :user => @user)
        future_unrestricted_enrollment = StudentEnrollment.create!(:course => future_unrestricted_course, :user => @user)

        [future_course, current_course, future_unrestricted_course].each { |course| course.offer }
        [current_enrollment, future_enrollment, current_unpublished_enrollment, future_unpublished_enrollment, future_unrestricted_enrollment].each { |e| e.accept }

        @user.enrollments.future.length.should == 1
        @user.enrollments.future.should include(future_enrollment)
      end

      it "should include enrollments for future as well as unpublished courses for admins" do
        user
        future_course  = Course.create!(:name => 'future course', :start_at => Time.now + 2.weeks,
                                        :restrict_enrollments_to_course_dates => true)
        current_course = Course.create!(:name => 'current course', :start_at => Time.now - 2.weeks)

        current_unpublished_course  = Course.create!(:name => 'future course 2', :start_at => Time.now - 2.weeks)
        future_unpublished_course  = Course.create!(:name => 'future course 2', :start_at => Time.now + 2.weeks)
        future_unrestricted_course = Course.create!(:name => 'future course 3', :start_at => Time.now + 2.weeks)

        current_enrollment = StudentEnrollment.create!(:course => current_course, :user => @user)
        future_enrollment  = StudentEnrollment.create!(:course => future_course, :user => @user)
        current_unpublished_enrollment = TeacherEnrollment.create!(:course => current_unpublished_course, :user => @user)
        future_unpublished_enrollment = TeacherEnrollment.create!(:course => future_unpublished_course, :user => @user)
        future_unrestricted_enrollment = StudentEnrollment.create!(:course => future_unrestricted_course, :user => @user)

        [future_course, current_course, future_unrestricted_course].each { |course| course.offer }
        [current_enrollment, future_enrollment, current_unpublished_enrollment, future_unpublished_enrollment, future_unrestricted_enrollment].each { |e| e.accept }

        @user.enrollments.future.length.should == 3
        @user.enrollments.future.should include(future_enrollment)
        @user.enrollments.future.should include(current_unpublished_enrollment)
        @user.enrollments.future.should include(future_unpublished_enrollment)
      end
    end
  end

  describe "destroy" do
    it "should update user_account_associations" do
      course_with_teacher(:active_all => 1)
      @user.associated_accounts.should == [Account.default]
      @enrollment.destroy
      @user.associated_accounts(true).should == []
    end
  end

  describe "effective_start_at" do
    before :each do
      course_with_student(:active_all => true)
      (@term = @course.enrollment_term).should_not be_nil
      (@section = @enrollment.course_section).should_not be_nil

      # 7 different possible times, make sure they're distinct
      @enrollment_date_start_at = 7.days.ago
      @enrollment.start_at = 6.days.ago
      @section.start_at = 5.days.ago
      @course.start_at = 4.days.ago
      @term.start_at = 3.days.ago
      @section.created_at = 2.days.ago
      @course.created_at = 1.days.ago
    end

    it "should utilize to enrollment_dates if it has a value" do
      @enrollment.stubs(:enrollment_dates).returns([[@enrollment_date_start_at, nil]])
      @enrollment.effective_start_at.should == @enrollment_date_start_at
    end

    it "should use earliest value from enrollment_dates if it has multiple" do
      @enrollment.stubs(:enrollment_dates).returns([[@enrollment.start_at, nil], [@enrollment_date_start_at, nil]])
      @enrollment.effective_start_at.should == @enrollment_date_start_at
    end

    it "should follow chain of fallbacks in correct order if no enrollment_dates" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, Time.now]])

      # start peeling away things from most preferred to least preferred to
      # test fallback chain
      @enrollment.effective_start_at.should == @enrollment.start_at
      @enrollment.start_at = nil
      @enrollment.effective_start_at.should == @section.start_at
      @section.start_at = nil
      @enrollment.effective_start_at.should == @course.start_at
      @course.start_at = nil
      @enrollment.effective_start_at.should == @term.start_at
      @term.start_at = nil
      @enrollment.effective_start_at.should == @section.created_at
      @section.created_at = nil
      @enrollment.effective_start_at.should == @course.created_at
      @course.created_at = nil
      @enrollment.effective_start_at.should be_nil
    end

    it "should not explode when missing section or term" do
      @enrollment.course_section = nil
      @course.enrollment_term = nil
      @enrollment.effective_start_at.should == @enrollment.start_at
      @enrollment.start_at = nil
      @enrollment.effective_start_at.should == @course.start_at
      @course.start_at = nil
      @enrollment.effective_start_at.should == @course.created_at
      @course.created_at = nil
      @enrollment.effective_start_at.should be_nil
    end
  end

  describe "effective_end_at" do
    before :each do
      course_with_student(:active_all => true)
      (@term = @course.enrollment_term).should_not be_nil
      (@section = @enrollment.course_section).should_not be_nil

      # 5 different possible times, make sure they're distinct
      @enrollment_date_end_at = 1.days.ago
      @enrollment.end_at = 2.days.ago
      @section.end_at = 3.days.ago
      @course.conclude_at = 4.days.ago
      @term.end_at = 5.days.ago
    end

    it "should utilize to enrollment_dates if it has a value" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, @enrollment_date_end_at]])
      @enrollment.effective_end_at.should == @enrollment_date_end_at
    end

    it "should use earliest value from enrollment_dates if it has multiple" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, @enrollment.end_at], [nil, @enrollment_date_end_at]])
      @enrollment.effective_end_at.should == @enrollment_date_end_at
    end

    it "should follow chain of fallbacks in correct order if no enrollment_dates" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, nil]])

      # start peeling away things from most preferred to least preferred to
      # test fallback chain
      @enrollment.effective_end_at.should == @enrollment.end_at
      @enrollment.end_at = nil
      @enrollment.effective_end_at.should == @section.end_at
      @section.end_at = nil
      @enrollment.effective_end_at.should == @course.conclude_at
      @course.conclude_at = nil
      @enrollment.effective_end_at.should == @term.end_at
      @term.end_at = nil
      @enrollment.effective_end_at.should be_nil
    end

    it "should not explode when missing section or term" do
      @enrollment.course_section = nil
      @course.enrollment_term = nil

      @enrollment.effective_end_at.should == @enrollment.end_at
      @enrollment.end_at = nil
      @enrollment.effective_end_at.should == @course.conclude_at
      @course.conclude_at = nil
      @enrollment.effective_end_at.should be_nil
    end
  end

  describe 'conclude' do
    it "should remove the enrollment from User#cached_current_enrollments" do
      enable_cache do
        course_with_student(:active_all => 1)
        User.where(:id => @user).update_all(:updated_at => 1.day.ago)
        @user.reload
        @user.cached_current_enrollments.should == [ @enrollment ]
        @enrollment.conclude
        @user.reload
        @user.cached_current_enrollments.should == []
      end
    end
  end

  describe 'observing users' do
    before do
      @student = user(:active_all => true)
      @parent = user_with_pseudonym(:active_all => true)
      @student.observers << @parent
    end

    it 'should get new observer enrollments when an observed user gets a new enrollment' do
      se = course_with_student(:active_all => true, :user => @student)
      pe = @parent.observer_enrollments.first

      pe.should_not be_nil
      pe.course_id.should eql se.course_id
      pe.course_section_id.should eql se.course_section_id
      pe.workflow_state.should eql se.workflow_state
      pe.associated_user_id.should eql se.user_id
    end

    it 'should have their observer enrollments updated when an observed user\'s enrollment is updated' do
      se = course_with_student(:user => @student)
      pe = @parent.observer_enrollments.first
      pe.should_not be_nil

      se.invite
      se.accept
      pe.reload.should be_active

      se.complete
      pe.reload.should be_completed
    end

    it 'should not undelete observer enrollments if the student enrollment wasn\'t already deleted' do
      se = course_with_student(:user => @student)
      pe = @parent.observer_enrollments.first
      pe.should_not be_nil
      pe.destroy

      se.invite
      pe.reload.should be_deleted

      se.accept
      pe.reload.should be_deleted
    end
  end

  describe '#can_be_deleted_by' do

    describe 'on a student enrollment' do
      let(:enrollment) { StudentEnrollment.new }
      let(:user) { stub(:id => 42) }
      let(:session) { stub }

      it 'is true for a user who has been granted the right' do
        context = stub(:grants_right? => true)
        enrollment.can_be_deleted_by(user, context, session).should be_true
      end

      it 'is false for a user without the right' do
        context = stub(:grants_right? => false)
        enrollment.can_be_deleted_by(user, context, session).should be_false
      end

      it 'is true for a user who can manage_admin_users' do
        context = Object.new
        context.stubs(:grants_right?).with(user, session, :manage_students).returns(false)
        context.stubs(:grants_right?).with(user, session, :manage_admin_users).returns(true)
        enrollment.can_be_deleted_by(user, context, session).should be_true
      end

      it 'is false if a user is trying to remove their own enrollment' do
        context = Object.new
        context.stubs(:grants_right?).with(user, session, :manage_students).returns(true)
        context.stubs(:grants_right?).with(user, session, :manage_admin_users).returns(false)
        context.stubs(:account => context)
        enrollment.user_id = user.id
        enrollment.can_be_deleted_by(user, context, session).should be_false
      end
    end
  end

  describe "#sis_user_id" do
    it "should work when sis_source_id is nil" do
      course_with_student(:active_all => 1)
      @enrollment.sis_source_id.should be_nil
      @enrollment.sis_user_id.should be_nil
    end
  end

  describe "record_recent_activity" do
    it "should record on the first call (last_activity_at is nil)" do
      course_with_student(:active_all => 1)
      @enrollment.last_activity_at.should be_nil
      @enrollment.record_recent_activity
      @enrollment.last_activity_at.should_not be_nil
    end

    it "should not record anything within the time threshold" do
      course_with_student(:active_all => 1)
      @enrollment.last_activity_at.should be_nil
      now = Time.zone.now
      @enrollment.record_recent_activity(now)
      @enrollment.record_recent_activity(now + 1.minutes)
      @enrollment.last_activity_at.to_s.should == now.to_s
    end

    it "should record again after the threshold is done" do
      course_with_student(:active_all => 1)
      @enrollment.last_activity_at.should be_nil
      now = Time.zone.now
      @enrollment.record_recent_activity(now)
      @enrollment.record_recent_activity(now + 11.minutes)
      @enrollment.last_activity_at.should.to_s == (now + 11.minutes).to_s
    end

    it "should update total_activity_time within the time threshold" do
      course_with_student(:active_all => 1)
      @enrollment.total_activity_time.should == 0
      now = Time.zone.now
      @enrollment.record_recent_activity(now)
      @enrollment.record_recent_activity(now + 1.minutes)
      @enrollment.total_activity_time.should == 0
      @enrollment.record_recent_activity(now + 3.minutes)
      @enrollment.total_activity_time.should == 3.minutes.to_i
      @enrollment.record_recent_activity(now + 30.minutes)
      @enrollment.total_activity_time.should == 3.minutes.to_i
    end
  end

  describe "updating cached due dates" do
    before do
      course_with_student
      @assignments = [
        assignment_model(:course => @course),
        assignment_model(:course => @course)
      ]
    end

    it "triggers a batch when enrollment is created" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).with(@course)
      @course.enroll_student(user)
    end

    it "triggers a batch when enrollment is deleted" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).with(@course)
      @enrollment.destroy
    end

    it "does not trigger when nothing changed" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).never
      @enrollment.save
    end
  end
end
