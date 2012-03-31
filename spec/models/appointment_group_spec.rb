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

describe AppointmentGroup do
  context "validations" do
    before do
      course_with_student(:active_all => true)
    end

    it "should ensure the course section matches the course" do
      AppointmentGroup.new(
        :title => "test",
        :context => @course,
        :sub_context_code => CourseSection.create.asset_string
      ).should_not be_valid
    end

    it "should ensure the group category matches the course" do
      AppointmentGroup.new(
        :title => "test",
        :context => @course,
        :sub_context_code => GroupCategory.create.asset_string
      ).should_not be_valid
    end

    it "should ignore invalid sub context types" do
      group = AppointmentGroup.new(
        :title => "test",
        :context => @course,
        :sub_context_code => Account.create.asset_string
      )
      group.should be_valid
      group.sub_context_code.should be_nil
    end
  end

  context "add_appointment" do
    before do
      course_with_student(:active_all => true)
      @ag = AppointmentGroup.create!(:title => "test", :context => @course, :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']])
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
      other_section = @course.course_sections.create!
      other_course = Course.create!
      gc = @course.group_categories.create!
      @user_group = @course.groups.create!(:group_category => gc)

      student_in_course(:course => @course, :active_all => true)
      @student = @user
      @user_group.users << @user

      user(:active_all => true)
      @course.enroll_user(@user, 'TaEnrollment', :section => other_section, :limit_privileges_to_course_section => true).accept!
      @ta = @user

      @g1 = AppointmentGroup.create(:title => "test", :context => @course)
      @g1.publish!
      @g2 = AppointmentGroup.create(:title => "test", :context => @course)
      @g3 = AppointmentGroup.create(:title => "test", :context => @course, :sub_context_code => @course.default_section.asset_string)
      @g3.publish!
      @g4 = AppointmentGroup.create(:title => "test", :context => @course, :sub_context_code => gc.asset_string)
      @g4.publish!
      @g5 = AppointmentGroup.create(:title => "test", :context => @course, :sub_context_code => other_section.asset_string)
      @g5.publish!
      @g6 = AppointmentGroup.create(:title => "test", :context => other_course)
      @g6.publish!
      @groups = [@g1, @g2, @g3, @g4, @g5]
    end

    it "should return only appointment groups that are reservable for the user" do
      # teacher can't reserve anything for himself
      visible_groups = AppointmentGroup.reservable_by(@teacher).sort_by(&:id)
      visible_groups.should eql []
      @groups.each{ |g|
        g.grants_right?(@teacher, nil, :reserve).should be_false
        g.eligible_participant?(@teacher).should be_false
      }

      # nor can the ta
      visible_groups = AppointmentGroup.reservable_by(@ta).sort_by(&:id)
      visible_groups.should eql []
      @groups.each{ |g|
        g.grants_right?(@ta, nil, :reserve).should be_false
        g.eligible_participant?(@ta).should be_false
      }

      # student can reserve course-level ones, as well as section-specific ones
      visible_groups = AppointmentGroup.reservable_by(@student).sort_by(&:id)
      visible_groups.should eql [@g1, @g3, @g4]
      @g1.grants_right?(@student, nil, :reserve).should be_true
      @g2.grants_right?(@student, nil, :reserve).should be_false # not active yet
      @g2.eligible_participant?(@student).should be_true # though an admin could reserve on his behalf
      @g3.grants_right?(@student, nil, :reserve).should be_true
      @g4.grants_right?(@student, nil, :reserve).should be_true
      @g4.eligible_participant?(@student).should be_false # student can't directly participate
      @g4.eligible_participant?(@user_group).should be_true # but his group can
      @user_group.should eql(@g4.participant_for(@student))
      @g5.grants_right?(@student, nil, :reserve).should be_false
      @g6.grants_right?(@student, nil, :reserve).should be_false
    end


    it "should return only appointment groups that are manageable by the user" do
      # teacher can manage everything in the course
      visible_groups = AppointmentGroup.manageable_by(@teacher).sort_by(&:id)
      visible_groups.should eql [@g1, @g2, @g3, @g4, @g5]
      @g1.grants_right?(@teacher, nil, :manage).should be_true
      @g2.grants_right?(@teacher, nil, :manage).should be_true
      @g3.grants_right?(@teacher, nil, :manage).should be_true
      @g4.grants_right?(@teacher, nil, :manage).should be_true
      @g5.grants_right?(@teacher, nil, :manage).should be_true
      @g6.grants_right?(@teacher, nil, :manage).should be_false

      # ta can only manage stuff in section
      visible_groups = AppointmentGroup.manageable_by(@ta).sort_by(&:id)
      visible_groups.should eql [@g5]
      @g1.grants_right?(@ta, nil, :manage).should be_false
      @g2.grants_right?(@ta, nil, :manage).should be_false
      @g3.grants_right?(@ta, nil, :manage).should be_false
      @g4.grants_right?(@ta, nil, :manage).should be_false
      @g5.grants_right?(@ta, nil, :manage).should be_true
      @g6.grants_right?(@ta, nil, :manage).should be_false

      # student can't manage anything
      visible_groups = AppointmentGroup.manageable_by(@student).sort_by(&:id)
      visible_groups.should eql []
      @groups.each{ |g| g.grants_right?(@student, nil, :manage).should be_false }
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

      @ag = @course.appointment_groups.create(:title => "test", :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']])
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
      @ag.destroy
      @ag.messages_sent.should be_include("Appointment Group Deleted")
      @ag.messages_sent["Appointment Group Deleted"].map(&:user_id).sort.uniq.should eql [@student.id]
    end

    it "should not notify participants in an unpublished course" do
      @unpublished_course = course
      @unpublished_course.enroll_user(@student, 'StudentEnrollment')
      @unpublished_course.enroll_user(@teacher, 'TeacherEnrollment')

      @ag = @unpublished_course.appointment_groups.create(:title => "test", 
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

    ag = AppointmentGroup.create(:title => "test", :context => @course, :new_appointments => [['2012-01-01 17:00:00', '2012-01-01 18:00:00']])
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
        @ag = @course.appointment_groups.create(:title => "test", :participants_per_appointment => 2, :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
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
end
