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
  before(:once) do
    @user = User.create!
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
  end

  it "should be valid" do
    expect(@enrollment).to be_valid
  end

  it "should have an interesting state machine" do
    enrollment_model
    @user.stubs(:dashboard_messages).returns(Message.none)
    expect(@enrollment.state).to eql(:invited)
    @enrollment.accept
    expect(@enrollment.state).to eql(:active)
    @enrollment.reject
    expect(@enrollment.state).to eql(:rejected)
    @enrollment.destroy!
    enrollment_model
    @enrollment.complete
    expect(@enrollment.state).to eql(:completed)
    @enrollment.destroy!
    enrollment_model
    @enrollment.reject
    expect(@enrollment.state).to eql(:rejected)
    @enrollment.destroy!
    enrollment_model
    @enrollment.accept
    expect(@enrollment.state).to eql(:active)
  end

  it "should be pending if it is invited or creation_pending" do
    enrollment_model(:workflow_state => 'invited')
    expect(@enrollment).to be_pending
    @enrollment.destroy!

    enrollment_model(:workflow_state => 'creation_pending')
    expect(@enrollment).to be_pending
  end

  it "should have a context_id as the course_id" do
    expect(@enrollment.course.id).not_to be_nil
    expect(@enrollment.context_id).to eql(@enrollment.course.id)
  end

  it "should have a readable_type of Teacher for a TeacherEnrollment" do
    e = TeacherEnrollment.new
    e.type = 'TeacherEnrollment'
    expect(e.readable_type).to eql('Teacher')
  end

  it "should have a readable_type of Student for a StudentEnrollment" do
    e = StudentEnrollment.new
    e.type = 'StudentEnrollment'
    expect(e.readable_type).to eql('Student')
  end

  it "should have a readable_type of TaEnrollment for a TA" do
    e = TaEnrollment.new(valid_enrollment_attributes)
    e.type = 'TaEnrollment'
    expect(e.readable_type).to eql('TA')
  end

  it "should have a defalt readable_type of Student" do
    e = Enrollment.new
    e.type = 'Other'
    expect(e.readable_type).to eql('Student')
  end

  describe "sis_role" do
    it "should return role_name if present" do
      e = TaEnrollment.new
      e.role_name = 'Assistant Grader'
      expect(e.sis_role).to eq 'Assistant Grader'
    end

    it "should return the sis enrollment type otherwise" do
      e = TaEnrollment.new
      expect(e.sis_role).to eq 'ta'
    end
  end

  it "should not allow an associated_user_id on a non-observer enrollment" do
    observed = User.create!

    @enrollment.type = 'ObserverEnrollment'
    @enrollment.associated_user_id = observed.id
    expect(@enrollment).to be_valid

    @enrollment.type = 'StudentEnrollment'
    expect(@enrollment).not_to be_valid

    @enrollment.associated_user_id = nil
    expect(@enrollment).to be_valid
  end

  context "permissions" do
    before(:once) { course_with_student(:active_all => true) }

    it "should not allow read permission on a course if date inactive" do
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to eql(false)
      # post to forum comes from role_override; inactive enrollments should not
      # get any permissions form role_override
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to eql(false)
    end

    it "should not allow read permission on a course if explicitly inactive" do
      @enrollment.workflow_state = 'inactive'
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to eql(false)
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to eql(false)
    end

    it "should allow read, but not post_to_forum on a course if date completed" do
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to eql(true)
      # post to forum comes from role_override; completed enrollments should not
      # get any permissions form role_override
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to eql(false)
    end

    it "should allow read, but not post_to_forum on a course if explicitly completed" do
      @enrollment.workflow_state = 'completed'
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to eql(true)
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to eql(false)
    end
  end

  context "typed_enrollment" do
    it "should allow StudentEnrollment" do
      expect(Enrollment.typed_enrollment('StudentEnrollment')).to eql(StudentEnrollment)
    end
    it "should allow TeacherEnrollment" do
      expect(Enrollment.typed_enrollment('TeacherEnrollment')).to eql(TeacherEnrollment)
    end
    it "should allow TaEnrollment" do
      expect(Enrollment.typed_enrollment('TaEnrollment')).to eql(TaEnrollment)
    end
    it "should allow ObserverEnrollment" do
      expect(Enrollment.typed_enrollment('ObserverEnrollment')).to eql(ObserverEnrollment)
    end
    it "should allow DesignerEnrollment" do
      expect(Enrollment.typed_enrollment('DesignerEnrollment')).to eql(DesignerEnrollment)
    end
    it "should allow not NothingEnrollment" do
      expect(Enrollment.typed_enrollment('NothingEnrollment')).to eql(nil)
    end
  end

  context "drop scores" do
    before(:once) do
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
      expect(@enrollment.reload.computed_current_score).to eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      expect(@submission[0].score).to eql(9.0)
      expect(@enrollment.reload.computed_current_score).to eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      expect(@submission2[0].score).to eql(20.0)
      expect(@enrollment.reload.computed_current_score).to eql(50.0)
      @group.update_attribute(:rules, nil)
      expect(@enrollment.reload.computed_current_score).to eql(58.0)
    end

    it "should drop low scores for groups when specified" do
      @enrollment = @user.enrollments.first
      expect(@enrollment.reload.computed_current_score).to eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      expect(@submission2[0].score).to eql(20.0)
      expect(@enrollment.reload.computed_current_score).to eql(90.0)
      @group.update_attribute(:rules, "")
      expect(@enrollment.reload.computed_current_score).to eql(58.0)
    end

    it "should not drop the last score for a group, even if the settings say it should be dropped" do
      @enrollment = @user.enrollments.first
      @group.update_attribute(:rules, "drop_lowest:2")
      expect(@enrollment.reload.computed_current_score).to eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      expect(@submission[0].score).to eql(9.0)
      expect(@enrollment.reload.computed_current_score).to eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      expect(@submission2[0].score).to eql(20.0)
      expect(@enrollment.reload.computed_current_score).to eql(90.0)
    end
  end

  context "notifications" do
    it "should send out invitations if the course is already published" do
      Notification.create!(:name => "Enrollment Registration")
      course_with_teacher(:active_all => true)
      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e.messages_sent).to be_include("Enrollment Registration")
    end

    it "should not send out invitations if the course is not yet published" do
      Notification.create!(:name => "Enrollment Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e.messages_sent).not_to be_include("Enrollment Registration")
    end

    it "should send out invitations for previously-created enrollments when the course is published" do
      n = Notification.create(:name => "Enrollment Registration", :category => "Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e.messages_sent).not_to be_include("Enrollment Registration")
      expect(@user.pseudonym).not_to be_nil
      @course.offer
      e.reload
      expect(e).to be_invited
      expect(e.user).not_to be_nil
      expect(e.user.pseudonym).not_to be_nil
      expect(Message.last).not_to be_nil
      expect(Message.last.notification).to eql(n)
      expect(Message.last.to).to eql(@user.email)
    end
  end

  context "atom" do
    it "should use the course and user name to derive a title" do
      expect(@enrollment.to_atom.title).to eql("#{@enrollment.user.name} in #{@enrollment.course.name}")
    end

    it "should link to the enrollment" do
      link_path = @enrollment.to_atom.links.first.to_s
      expect(link_path).to eql("/courses/#{@enrollment.course.id}/enrollments/#{@enrollment.id}")
    end
  end

  context "permissions" do
    it "should grant read rights to account members with the ability to read_roster" do
      user = account_admin_user(:membership_type => "AccountMembership")
      RoleOverride.create!(:context => Account.default, :permission => :read_roster,
                           :enrollment_type => "AccountMembership", :enabled => true)
      @enrollment.save

      expect(@enrollment.user.grants_right?(user, :read)).to eq false
      expect(@enrollment.grants_right?(user, :read)).to eq true
    end

    it "should be able to read grades if the course grants management rights to the enrollment" do
      @new_user = user_model
      @enrollment.save
      expect(@enrollment.grants_right?(@new_user, :read_grades)).to be_falsey
      @course.enroll_teacher(@new_user)
      @enrollment.reload
      expect(@enrollment.grants_right?(@user, :read_grades)).to be_truthy
    end

    it "should allow the user itself to read its own grades" do
      expect(@enrollment.grants_right?(@user, :read_grades)).to be_truthy
    end
  end

  context "recompute_final_score_if_stale" do
    before(:once) { course_with_student }
    it "should only call recompute_final_score once within the cache window" do
      Enrollment.expects(:recompute_final_score).once
      enable_cache do
        Enrollment.recompute_final_score_if_stale @course
        Enrollment.recompute_final_score_if_stale @course
      end
    end

    it "should yield iff it calls recompute_final_score" do
      Enrollment.expects(:recompute_final_score).once
      count = 1
      enable_cache do
        Enrollment.recompute_final_score_if_stale(@course, @user){ count += 1 }
        Enrollment.recompute_final_score_if_stale(@course, @user){ count += 1 }
      end
      expect(count).to eql 2
    end
  end

  context "recompute_final_scores" do
    it "should only recompute once per student, per course" do
      course_with_student(:active_all => true)
      @c1 = @course
      @s2 = @course.course_sections.create!(:name => 's2')
      @course.enroll_student(@user, :section => @s2, :allow_multiple_enrollments => true)
      expect(@user.student_enrollments(true).count).to eq 2
      course_with_student(:user => @user)
      @c2 = @course
      Enrollment.recompute_final_scores(@user.id)
      jobs = Delayed::Job.find_available(100).select { |j| j.tag == 'Enrollment.recompute_final_score' }
      # pull the course ids out of the job params
      expect(jobs.map { |j| j.payload_object.args[1] }.sort).to eq [@c1.id, @c2.id]
    end
  end

  context "date restrictions" do
    context "accept" do
      def enrollment_availability_test
        @enrollment.start_at = 2.days.ago
        @enrollment.end_at = 2.days.from_now
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        expect(@enrollment.state_based_on_date).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:active)

        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.reload.state).to eql(:invited)
        expect(@enrollment.state_based_on_date).to eql(:completed)
        expect(@enrollment.accept).to be_falsey

        @enrollment.start_at = 2.days.from_now
        @enrollment.end_at = 4.days.from_now
        @enrollment.save!
        expect(@enrollment.reload.state).to eql(:invited)
        expect(@enrollment.state_based_on_date).to eql(:invited)
        expect(@enrollment.accept).to be_truthy
      end

      def course_section_availability_test(should_be_invited=false)
        @section = @course.course_sections.first
        expect(@section).not_to be_nil
        @enrollment.course_section = @section
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @section.start_at = 2.days.ago
        @section.end_at = 2.days.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:active)

        @section.start_at = 4.days.ago
        @section.end_at = 2.days.ago
        @section.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.reload.state).to eql(:invited)
        if should_be_invited
          expect(@enrollment.state_based_on_date).to eql(:invited)
          expect(@enrollment.accept).to be_truthy
        else
          expect(@enrollment.state_based_on_date).to eql(:completed)
          expect(@enrollment.accept).to be_falsey
        end

        @section.start_at = 2.days.from_now
        @section.end_at = 4.days.from_now
        @section.save!
        @enrollment.save!
        @enrollment.reload
        if should_be_invited
          expect(@enrollment.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:active)
        else
          expect(@enrollment.state).to eql(:invited)
          expect(@enrollment.state_based_on_date).to eql(:invited)
          expect(@enrollment.accept).to be_truthy
        end
      end

      def course_availability_test(state_based_state)
        @course.start_at = 2.days.ago
        @course.conclude_at = 2.days.from_now
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:active)

        @course.start_at = 4.days.ago
        @course.conclude_at = 2.days.ago
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(state_based_state)

        @course.start_at = 2.days.from_now
        @course.conclude_at = 4.days.from_now
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        expect(@enrollment.state).to eql(:invited)
        expect(@enrollment.state_based_on_date).to eql(:invited)
        expect(@enrollment.accept).to be_truthy
      end

      def enrollment_term_availability_test
        @term = @course.enrollment_term
        expect(@term).not_to be_nil
        @term.start_at = 2.days.ago
        @term.end_at = 2.days.from_now
        @term.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:active)

        @term.start_at = 4.days.ago
        @term.end_at = 2.days.ago
        @term.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:completed)

        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        expect(@enrollment.state).to eql(:invited)
        expect(@enrollment.state_based_on_date).to eql(:invited)
        expect(@enrollment.accept).to be_truthy
      end

      def enrollment_dates_override_test
        @term = @course.enrollment_term
        expect(@term).not_to be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(:enrollment_type => @enrollment.type, :enrollment_term => @term)
        @override.start_at = 2.days.ago
        @override.end_at = 2.days.from_now
        @override.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:active)

        @override.start_at = 4.days.ago
        @override.end_at = 2.days.ago
        @override.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        expect(@enrollment.state).to eql(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to eql(:active)
        expect(@enrollment.state_based_on_date).to eql(:completed)

        @override.start_at = 2.days.from_now
        @override.end_at = 4.days.from_now
        @override.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        expect(@enrollment.state).to eql(:invited)
        expect(@enrollment.state_based_on_date).to eql(:invited)
        expect(@enrollment.accept).to be_truthy

        @enrollment.update_attribute(:workflow_state, 'active')
        @override.start_at = nil
        @override.end_at = nil
        @override.save!
        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        expect(@enrollment.reload.state_based_on_date).to eql(@enrollment.admin? ? :active : :inactive)
      end

      context "as a student" do
        before :once do
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
          expect(@term).not_to be_nil
          @term.start_at = nil
          @term.end_at = 2.days.ago
          @term.save!

          @enrollment.workflow_state = 'invited'
          @enrollment.save!
          expect(@enrollment.reload.state).to eq :invited
          expect(@enrollment.state_based_on_date).to eq :completed
        end
      end

      context "as a teacher" do
        before :once do
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
      before :once do
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
          expect(@enrollment.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:active)
        end

        it "should return completed enrolmnet" do
          @enrollment.start_at = 4.days.ago
          @enrollment.end_at = 2.days.ago
          @enrollment.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:completed)
        end

        it "should return inactive enrolmnet" do
          @enrollment.start_at = 2.days.from_now
          @enrollment.end_at = 4.days.from_now
          @enrollment.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:inactive)
        end
      end

      describe 'section dates' do
        before do
          @section = @course.course_sections.first
          expect(@section).not_to be_nil
          @section.restrict_enrollments_to_section_dates = true
        end

        it "should return active" do
          @section.start_at = 2.days.ago
          @section.end_at = 2.days.from_now
          @section.save!
          expect(@enrollment.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:active)
        end

        it "should return completed" do
          @section.start_at = 4.days.ago
          @section.end_at = 2.days.ago
          @section.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:completed)
        end

        it "should return inactive" do
          @section.start_at = 2.days.from_now
          @section.end_at = 4.days.from_now
          @section.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:inactive)
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
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:active)
        end

        it "should return completed" do
          @course.start_at = 4.days.ago
          @course.conclude_at = 2.days.ago
          @course.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:completed)
        end

        it "should return inactive" do
          @course.start_at = 2.days.from_now
          @course.conclude_at = 4.days.from_now
          @course.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:inactive)
        end
      end

      describe 'term dates' do
        before do
          @term = @course.enrollment_term
          expect(@term).not_to be_nil
        end

        it "should return active" do
          @term.start_at = 2.days.ago
          @term.end_at = 2.days.from_now
          @term.save!
          @enrollment.workflow_state = 'active'
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:active)
        end

        it "should return completed" do
          @term.start_at = 4.days.ago
          @term.end_at = 2.days.ago
          @term.reset_touched_courses_flag
          @term.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:completed)
        end

        it "should return inactive" do
          @term.start_at = 2.days.from_now
          @term.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @term.save!
          @enrollment.course.reload
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:inactive)
        end
      end

      describe 'enrollment_dates_override dates' do
        before do
          @term = @course.enrollment_term
          expect(@term).not_to be_nil
          @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term)

        end

        it "should return active" do
          @override.start_at = 2.days.ago
          @override.end_at = 2.days.from_now
          @override.save!
          @enrollment.workflow_state = 'active'
          @enrollment.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:active)
        end

        it "should return completed" do
          @override.start_at = 4.days.ago
          @override.end_at = 2.days.ago
          @term.reset_touched_courses_flag
          @override.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:completed)
        end

        it "should return inactive" do
          @override.start_at = 2.days.from_now
          @override.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @override.save!
          expect(@enrollment.reload.state).to eql(:active)
          expect(@enrollment.state_based_on_date).to eql(:inactive)
        end
      end
    end

    it "should allow teacher access if both course and term have dates" do
      @teacher_enrollment = course_with_teacher(:active_all => 1)
      @student_enrollment = student_in_course(:active_all => 1)
      @term = @course.enrollment_term

      expect(@teacher_enrollment.state).to eq :active
      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates completely before Term dates, now in course dates
      @course.start_at = 2.days.ago
      @course.conclude_at = 2.days.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @term.start_at = 4.days.from_now
      @term.end_at = 6.days.from_now
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Term dates completely before Course dates, now in course dates
      @term.start_at = 6.days.ago
      @term.end_at = 4.days.ago
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Terms dates superset of course dates, now in both
      @term.start_at = 4.days.ago
      @term.end_at = 4.days.from_now
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates superset of term dates, now in both
      @course.start_at = 6.days.ago
      @course.conclude_at = 6.days.from_now
      @course.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates superset of term dates, now in beginning non-overlap
      @term.start_at = 2.days.from_now
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates superset of term dates, now in ending non-overlap
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Term dates superset of course dates, now in beginning non-overlap
      @term.start_at = 6.days.ago
      @term.end_at = 6.days.from_now
      @term.save!
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Term dates superset of course dates, now in ending non-overlap
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

      # Course dates completely before term dates, now in term dates
      @course.start_at = 6.days.ago
      @course.conclude_at = 4.days.ago
      @course.save!
      @term.start_at = 2.days.ago
      @term.end_at = 2.days.from_now
      @term.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

      # Course dates completely after term dates, now in term dates
      @course.start_at = 4.days.from_now
      @course.conclude_at = 6.days.from_now
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Now between course and term dates, term first
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :completed
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Now after both dates
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :completed
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

      # Now before both dates
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!
      @term.start_at = 2.days.from_now
      @term.end_at = 4.days.from_now
      @term.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Now between course and term dates, course first
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :completed
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

    end

    it "should affect the active?/inactive?/completed? predicates" do
      course_with_student(:active_all => true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      expect(@enrollment.active?).to be_truthy
      expect(@enrollment.inactive?).to be_falsey
      expect(@enrollment.completed?).to be_falsey

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.reload
      expect(@enrollment.active?).to be_falsey
      expect(@enrollment.inactive?).to be_falsey
      expect(@enrollment.completed?).to be_truthy

      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      @enrollment.reload
      expect(@enrollment.active?).to be_falsey
      expect(@enrollment.inactive?).to be_truthy
      expect(@enrollment.completed?).to be_falsey
    end

    it "should not affect the explicitly_completed? predicate" do
      course_with_student(:active_all => true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.save!
      expect(@enrollment.explicitly_completed?).to be_falsey

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      expect(@enrollment.explicitly_completed?).to be_falsey

      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      expect(@enrollment.explicitly_completed?).to be_falsey

      @enrollment.workflow_state = 'completed'
      expect(@enrollment.explicitly_completed?).to be_truthy
    end

    it "should affect the completed_at" do
      yesterday = 1.day.ago

      course_with_student(:active_all => true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = 'active'
      @enrollment.completed_at = nil
      @enrollment.save!

      expect(@enrollment.completed_at).to be_nil
      @enrollment.completed_at = yesterday
      expect(@enrollment.completed_at).to eq yesterday

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.completed_at = nil
      @enrollment.save!
      @enrollment.reload

      expect(@enrollment.completed_at).to eq @enrollment.end_at
      @enrollment.completed_at = yesterday
      expect(@enrollment.completed_at).to eq yesterday
    end
  end

  context "audit_groups_for_deleted_enrollments" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "should ungroup the user when the enrollment is deleted" do
      # set up course with two users in one section
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
      expect(group.users.size).to eq 1
      expect(group.users).not_to be_include(user2)
      expect(group).to have_common_section
    end

    it "should ungroup the user when a changed enrollment causes conflict" do
      # set up course with two users in one section
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
      expect(category).not_to have_heterogenous_group

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user2.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should be removed from the group, keeping the group and the category
      # happily satisfying the self sign-up restriction.
      expect(group.users.size).to eq 1
      expect(group.users).not_to be_include(user2)
      expect(group).to have_common_section
      expect(category).not_to have_heterogenous_group
    end

    it "should not ungroup the user when a the group doesn't care" do
      # set up course with two users in one section
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
      expect(group.users.size).to eq 2
      expect(group.users).to be_include(user2)
    end

    it "should ungroup the user even when there's not another user in the group if the enrollment is deleted" do
      # set up course with only one user in one section
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
      expect(group.users.size).to eq 0
    end

    it "should not ungroup the user when there's not another user in the group" do
      # set up course with only one user in one section
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
      expect(group.users.size).to eq 1
      expect(group.users).to be_include(user1)
    end

    it "should ignore previously deleted memberships" do
      # set up course with a user in one section
      user = user_model
      section1 = @course.course_sections.create
      enrollment = section1.enroll_user(user, 'StudentEnrollment')

      # set up a group without a group category and put the user in it
      group = @course.groups.create
      group.add_user(user)

      # mark the membership as deleted
      membership = group.group_memberships.where(user_id: user).first
      membership.workflow_state = 'deleted'
      membership.save!

      # delete the enrollment to trigger audit_groups_for_deleted_enrollments processing
      expect {enrollment.destroy}.not_to raise_error

      # she should still be removed from the group
      expect(group.users.size).to eq 0
      expect(group.users).not_to be_include(user)
    end
  end

  describe "for_email" do
    before :once do
      course(:active_all => 1)
    end

    it "should return candidate enrollments" do
      user
      @user.update_attribute(:workflow_state, 'creation_pending')
      @user.communication_channels.create!(:path => 'jt@instructure.com')
      @course.enroll_user(@user)
      expect(Enrollment.invited.for_email('jt@instructure.com').count).to eq 1
    end

    it "should not return non-candidate enrollments" do
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

      expect(Enrollment.invited.for_email('jt@instructure.com')).to eq []
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
        expect(Enrollment.cached_temporary_invitations('jt@instructure.com').length).to eq 1
        @enrollment.accept
        expect(Enrollment.cached_temporary_invitations('jt@instructure.com')).to eq []
      end
    end

    it "should uncache user enrollments when rejected" do
      enable_cache do
        course_with_student(:active_course => 1)
        User.where(:id => @user).update_all(:updated_at => 1.year.ago)
        @user.reload
        expect(@user.cached_current_enrollments).to eq [@enrollment]
        @enrollment.reject!
        # have to get the new updated_at
        @user.reload
        expect(@user.cached_current_enrollments).to eq []
      end
    end

    it "should uncache user enrollments when deleted" do
      enable_cache do
        course_with_student(:active_course => 1)
        User.where(:id => @user).update_all(:updated_at => 1.year.ago)
        @user.reload
        expect(@user.cached_current_enrollments).to eq [@enrollment]
        @enrollment.destroy
        # have to get the new updated_at
        @user.reload
        expect(@user.cached_current_enrollments).to eq []
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

          expect(@enrollment.reload.limit_privileges_to_course_section).to be_truthy
        end
      end

      describe "cached_temporary_invitations" do
        before :once do
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
        end

        before :each do
          Enrollment.stubs(:cross_shard_invitations?).returns(true)
          skip "working CommunicationChannel.associated_shards" unless CommunicationChannel.associated_shards('jt@instructure.com').length == 2
        end

        it "should include invitations from other shards" do
          expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          @shard1.activate do
            expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
          @shard2.activate do
            expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
        end

        it "should have a single cache for all shards" do
          enable_cache do
            @shard2.activate do
              expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
            end
            Shard.expects(:with_each_shard).never
            @shard1.activate do
              expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
            end
            expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
        end

        it "should invalidate the cache from any shard" do
          enable_cache do
            @shard2.activate do
              expect(Enrollment.cached_temporary_invitations('jt@instructure.com').sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
              @enrollment2.reject!
            end
            @shard1.activate do
              expect(Enrollment.cached_temporary_invitations('jt@instructure.com')).to eq [@enrollment1]
              @enrollment1.reject!
            end
            expect(Enrollment.cached_temporary_invitations('jt@instructure.com')).to eq []
          end

        end
      end
    end
  end

  describe "destroy" do
    it "should update user_account_associations" do
      course_with_teacher(:active_all => 1)
      expect(@user.associated_accounts).to eq [Account.default]
      @enrollment.destroy
      expect(@user.associated_accounts(true)).to eq []
    end
  end

  describe "effective_start_at" do
    before :once do
      course_with_student(:active_all => true)
      expect(@term = @course.enrollment_term).not_to be_nil
      expect(@section = @enrollment.course_section).not_to be_nil

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
      expect(@enrollment.effective_start_at).to eq @enrollment_date_start_at
    end

    it "should use earliest value from enrollment_dates if it has multiple" do
      @enrollment.stubs(:enrollment_dates).returns([[@enrollment.start_at, nil], [@enrollment_date_start_at, nil]])
      expect(@enrollment.effective_start_at).to eq @enrollment_date_start_at
    end

    it "should follow chain of fallbacks in correct order if no enrollment_dates" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, Time.now]])

      # start peeling away things from most preferred to least preferred to
      # test fallback chain
      expect(@enrollment.effective_start_at).to eq @enrollment.start_at
      @enrollment.start_at = nil
      expect(@enrollment.effective_start_at).to eq @section.start_at
      @section.start_at = nil
      expect(@enrollment.effective_start_at).to eq @course.start_at
      @course.start_at = nil
      expect(@enrollment.effective_start_at).to eq @term.start_at
      @term.start_at = nil
      expect(@enrollment.effective_start_at).to eq @section.created_at
      @section.created_at = nil
      expect(@enrollment.effective_start_at).to eq @course.created_at
      @course.created_at = nil
      expect(@enrollment.effective_start_at).to be_nil
    end

    it "should not explode when missing section or term" do
      @enrollment.course_section = nil
      @course.enrollment_term = nil
      expect(@enrollment.effective_start_at).to eq @enrollment.start_at
      @enrollment.start_at = nil
      expect(@enrollment.effective_start_at).to eq @course.start_at
      @course.start_at = nil
      expect(@enrollment.effective_start_at).to eq @course.created_at
      @course.created_at = nil
      expect(@enrollment.effective_start_at).to be_nil
    end
  end

  describe "effective_end_at" do
    before :once do
      course_with_student(:active_all => true)
      expect(@term = @course.enrollment_term).not_to be_nil
      expect(@section = @enrollment.course_section).not_to be_nil

      # 5 different possible times, make sure they're distinct
      @enrollment_date_end_at = 1.days.ago
      @enrollment.end_at = 2.days.ago
      @section.end_at = 3.days.ago
      @course.conclude_at = 4.days.ago
      @term.end_at = 5.days.ago
    end

    it "should utilize to enrollment_dates if it has a value" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, @enrollment_date_end_at]])
      expect(@enrollment.effective_end_at).to eq @enrollment_date_end_at
    end

    it "should use earliest value from enrollment_dates if it has multiple" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, @enrollment.end_at], [nil, @enrollment_date_end_at]])
      expect(@enrollment.effective_end_at).to eq @enrollment_date_end_at
    end

    it "should follow chain of fallbacks in correct order if no enrollment_dates" do
      @enrollment.stubs(:enrollment_dates).returns([[nil, nil]])

      # start peeling away things from most preferred to least preferred to
      # test fallback chain
      expect(@enrollment.effective_end_at).to eq @enrollment.end_at
      @enrollment.end_at = nil
      expect(@enrollment.effective_end_at).to eq @section.end_at
      @section.end_at = nil
      expect(@enrollment.effective_end_at).to eq @course.conclude_at
      @course.conclude_at = nil
      expect(@enrollment.effective_end_at).to eq @term.end_at
      @term.end_at = nil
      expect(@enrollment.effective_end_at).to be_nil
    end

    it "should not explode when missing section or term" do
      @enrollment.course_section = nil
      @course.enrollment_term = nil

      expect(@enrollment.effective_end_at).to eq @enrollment.end_at
      @enrollment.end_at = nil
      expect(@enrollment.effective_end_at).to eq @course.conclude_at
      @course.conclude_at = nil
      expect(@enrollment.effective_end_at).to be_nil
    end
  end

  describe 'conclude' do
    it "should remove the enrollment from User#cached_current_enrollments" do
      enable_cache do
        course_with_student(:active_all => 1)
        User.where(:id => @user).update_all(:updated_at => 1.day.ago)
        @user.reload
        expect(@user.cached_current_enrollments).to eq [ @enrollment ]
        @enrollment.conclude
        @user.reload
        expect(@user.cached_current_enrollments).to eq []
      end
    end
  end

  describe 'observing users' do
    before :once do
      @student = user(:active_all => true)
      @parent = user_with_pseudonym(:active_all => true)
      @student.observers << @parent
    end

    it 'should get new observer enrollments when an observed user gets a new enrollment' do
      se = course_with_student(:active_all => true, :user => @student)
      pe = @parent.observer_enrollments.first

      expect(pe).not_to be_nil
      expect(pe.course_id).to eql se.course_id
      expect(pe.course_section_id).to eql se.course_section_id
      expect(pe.workflow_state).to eql se.workflow_state
      expect(pe.associated_user_id).to eql se.user_id
    end

    it 'should have their observer enrollments updated when an observed user\'s enrollment is updated' do
      se = course_with_student(:user => @student)
      pe = @parent.observer_enrollments.first
      expect(pe).not_to be_nil

      se.invite
      se.accept
      expect(pe.reload).to be_active

      se.complete
      expect(pe.reload).to be_completed
    end

    it 'should not undelete observer enrollments if the student enrollment wasn\'t already deleted' do
      se = course_with_student(:user => @student)
      pe = @parent.observer_enrollments.first
      expect(pe).not_to be_nil
      pe.destroy

      se.invite
      expect(pe.reload).to be_deleted

      se.accept
      expect(pe.reload).to be_deleted
    end
  end

  describe '#can_be_deleted_by' do

    describe 'on a student enrollment' do
      let(:enrollment) { StudentEnrollment.new }
      let(:user) { stub(:id => 42) }
      let(:session) { stub }

      it 'is true for a user who has been granted the right' do
        context = stub(:grants_right? => true)
        expect(enrollment.can_be_deleted_by(user, context, session)).to be_truthy
      end

      it 'is false for a user without the right' do
        context = stub(:grants_right? => false)
        expect(enrollment.can_be_deleted_by(user, context, session)).to be_falsey
      end

      it 'is true for a user who can manage_admin_users' do
        context = Object.new
        context.stubs(:grants_right?).with(user, session, :manage_students).returns(false)
        context.stubs(:grants_right?).with(user, session, :manage_admin_users).returns(true)
        expect(enrollment.can_be_deleted_by(user, context, session)).to be_truthy
      end

      it 'is false if a user is trying to remove their own enrollment' do
        context = Object.new
        context.stubs(:grants_right?).with(user, session, :manage_students).returns(true)
        context.stubs(:grants_right?).with(user, session, :manage_admin_users).returns(false)
        context.stubs(:account => context)
        enrollment.user_id = user.id
        expect(enrollment.can_be_deleted_by(user, context, session)).to be_falsey
      end
    end
  end

  describe "#sis_user_id" do
    it "should work when sis_source_id is nil" do
      course_with_student(:active_all => 1)
      expect(@enrollment.sis_source_id).to be_nil
      expect(@enrollment.sis_user_id).to be_nil
    end
  end

  describe "updating cached due dates" do
    before :once do
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
