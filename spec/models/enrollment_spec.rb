#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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
    @enrollment = Enrollment.new(valid_enrollment_attributes)
  end

  it "should be valid" do
    @enrollment.should be_valid
  end

  it "should have an interesting state machine" do
    enrollment_model
    list = {}
    list.stubs(:find_all_by_context_id_and_context_type).returns([])
    @user.stubs(:dashboard_messages).returns(list)
    @enrollment.state.should eql(:invited)
    @enrollment.accept
    @enrollment.state.should eql(:active)
    @enrollment.reject
    @enrollment.state.should eql(:rejected)
    enrollment_model
    @enrollment.complete
    @enrollment.state.should eql(:completed)
    enrollment_model
    @enrollment.reject
    @enrollment.state.should eql(:rejected)
    enrollment_model
    @enrollment.accept
    @enrollment.state.should eql(:active)
  end

  it "should find students" do
    @student_list = mock('student list')
    @student_list.stubs(:map).returns(['student list'])
    Enrollment.expects(:find).returns(@student_list)
    Enrollment.students.should eql(['student list'])
  end

  it "should be pending if it is invited or creation_pending" do
    enrollment_model(:workflow_state => 'invited')
    @enrollment.should be_pending

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

  it "should not allow read permission on a course if date inactive" do
    course_with_student(:active_all => true)
    @enrollment.start_at = 2.days.from_now
    @enrollment.end_at = 4.days.from_now
    @enrollment.workflow_state = 'active'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, nil, :read).should eql(false)
    # post to forum comes from role_override; inactive enrollments should not
    # get any permissions form role_override
    @course.grants_right?(@enrollment.user, nil, :post_to_forum).should eql(false)
  end

  it "should not allow read permission on a course if explicitly inactive" do
    course_with_student(:active_all => true)
    @enrollment.workflow_state = 'inactive'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, nil, :read).should eql(false)
    @course.grants_right?(@enrollment.user, nil, :post_to_forum).should eql(false)
  end

  it "should allow read, but not post_to_forum on a course if date completed" do
    course_with_student(:active_all => true)
    @enrollment.start_at = 4.days.ago
    @enrollment.end_at = 2.days.ago
    @enrollment.workflow_state = 'active'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, nil, :read).should eql(true)
    # post to forum comes from role_override; completed enrollments should not
    # get any permissions form role_override
    @course.grants_right?(@enrollment.user, nil, :post_to_forum).should eql(false)
  end

  it "should allow read, but not post_to_forum on a course if explicitly completed" do
    course_with_student(:active_all => true)
    @enrollment.workflow_state = 'completed'
    @enrollment.save!
    @course.grants_right?(@enrollment.user, nil, :read).should eql(true)
    @course.grants_right?(@enrollment.user, nil, :post_to_forum).should eql(false)
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
      @group.update_attribute(:rules, "drop_highest:1")
      @user.enrollments.first.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @user.enrollments.should_not be_empty
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(50.0)
      @group.reload
      @group.rules = nil
      @group.save
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.0)
    end

    it "should drop low scores for groups when specified" do
      @user.enrollments.first.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @group.update_attribute(:rules, "")
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.0)
    end

    it "should not drop the last score for a group, even if the settings say it should be dropped" do
      @group.update_attribute(:rules, "drop_lowest:2")
      @user.enrollments.first.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @user.enrollments.should_not be_empty
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
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
      @enrollment.grants_rights?(@new_user, nil, :read_grades)[:read_grades].should be_false
      @course.instructors << @new_user
      @course.save!
      @enrollment.grants_rights?(@user, nil, :read_grades).should be_true
    end

    it "should allow the user itself to read its own grades" do
      @enrollment.grants_rights?(@user, nil, :read_grades).should be_true
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
      jobs = Delayed::Job.all(:conditions => { :tag => 'Enrollment.recompute_final_score' })
      jobs.size.should == 2
      # pull the course ids out of the job params
      jobs.map { |j| j.payload_object.args[1] }.sort.should == [@c1.id, @c2.id]
    end
  end

  context "date restrictions" do
    context "accept" do
      it "should accept into the right state based on availability dates on enrollment" do
        course_with_student(:active_all => true)
        @enrollment.start_at = 2.days.ago
        @enrollment.end_at = 2.days.from_now
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:invited)
        @enrollment.accept
        @enrollment.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:completed)
        @enrollment.accept.should be_false

        @enrollment.start_at = 2.days.from_now
        @enrollment.end_at = 4.days.from_now
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:inactive)
        @enrollment.accept.should be_false
      end

      it "should accept into the right state based on availability dates on course_section" do
        course_with_student(:active_all => true)
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
        @enrollment.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        @section.start_at = 4.days.ago
        @section.end_at = 2.days.ago
        @section.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:completed)
        @enrollment.accept.should be_false

        @section.start_at = 2.days.from_now
        @section.end_at = 4.days.from_now
        @section.save!
        @enrollment.save!
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:inactive)
        @enrollment.accept.should be_false
      end

      it "should accept into the right state based on availability dates on course" do
        course_with_student(:active_all => true)
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
        @enrollment.state_based_on_date.should eql(:completed)

        @course.start_at = 2.days.from_now
        @course.conclude_at = 4.days.from_now
        @course.save!
        @enrollment.workflow_state = 'invited'
        @enrollment.save!
        @enrollment.reload
        @enrollment.state.should eql(:invited)
        @enrollment.state_based_on_date.should eql(:inactive)
        @enrollment.accept.should be_false
      end

      it "should accept into the right state based on availability dates on enrollment_term" do
        course_with_student(:active_all => true)
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
        @enrollment.state_based_on_date.should eql(:inactive)
        @enrollment.accept.should be_false
      end

      it "should accept into the right state based on availability dates on enrollment_dates_override" do
        course_with_student(:active_all => true)
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term)
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
        @enrollment.state_based_on_date.should eql(:inactive)
        @enrollment.accept.should be_false

        @enrollment.update_attribute(:workflow_state, 'active')
        @override.start_at = nil
        @override.end_at = nil
        @override.save!
        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        @enrollment.reload.state_based_on_date.should eql(:inactive)
      end
    end

    context 'dates change' do
      before(:all) do
        @old_cache = RAILS_CACHE
        silence_warnings { Object.const_set(:RAILS_CACHE, ActiveSupport::Cache::MemoryStore.new) }
      end

      after(:all) do
        silence_warnings { Object.const_set(:RAILS_CACHE, @old_cache) }
      end

      it "should return the right state based on availability dates on enrollment" do
        course_with_student(:active_all => true)
        @enrollment.start_at = 2.days.ago
        @enrollment.end_at = 2.days.from_now
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        sleep 1
        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.save!
        @enrollment.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        sleep 1
        @enrollment.start_at = 2.days.from_now
        @enrollment.end_at = 4.days.from_now
        @enrollment.save!
        @enrollment.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:inactive)
      end

      it "should return the right state based on availability dates on course_section" do
        course_with_student(:active_all => true)
        @section = @course.course_sections.first
        @section.should_not be_nil
        @enrollment.course_section = @section
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @section.start_at = 2.days.ago
        @section.end_at = 2.days.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        @enrollment.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        sleep 1
        @section.start_at = 4.days.ago
        @section.end_at = 2.days.ago
        @section.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        sleep 1
        @section.start_at = 2.days.from_now
        @section.end_at = 4.days.from_now
        @section.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:inactive)
      end

      it "should return the right state based on availability dates on course" do
        course_with_student(:active_all => true)
        @course.start_at = 2.days.ago
        @course.conclude_at = 2.days.from_now
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        sleep 1
        @course.start_at = 4.days.ago
        @course.conclude_at = 2.days.ago
        @course.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        sleep 1
        @course.start_at = 2.days.from_now
        @course.conclude_at = 4.days.from_now
        @course.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:inactive)
      end

      it "should return the right state based on availability dates on enrollment_term" do
        course_with_student(:active_all => true)
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.start_at = 2.days.ago
        @term.end_at = 2.days.from_now
        @term.save!
        @enrollment.workflow_state = 'active'
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        sleep 1
        @term.start_at = 4.days.ago
        @term.end_at = 2.days.ago
        @term.reset_touched_courses_flag
        @term.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        sleep 1
        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.reset_touched_courses_flag
        @term.save!
        @enrollment.course.reload
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:inactive)
      end

      it "should return the right state based on availability dates on enrollment_dates_override" do
        course_with_student(:active_all => true)
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term)
        @override.start_at = 2.days.ago
        @override.end_at = 2.days.from_now
        @override.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:active)

        sleep 1
        @override.start_at = 4.days.ago
        @override.end_at = 2.days.ago
        @term.reset_touched_courses_flag
        @override.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:completed)

        sleep 1
        @override.start_at = 2.days.from_now
        @override.end_at = 4.days.from_now
        @term.reset_touched_courses_flag
        @override.save!
        @enrollment.reload.state.should eql(:active)
        @enrollment.state_based_on_date.should eql(:inactive)
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

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :inactive

      # Term dates superset of course dates, now in ending non-overlap
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :completed

      # Course dates completely before term dates, now in term dates
      @course.start_at = 6.days.ago
      @course.conclude_at = 4.days.ago
      @course.save!
      @term.start_at = 2.days.ago
      @term.end_at = 2.days.from_now
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :completed

      # Course dates completely after term dates, now in term dates
      @course.start_at = 4.days.from_now
      @course.conclude_at = 6.days.from_now
      @course.save!

      @teacher_enrollment.state_based_on_date.should == :active
      @student_enrollment.state_based_on_date.should == :inactive

      # Now between course and term dates, term first
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :completed
      @student_enrollment.state_based_on_date.should == :inactive

      # Now after both dates
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      @teacher_enrollment.state_based_on_date.should == :completed
      @student_enrollment.state_based_on_date.should == :completed

      # Now before both dates
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!
      @term.start_at = 2.days.from_now
      @term.end_at = 4.days.from_now
      @term.save!

      @teacher_enrollment.state_based_on_date.should == :inactive
      @student_enrollment.state_based_on_date.should == :inactive

      # Now between course and term dates, course first
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      @teacher_enrollment.state_based_on_date.should == :completed
      @student_enrollment.state_based_on_date.should == :completed

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

      sleep 1
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.active?.should be_false
      @enrollment.inactive?.should be_false
      @enrollment.completed?.should be_true

      sleep 1
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
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

      sleep 1
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.explicitly_completed?.should be_false

      sleep 1
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

      sleep 1
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.completed_at = nil
      @enrollment.save!

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
      category = @course.group_categories.build
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
      category = @course.group_categories.build
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
      category = @course.group_categories.build
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
      category = @course.group_categories.build
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
      User.update_all({:updated_at => 1.year.ago}, :id => @user.id)
      @user.reload
      @user.cached_current_enrollments.should == [@enrollment]
      @enrollment.reject!
      @user.cached_current_enrollments(true).should == []
    end
  end

  context "named scopes" do
    describe "ended" do
      it "should work" do
        course(:active_all => 1)
        user
        Enrollment.ended.should == []
        @enrollment = Enrollment.create!(:user => @user, :course => @course)
        Enrollment.ended.should == []
        @enrollment.update_attribute(:workflow_state, 'active')
        Enrollment.ended.should == []
        @enrollment.update_attribute(:workflow_state, 'completed')
        Enrollment.ended.should == [@enrollment]
        @enrollment.update_attribute(:workflow_state, 'rejected')
        Enrollment.ended.should == [@enrollment]
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

  describe ".remove_duplicate_enrollments_from_sections" do
    before do
      course_with_student(:active_all => true)
      @e1 = @enrollment
      @e1.sis_batch_id = 2
      @e1.sis_source_id = 'ohai'
      @e1.save!
    end

    it "should leave single enrollments alone" do
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(0)
      @e1.reload.should be_active
    end

    it "should remove duplicates" do
      enrollment_model(:course_section => @course.course_sections.first, :user => @user, :sis_source_id => 'ohai', :workflow_state => 'active', :type => "StudentEnrollment")
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(-1)
    end

    it "should prefer the highest sis_batch_id" do
      enrollment_model(:course_section => @course.course_sections.first, :user => @user, :sis_source_id => 'ohai', :type => "StudentEnrollment", :sis_batch_id => 1)
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(-1)
      @e1.reload.state.should == :active
    end

    it "should group by user_id" do
      enrollment_model(:course_section => @course.course_sections.first, :user => user, :sis_source_id => 'ohai2', :type => "StudentEnrollment")
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(0)
    end

    it "should group by type" do
      enrollment_model(:course_section => @course.course_sections.first, :user => @user, :sis_source_id => 'ohai', :type => "TeacherEnrollment")
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(0)
    end

    it "should group by section" do
      enrollment_model(:course_section => @course.course_sections.create!(:name => 's2'), :user => @user, :sis_source_id => 'ohai', :type => "StudentEnrollment")
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(0)
    end

    it "should group by associated_user_id" do
      enrollment_model(:course_section => @course.course_sections.first, :user => @user, :sis_source_id => 'ohai', :associated_user_id => user.id, :type => "StudentEnrollment")
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(0)
    end

    it "should ignore non-sis enrollments" do
      @e1.update_attribute('sis_source_id', nil)
      enrollment_model(:course_section => @course.course_sections.first, :user => @user, :type => "StudentEnrollment")
      expect { Enrollment.remove_duplicate_enrollments_from_sections }.to change(Enrollment, :count).by(0)
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
        User.update_all({:updated_at => 1.day.ago}, :id => @user.id)
        @user.reload
        @user.cached_current_enrollments.should == [ @enrollment ]
        @enrollment.conclude
        @user.reload
        @user.cached_current_enrollments(true).should == []
      end
    end
  end

  describe 'observing users' do
    before do
      @student = user(:active_all => true)
      @parent = user(:active_all => true)
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

    it 'should update the best observer enrollment if there are duplicates' do
      se = course_with_student(:user => @student)
      pe = @parent.observer_enrollments.first
      pe.should_not be_nil

      pe.destroy
      pe2 = @parent.observer_enrollments.build
      pe2.course_id = pe.course_id
      pe2.course_section_id = pe.course_section_id
      pe2.associated_user_id = pe.associated_user_id
      pe2.save!

      se.invite
      pe.reload.should be_deleted
      pe2.reload.should be_invited

      se.accept
      pe.reload.should be_deleted
      pe2.reload.should be_active

      se.complete
      pe.reload.should be_deleted
      pe2.reload.should be_completed
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
end
