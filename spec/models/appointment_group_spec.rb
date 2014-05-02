#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

describe AppointmentGroup do
  context "validations" do
    before do
      course_with_student(:active_all => true)
    end

    it "should ensure the course section matches the course" do
      other_section = Course.create!.default_section
      AppointmentGroup.new(
        :title => "test",
        :contexts => [@course],
        :sub_context_codes => [other_section.asset_string]
      ).should_not be_valid
    end

    it "should ensure the group category matches the course" do
      AppointmentGroup.new(
        :title => "test",
        :contexts => [@course],
        :sub_context_codes => [GroupCategory.create(name: "foo").asset_string]
      ).should_not be_valid
    end

    it "should ignore invalid sub context types" do
      group = AppointmentGroup.new(
        :title => "test",
        :contexts => [@course],
        :sub_context_codes => [Account.create.asset_string]
      )
      group.should be_valid
      group.sub_context_codes.should be_empty
    end
  end

  context "add context" do
    it "should only add contexts" do
      course1 = course
      course_with_student(:active_all => true)
      course2 = @course

      group = AppointmentGroup.new(
        :title => "test",
        :contexts => [course1],
        :sub_context_codes => [Account.create.asset_string]
      )

      group.contexts = [course2]
      group.save!

      group.contexts.sort_by(&:id).should eql [course1, course2].sort_by(&:id)

      # also make sure you can't get duplicates
      group.contexts = [course1]
      group.save!
      group.contexts.sort_by(&:id).should eql [course1, course2].sort_by(&:id)
    end

    it "should not add contexts when it has a group category" do
      course1 = course
      gc = group_category(context: course1)
      ag = AppointmentGroup.create!(:title => 'test',
                                    :contexts => [course1],
                                    :sub_context_codes => [gc.asset_string])
      ag.contexts.should eql [course1]

      ag.contexts = [course]
      ag.save!
      ag.contexts.should eql [course1]
    end

    it "should update appointments effective_context_code" do
      course(:active_all => true)
      course1 = @course
      course(:active_all => true)
      course2 = @course

      group = AppointmentGroup.create!(
        :title => "test",
        :contexts => [course1],
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )

      group.appointments.map(&:effective_context_code).should eql [course1.asset_string]

      group.contexts = [course1, course2]
      group.save!
      group.reload
      group.appointments.map(&:effective_context_code).sort.should eql ["#{course1.asset_string},#{course2.asset_string}"]
    end
  end

  context "add sub_contexts" do
    before do
      @course1 = course
      @c1section1 = @course1.default_section
      @c1section2 = @course1.course_sections.create!

      @course2 = course
    end

    it "should only add sub_contexts when first adding a course" do
      ag = AppointmentGroup.create! :title => 'test',
                                    :contexts => [@course1],
                                    :sub_context_codes => [@c1section1.asset_string]
      ag.sub_contexts.should eql [@c1section1]
      ag.sub_context_codes = [@c1section2.asset_string]
      ag.sub_contexts.should eql [@c1section1]

      ag.contexts = [@course1, @course2]
      c2section = @course2.default_section.asset_string
      ag.sub_context_codes = [c2section]
      ag.save!
      ag.contexts.sort_by(&:id).should eql [@course1, @course2].sort_by(&:id)
      ag.sub_context_codes.sort.should eql [@c1section1.asset_string, c2section].sort
    end
  end

  context "add_appointment" do
    before do
      course_with_student(:active_all => true)
      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']])
      @appointment = @ag.appointments.first
      @appointment.should_not be_nil
    end

    it "should allow additional appointments" do
      @ag.update_attributes(:new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]).should be_true
      @ag.appointments.size.should eql 2
    end

    it "should not allow invalid appointments" do
      @ag.update_attributes(:new_appointments => [['2012-01-01 14:00:00', '2012-01-01 13:00:00']]).should be_false
    end

    it "should not allow overlapping appointments" do
      @ag.update_attributes(:new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]).should be_false
    end

    it "should update start_at/end_at when adding appointments" do
      @ag.start_at.should eql @ag.appointments.map(&:start_at).min
      @ag.end_at.should eql @ag.appointments.map(&:end_at).max

      @ag.update_attributes(:new_appointments => [
        ['2012-01-01 17:00:00', '2012-01-01 18:00:00'],
        ['2012-01-01 07:00:00', '2012-01-01 08:00:00']
      ]).should be_true

      @ag.appointments.size.should eql 3
      @ag.start_at.should eql @ag.appointments.map(&:start_at).min
      @ag.end_at.should eql @ag.appointments.map(&:end_at).max
    end
  end

  context "permissions" do
    before do
      course_with_teacher(:active_all => true)
      @teacher = @user
      section1 = @course.default_section
      section2 = @course.course_sections.create!
      section3 = @course.course_sections.create!
      other_course = Course.create!
      gc = group_category
      @user_group = @course.groups.create!(:group_category => gc)

      student_in_course(:course => @course, :active_all => true)
      @student = @user
      @user_group.users << @user

      @student_in_section2 = student_in_section(section2, :course => @course)
      @student_in_section3 = student_in_section(section3, :course => @course)

      user(:active_all => true)
      @course.enroll_user(@user, 'TaEnrollment', :section => section2, :limit_privileges_to_course_section => true).accept!
      @ta = @user

      @g1 = AppointmentGroup.create(:title => "test", :contexts => [@course])
      @g1.publish!
      @g2 = AppointmentGroup.create(:title => "test", :contexts => [@course])
      @g3 = AppointmentGroup.create(:title => "test", :contexts => [@course], :sub_context_codes => [@course.default_section.asset_string])
      @g3.publish!
      @g4 = AppointmentGroup.create(:title => "test", :contexts => [@course], :sub_context_codes => [gc.asset_string])
      @g4.publish!
      @g5 = AppointmentGroup.create(:title => "test", :contexts => [@course], :sub_context_codes => [section2.asset_string])
      @g5.publish!
      @g6 = AppointmentGroup.create(:title => "test", :contexts => [other_course])
      @g6.publish!

      # multiple sub_contexts
      @g7 = AppointmentGroup.create(:title => "test", :contexts => [@course], :sub_context_codes => [@course.default_section.asset_string, section2.asset_string])
      @g7.publish!

      # multiple contexts
      course_bak, teacher_bak = @course, @teacher
      course_with_teacher(:active_all => true)
      @course2, @teacher2 = @course, @teacher
      course_with_teacher(:user => @teacher2, :active_all => true)
      teacher_in_course(:course => @course)
      @course3, @teacher3, @course, @teacher = @course, @teacher, course_bak, teacher_bak
      @g8 = AppointmentGroup.create(:title => "test", :contexts => [@course2, @course3])
      @g8.publish!

      c2s2 = @course2.course_sections.create!
      c3s2 = @course3.course_sections.create!
      @student_in_course2_section2 = student_in_section(c2s2, :course => @course2)
      @student_in_course3_section2 = student_in_section(c3s2, :course => @course3)

      # multiple contexts and sub contexts
      @g9 = AppointmentGroup.create! :title => "multiple everything",
                                     :contexts => [@course2, @course3],
                                     :sub_context_codes => [c2s2.asset_string, c3s2.asset_string]
      @g9.publish!

      @groups = [@g1, @g2, @g3, @g4, @g5, @g7]
    end

    it "should return only appointment groups that are reservable for the user" do
      # teacher can't reserve anything for himself
      visible_groups = AppointmentGroup.reservable_by(@teacher).sort_by(&:id)
      visible_groups.should eql []
      @groups.each{ |g|
        g.grants_right?(@teacher, :reserve).should be_false
        g.eligible_participant?(@teacher).should be_false
      }

      # nor can the ta
      visible_groups = AppointmentGroup.reservable_by(@ta).sort_by(&:id)
      visible_groups.should eql []
      @groups.each{ |g|
        g.grants_right?(@ta, :reserve).should be_false
        g.eligible_participant?(@ta).should be_false
      }

      # student can reserve course-level ones, as well as section-specific ones
      visible_groups = AppointmentGroup.reservable_by(@student).sort_by(&:id)
      visible_groups.should eql [@g1, @g3, @g4, @g7]
      @g1.grants_right?(@student, :reserve).should be_true
      @g2.grants_right?(@student, :reserve).should be_false # not active yet
      @g2.eligible_participant?(@student).should be_true # though an admin could reserve on his behalf
      @g3.grants_right?(@student, :reserve).should be_true
      @g4.grants_right?(@student, :reserve).should be_true
      @g4.eligible_participant?(@student).should be_false # student can't directly participate
      @g4.eligible_participant?(@user_group).should be_true # but his group can
      @user_group.should eql(@g4.participant_for(@student))
      @g5.grants_right?(@student, :reserve).should be_false
      @g6.grants_right?(@student, :reserve).should be_false
      @g7.grants_right?(@student, :reserve).should be_true
      @g7.grants_right?(@student_in_section2, :reserve).should be_true
      @g7.grants_right?(@student_in_section3, :reserve).should be_false

      # multiple contexts
      @student_in_course1 = @student
      student_in_course(:course => @course2, :active_all => true)
      @student_in_course2 = @user
      student_in_course(:course => @course3, :active_all => true)
      @student_in_course3 = @user
      @g8.grants_right?(@student_in_course1, :reserve).should be_false
      @g8.grants_right?(@student_in_course2, :reserve).should be_true
      @g8.grants_right?(@student_in_course3, :reserve).should be_true

      # multiple contexts and sub contexts
      @g9.grants_right?(@student_in_course1, :reserve).should be_false
      @g9.grants_right?(@student_in_course2, :reserve).should be_false
      @g9.grants_right?(@student_in_course3, :reserve).should be_false

      @g9.grants_right?(@student_in_course2_section2, :reserve).should be_true
      @g9.grants_right?(@student_in_course3_section2, :reserve).should be_true
    end


    it "should return only appointment groups that are manageable by the user" do
      # teacher can manage everything in the course
      visible_groups = AppointmentGroup.manageable_by(@teacher).sort_by(&:id)
      visible_groups.should eql [@g1, @g2, @g3, @g4, @g5, @g7]
      @g1.grants_right?(@teacher, :manage).should be_true
      @g2.grants_right?(@teacher, :manage).should be_true
      @g3.grants_right?(@teacher, :manage).should be_true
      @g4.grants_right?(@teacher, :manage).should be_true
      @g5.grants_right?(@teacher, :manage).should be_true
      @g6.grants_right?(@teacher, :manage).should be_false
      @g7.grants_right?(@teacher, :manage).should be_true

      # ta can only manage stuff in section
      visible_groups = AppointmentGroup.manageable_by(@ta).sort_by(&:id)
      visible_groups.should eql [@g5, @g7]
      @g1.grants_right?(@ta, :manage).should be_false
      @g2.grants_right?(@ta, :manage).should be_false
      @g3.grants_right?(@ta, :manage).should be_false
      @g4.grants_right?(@ta, :manage).should be_false
      @g5.grants_right?(@ta, :manage).should be_true
      @g6.grants_right?(@ta, :manage).should be_false
      @g7.grants_right?(@ta, :manage).should be_false # not in all sections

      # student can't manage anything
      visible_groups = AppointmentGroup.manageable_by(@student).sort_by(&:id)
      visible_groups.should eql []
      @groups.each{ |g| g.grants_right?(@student, :manage).should be_false }

      # multiple contexts
      @g8.grants_right?(@teacher, :manage).should be_false  # not in any courses
      @g8.grants_right?(@teacher2, :manage).should be_true
      @g8.grants_right?(@teacher3, :manage).should be_false # not in all courses

      # multiple contexts and sub contexts
      @g9.grants_right?(@teacher2, :manage).should be_true
      @g9.grants_right?(@teacher3, :manage).should be_false
    end

    it "should ignore deleted courses when performing permissions checks" do
      @course3.destroy
      @g8.reload.grants_right?(@teacher2, :manage).should be_true
    end
  end

  context "notifications" do
    before do
      Notification.create(:name => 'Appointment Group Deleted', :category => "TestImmediately")
      Notification.create(:name => 'Appointment Group Published', :category => "TestImmediately")
      Notification.create(:name => 'Appointment Group Updated', :category => "TestImmediately")

      course_with_teacher(:active_all => true)
      student_in_course(:course => @course, :active_all => true)

      [@teacher, @student].each do |user|
        channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
        channel.confirm
      end

      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']])
    end

    it "should notify all participants when publishing" do
      @ag.publish!
      @ag.messages_sent.should be_include("Appointment Group Published")
      @ag.messages_sent["Appointment Group Published"].map(&:user_id).sort.uniq.should eql [@student.id]
    end

    it "should notify all participants when adding appointments" do
      @ag.publish!
      @ag.update_attributes(:new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']])
      @ag.messages_sent.should be_include("Appointment Group Updated")
      @ag.messages_sent["Appointment Group Updated"].map(&:user_id).sort.uniq.should eql [@student.id]
    end

    it "should notify all participants when deleting" do
      @ag.publish!
      @ag.cancel_reason = "just because"
      @ag.destroy
      @ag.messages_sent.should be_include("Appointment Group Deleted")
      @ag.messages_sent["Appointment Group Deleted"].map(&:user_id).sort.uniq.should eql [@student.id]
    end

    it "should not notify participants in an unpublished course" do
      @unpublished_course = course
      @unpublished_course.enroll_user(@student, 'StudentEnrollment')
      @unpublished_course.enroll_user(@teacher, 'TeacherEnrollment')

      @ag = AppointmentGroup.create!(:title => "test",
                                       :contexts => [@unpublished_course],
                                       :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']])
      @ag.publish!
      @ag.messages_sent.should be_empty

      @ag.destroy
      @ag.messages_sent.should be_empty
    end
  end

  it "should delete appointments and appointment_participants when deleting an appointment_group" do
    course_with_teacher(:active_all => true)
    @teacher = @user

    ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :new_appointments => [['2012-01-01 17:00:00', '2012-01-01 18:00:00']])
    appt = ag.appointments.first
    participants = 3.times.map {
      student_in_course(:course => @course, :active_all => true)
      participant = appt.reserve_for(@user, @teacher)
      participant.should be_locked
      participant
    }

    ag.destroy
    appt.reload.should be_deleted
    participants.each do |participant|
      participant.reload.should be_deleted
    end
  end

  context "available_slots" do
    enable_cache do
      before do
        course_with_teacher(:active_all => true)
        @teacher = @user
        @ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 2, :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
        @appointment = @ag.appointments.first
        @ag.reload.available_slots.should eql 4
      end

      it "should be nil if participants_per_appointment is nil" do
        @ag.update_attributes :participants_per_appointment => nil
        @ag.available_slots.should be_nil
      end

      it "should change if participants_per_appointment changes" do
        @ag.update_attributes :participants_per_appointment => 1
        @ag.available_slots.should eql 2
      end

      it "should be correct if participants exceed the limit for a given appointment" do
        @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
        @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
        @ag.reload.available_slots.should eql 2
        @ag.update_attributes :participants_per_appointment => 1
        @ag.reload.available_slots.should eql 1
      end

      it "should increase as appointments are added" do
        @ag.update_attributes(:new_appointments => [["#{Time.now.year + 1}-01-01 14:00:00", "#{Time.now.year + 1}-01-01 15:00:00"]])
        @ag.available_slots.should eql 6
      end

      it "should decrease as appointments are deleted" do
        @appointment.destroy
        @ag.reload.available_slots.should eql 2
      end

      it "should decrease as reservations are made" do
        @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
        @ag.reload.available_slots.should eql 3
      end

      it "should increase as reservations are canceled" do
        res = @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
        @ag.reload.available_slots.should eql 3
        res.destroy
        @ag.reload.available_slots.should eql 4
      end

      it "should decrease as enrollments conclude (if reservations are in the future)" do
        enrollment = student_in_course(:course => @course, :active_all => true)
        @appointment.reserve_for(enrollment.user, @teacher)
        @ag.reload.available_slots.should eql 3
        enrollment.conclude
        @ag.reload.available_slots.should eql 4
      end
    end
  end

  context "possible_participants" do
    before do
      course_with_teacher(:active_all => true)
      @teacher = @user

      @users, @sections = [], []
      2.times do
        @sections << section = @course.course_sections.create!
        enrollment = student_in_course(:active_all => true)
        @enrollment.course_section = section
        @enrollment.save!
        @users << @user
      end

      @group1 = group(:name => "group1", :group_context => @course)
      @group1.participating_users << @users.last
      @group1.save!
      @gc = @group1.group_category
      @group2 = @gc.groups.create!(:name => "group2", :context => @course)

      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :participants_per_appointment => 2, :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
    end

    it "should return possible participants" do
      @ag.possible_participants.should eql @users
    end

    it "should respect course_section sub_contexts" do
      @ag.appointment_group_sub_contexts.create! :sub_context => @sections.first
      @ag.possible_participants.should eql [@users.first]
    end

    it "should respect group sub_contexts" do
      @ag.appointment_group_sub_contexts.create! :sub_context => @gc
      @ag.possible_participants.sort_by(&:id).should eql [@group1, @group2].sort_by(&:id)
      @ag.possible_users.should eql [@users.last]
    end

    it "should allow filtering on registration status" do
      @ag.appointments.first.reserve_for(@users.first, @users.first)
      @ag.possible_participants.should eql @users
      @ag.possible_participants('registered').should eql [@users.first]
      @ag.possible_participants('unregistered').should eql [@users.last]
    end

    it "should allow filtering on registration status (for groups)" do
      @ag.appointment_group_sub_contexts.create! :sub_context => @gc, :sub_context_code => @gc.asset_string
      @ag.appointments.first.reserve_for(@group1, @users.first)
      @ag.possible_participants.sort_by(&:id).should eql [@group1, @group2].sort_by(&:id)
      @ag.possible_participants('registered').should eql [@group1]
      @ag.possible_participants('unregistered').should eql [@group2]
    end
  end

  context "#requiring_action?" do
    before do
      course_with_teacher(:active_all => true)
      @teacher = @user
    end

    it "returns false when participants_per_appointment is set filled" do
      # given
      ag = AppointmentGroup.create(:title => "test",
                                   :contexts => [@course],
                                   :participants_per_appointment => 1,
                                   :min_appointments_per_participant => 1,
                                   :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"]])
      student = student_in_course(:course => @course, :active_all => true).user
      ag.requiring_action?(student).should be_true
      # when
      res = ag.appointments.first.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      # expect
      ag.requiring_action?(student).should be_false
    end
  end
end
