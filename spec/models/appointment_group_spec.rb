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
    before :once do
      course_with_student(:active_all => true)
    end

    it "should ensure the course section matches the course" do
      other_section = Course.create!.default_section
      expect(AppointmentGroup.new(
        :title => "test",
        :contexts => [@course],
        :sub_context_codes => [other_section.asset_string]
      )).not_to be_valid
    end

    it "should ensure the group category matches the course" do
      expect(AppointmentGroup.new(
        :title => "test",
        :contexts => [@course],
        :sub_context_codes => [GroupCategory.create(name: "foo").asset_string]
      )).not_to be_valid
    end

    it "should ignore invalid sub context types" do
      group = AppointmentGroup.new(
        :title => "test",
        :contexts => [@course],
        :sub_context_codes => [Account.create.asset_string]
      )
      expect(group).to be_valid
      expect(group.sub_context_codes).to be_empty
    end
  end

  context "add context" do
    let_once(:course1) { course_factory(active_all: true) }

    it "should only add contexts" do
      course_with_student(:active_all => true)
      course2 = @course

      group = AppointmentGroup.new(
        :title => "test",
        :contexts => [course1],
        :sub_context_codes => [Account.create.asset_string]
      )

      group.contexts = [course2]
      group.save!

      expect(group.contexts.sort_by(&:id)).to eql [course1, course2].sort_by(&:id)

      # also make sure you can't get duplicates
      group.contexts = [course1]
      group.save!
      expect(group.contexts.sort_by(&:id)).to eql [course1, course2].sort_by(&:id)
    end

    it "should not add contexts when it has a group category" do
      gc = group_category(context: course1)
      ag = AppointmentGroup.create!(:title => 'test',
                                    :contexts => [course1],
                                    :sub_context_codes => [gc.asset_string])
      expect(ag.contexts).to eql [course1]

      ag.contexts = [course_factory]
      ag.save!
      expect(ag.contexts).to eql [course1]
    end

    it "should update appointments effective_context_code" do
      course_factory(active_all: true)
      course2 = @course

      group = AppointmentGroup.create!(
        :title => "test",
        :contexts => [course1],
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )

      expect(group.appointments.map(&:effective_context_code)).to eql [course1.asset_string]

      group.contexts = [course1, course2]
      group.save!
      group.reload
      expect(group.appointments.map(&:effective_context_code).sort).to eql ["#{course1.asset_string},#{course2.asset_string}"]
    end
  end

  context "add sub_contexts" do
    before :once do
      @course1 = course_factory
      @c1section1 = @course1.default_section
      @c1section2 = @course1.course_sections.create!

      @course2 = course_factory
    end

    it "should only add sub_contexts when first adding a course" do
      ag = AppointmentGroup.create! :title => 'test',
                                    :contexts => [@course1],
                                    :sub_context_codes => [@c1section1.asset_string]
      expect(ag.sub_contexts).to eql [@c1section1]
      ag.sub_context_codes = [@c1section2.asset_string]
      expect(ag.sub_contexts).to eql [@c1section1]

      ag.contexts = [@course1, @course2]
      c2section = @course2.default_section.asset_string
      ag.sub_context_codes = [c2section]
      ag.save!
      expect(ag.contexts.sort_by(&:id)).to eql [@course1, @course2].sort_by(&:id)
      expect(ag.sub_context_codes.sort).to eql [@c1section1.asset_string, c2section].sort
    end
  end

  context "add_appointment" do
    before :once do
      course_with_student(:active_all => true)
      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']])
      @appointment = @ag.appointments.first
    end

    it "should allow additional appointments" do
      expect(@ag.update_attributes(:new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']])).to be_truthy
      expect(@ag.appointments.size).to eql 2
    end

    it "should not allow invalid appointments" do
      expect(@ag.update_attributes(:new_appointments => [['2012-01-01 14:00:00', '2012-01-01 13:00:00']])).to be_falsey
    end

    it "should not allow overlapping appointments" do
      expect(@ag.update_attributes(:new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']])).to be_falsey
    end

    it "should update start_at/end_at when adding appointments" do
      expect(@ag.start_at).to eql @ag.appointments.map(&:start_at).min
      expect(@ag.end_at).to eql @ag.appointments.map(&:end_at).max

      expect(@ag.update_attributes(:new_appointments => [
        ['2012-01-01 17:00:00', '2012-01-01 18:00:00'],
        ['2012-01-01 07:00:00', '2012-01-01 08:00:00']
      ])).to be_truthy

      expect(@ag.appointments.size).to eql 3
      expect(@ag.start_at).to eql @ag.appointments.map(&:start_at).min
      expect(@ag.end_at).to eql @ag.appointments.map(&:end_at).max
    end
  end

  context "permissions" do
    before :once do
      @course, @course2, @course3, other_course = create_courses(4, return_type: :record)

      @teacher, @teacher2, @teacher3, @ta, @student, @student_in_section2, @student_in_section3,
        @student_in_course2_section2, @student_in_course3_section2 = create_users(9, return_type: :record)

      section2 = @course.course_sections.create!
      section3 = @course.course_sections.create!
      c2s2 = @course2.course_sections.create!
      c3s2 = @course3.course_sections.create!

      gc = group_category
      @user_group = @course.groups.create!(:group_category => gc)
      @user_group.users << @student

      create_enrollment @course, @teacher, enrollment_type: "TeacherEnrollment"
      create_enrollment @course, @student
      create_enrollment @course, @student_in_section2, section: section2
      create_enrollment @course, @student_in_section3, section: section3
      create_enrollment @course, @ta, enrollment_type: "TaEnrollment", section: section2,
                                      limit_privileges_to_course_section: true
      create_enrollment @course2, @teacher2, enrollment_type: "TeacherEnrollment"
      create_enrollment @course3, @teacher2, enrollment_type: "TeacherEnrollment"
      create_enrollment @course3, @teacher3, enrollment_type: "TeacherEnrollment"
      create_enrollment @course2, @student_in_course2_section2, section: c2s2
      create_enrollment @course3, @student_in_course3_section2, section: c3s2

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
      @g8 = AppointmentGroup.create(:title => "test", :contexts => [@course2, @course3])
      @g8.publish!

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
      expect(visible_groups).to eql []
      @groups.each{ |g|
        expect(g.grants_right?(@teacher, :reserve)).to be_falsey
        expect(g.eligible_participant?(@teacher)).to be_falsey
      }

      # nor can the ta
      visible_groups = AppointmentGroup.reservable_by(@ta).sort_by(&:id)
      expect(visible_groups).to eql []
      @groups.each{ |g|
        expect(g.grants_right?(@ta, :reserve)).to be_falsey
        expect(g.eligible_participant?(@ta)).to be_falsey
      }

      # student can reserve course-level ones, as well as section-specific ones
      visible_groups = AppointmentGroup.reservable_by(@student).sort_by(&:id)
      expect(visible_groups).to eql [@g1, @g3, @g4, @g7]
      expect(@g1.grants_right?(@student, :reserve)).to be_truthy
      expect(@g2.grants_right?(@student, :reserve)).to be_falsey # not active yet
      expect(@g2.eligible_participant?(@student)).to be_truthy # though an admin could reserve on his behalf
      expect(@g3.grants_right?(@student, :reserve)).to be_truthy
      expect(@g4.grants_right?(@student, :reserve)).to be_truthy
      expect(@g4.eligible_participant?(@student)).to be_falsey # student can't directly participate
      expect(@g4.eligible_participant?(@user_group)).to be_truthy # but his group can
      expect(@user_group).to eql(@g4.participant_for(@student))
      expect(@g5.grants_right?(@student, :reserve)).to be_falsey
      expect(@g6.grants_right?(@student, :reserve)).to be_falsey
      expect(@g7.grants_right?(@student, :reserve)).to be_truthy
      expect(@g7.grants_right?(@student_in_section2, :reserve)).to be_truthy
      expect(@g7.grants_right?(@student_in_section3, :reserve)).to be_falsey

      # multiple contexts
      @student_in_course1 = @student
      student_in_course(:course => @course2, :active_all => true)
      @student_in_course2 = @user
      student_in_course(:course => @course3, :active_all => true)
      @student_in_course3 = @user
      expect(@g8.grants_right?(@student_in_course1, :reserve)).to be_falsey
      expect(@g8.grants_right?(@student_in_course2, :reserve)).to be_truthy
      expect(@g8.grants_right?(@student_in_course3, :reserve)).to be_truthy

      # multiple contexts and sub contexts
      expect(@g9.grants_right?(@student_in_course1, :reserve)).to be_falsey
      expect(@g9.grants_right?(@student_in_course2, :reserve)).to be_falsey
      expect(@g9.grants_right?(@student_in_course3, :reserve)).to be_falsey

      expect(@g9.grants_right?(@student_in_course2_section2, :reserve)).to be_truthy
      expect(@g9.grants_right?(@student_in_course3_section2, :reserve)).to be_truthy
    end


    it "should return only appointment groups that are manageable by the user" do
      # teacher can manage everything in the course
      visible_groups = AppointmentGroup.manageable_by(@teacher).sort_by(&:id)
      expect(visible_groups).to eql [@g1, @g2, @g3, @g4, @g5, @g7]
      expect(@g1.grants_right?(@teacher, :manage)).to be_truthy
      expect(@g2.grants_right?(@teacher, :manage)).to be_truthy
      expect(@g3.grants_right?(@teacher, :manage)).to be_truthy
      expect(@g4.grants_right?(@teacher, :manage)).to be_truthy
      expect(@g5.grants_right?(@teacher, :manage)).to be_truthy
      expect(@g6.grants_right?(@teacher, :manage)).to be_falsey
      expect(@g7.grants_right?(@teacher, :manage)).to be_truthy

      # ta can only manage stuff in section
      visible_groups = AppointmentGroup.manageable_by(@ta).sort_by(&:id)
      expect(visible_groups).to eql [@g5, @g7]
      expect(@g1.grants_right?(@ta, :manage)).to be_falsey
      expect(@g2.grants_right?(@ta, :manage)).to be_falsey
      expect(@g3.grants_right?(@ta, :manage)).to be_falsey
      expect(@g4.grants_right?(@ta, :manage)).to be_falsey
      expect(@g5.grants_right?(@ta, :manage)).to be_truthy
      expect(@g6.grants_right?(@ta, :manage)).to be_falsey
      expect(@g7.grants_right?(@ta, :manage)).to be_falsey # not in all sections

      # student can't manage anything
      visible_groups = AppointmentGroup.manageable_by(@student).sort_by(&:id)
      expect(visible_groups).to eql []
      @groups.each{ |g| expect(g.grants_right?(@student, :manage)).to be_falsey }

      # multiple contexts
      expect(@g8.grants_right?(@teacher, :manage)).to be_falsey  # not in any courses
      expect(@g8.grants_right?(@teacher2, :manage)).to be_truthy
      expect(@g8.grants_right?(@teacher3, :manage)).to be_truthy # in at least one course

      # multiple contexts and sub contexts
      expect(@g9.grants_right?(@teacher2, :manage)).to be_truthy
      expect(@g9.grants_right?(@teacher3, :manage)).to be_truthy
    end

    it "should ignore deleted courses when performing permissions checks" do
      @course3.destroy
      expect(@g8.active_contexts).not_to include @course3
      expect(@g8.reload.grants_right?(@teacher2, :manage)).to be_truthy
    end

    it "should give :manage permission even if some contexts are concluded" do
      @course3.complete!
      expect(@g8.reload.grants_right?(@teacher2, :manage)).to be_truthy
    end

    it "should not give :manage permission if all contexts are (hard-)concluded" do
      @course2.complete!
      @course3.complete!
      expect(@g8.reload.grants_right?(@teacher2, :manage)).to be_falsey
    end

    it "should give :manage permission if a context is soft-concluded" do
      @course.soft_conclude!
      expect(@g1.reload.grants_right?(@teacher, :manage)).to be_truthy
    end
  end

  context "notifications" do
    before :once do
      Notification.create(:name => 'Appointment Group Deleted', :category => "TestImmediately")
      Notification.create(:name => 'Appointment Group Published', :category => "TestImmediately")
      Notification.create(:name => 'Appointment Group Updated', :category => "TestImmediately")

      course_with_teacher(:active_all => true)
      student_in_course(:course => @course, :active_all => true)
      course_with_observer(active_all: true, active_cc: true, course: @course, associated_user_id: @student)

      [@teacher, @student].each do |user|
        channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
        channel.confirm
      end

      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']])
    end

    it "should notify all participants when publishing", priority: "1", test_id: 186566 do
      @ag.publish!
      expect(@ag.messages_sent).to be_include("Appointment Group Published")
      expect(@ag.messages_sent["Appointment Group Published"].map(&:user_id).sort.uniq).to eql [@student.id, @observer.id].sort
    end

    it "should notify all participants when adding appointments", priority: "1", test_id: 193138 do
      @ag.publish!
      @ag.update_attributes(:new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']])
      expect(@ag.messages_sent).to be_include("Appointment Group Updated")
      expect(@ag.messages_sent["Appointment Group Updated"].map(&:user_id).sort.uniq).to eql [@student.id, @observer.id].sort
    end

    it "should notify all participants when deleting", priority: "1", test_id: 193137 do
      @ag.publish!
      @ag.cancel_reason = "just because"
      @ag.destroy
      expect(@ag.messages_sent).to be_include("Appointment Group Deleted")
      expect(@ag.messages_sent["Appointment Group Deleted"].map(&:user_id).sort.uniq).to eql [@student.id, @observer.id].sort
    end

    it "should not notify participants when unpublished" do
      @ag.destroy
      expect(@ag.messages_sent).to be_empty
    end

    it "should not notify participants in an unpublished course" do
      @unpublished_course = course_factory
      @unpublished_course.enroll_user(@student, 'StudentEnrollment')
      @unpublished_course.enroll_user(@teacher, 'TeacherEnrollment')
      @unpublished_course.enroll_user(@observer, 'ObserverEnrollment')

      @ag = AppointmentGroup.create!(:title => "test",
                                       :contexts => [@unpublished_course],
                                       :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']])
      @ag.publish!
      expect(@ag.messages_sent).to be_empty

      @ag.destroy
      expect(@ag.messages_sent).to be_empty
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
      expect(participant).to be_locked
      participant
    }

    ag.destroy
    expect(appt.reload).to be_deleted
    participants.each do |participant|
      expect(participant.reload).to be_deleted
    end
  end

  context "available_slots" do
    before :once do
      course_with_teacher(:active_all => true)
      @teacher = @user
      @ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 2, :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      @appointment = @ag.appointments.first
    end

    it "should be nil if participants_per_appointment is nil" do
      @ag.update_attributes :participants_per_appointment => nil
      expect(@ag.available_slots).to be_nil
    end

    it "should change if participants_per_appointment changes" do
      @ag.update_attributes :participants_per_appointment => 1
      expect(@ag.available_slots).to eql 2
    end

    it "should be correct if participants exceed the limit for a given appointment" do
      @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      expect(@ag.reload.available_slots).to eql 2
      @ag.update_attributes :participants_per_appointment => 1
      expect(@ag.reload.available_slots).to eql 1
    end

    it "should increase as appointments are added" do
      @ag.update_attributes(:new_appointments => [["#{Time.now.year + 1}-01-01 14:00:00", "#{Time.now.year + 1}-01-01 15:00:00"]])
      expect(@ag.available_slots).to eql 6
    end

    it "should decrease as appointments are deleted" do
      @appointment.destroy
      expect(@ag.reload.available_slots).to eql 2
    end

    it "should decrease as reservations are made" do
      @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      expect(@ag.reload.available_slots).to eql 3
    end

    it "should increase as reservations are canceled" do
      res = @appointment.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      expect(@ag.reload.available_slots).to eql 3
      res.destroy
      expect(@ag.reload.available_slots).to eql 4
    end

    it "should decrease as enrollments conclude (if reservations are in the future)" do
      enrollment = student_in_course(:course => @course, :active_all => true)
      @appointment.reserve_for(enrollment.user, @teacher)
      expect(@ag.reload.available_slots).to eql 3
      enrollment.conclude
      expect(@ag.reload.available_slots).to eql 4
    end
  end

  context "possible_participants" do
    before :once do
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
      expect(@ag.possible_participants).to eql @users
    end

    it "should respect course_section sub_contexts" do
      @ag.appointment_group_sub_contexts.create! :sub_context => @sections.first
      expect(@ag.possible_participants).to eql [@users.first]
    end

    it "should respect group sub_contexts" do
      @ag.appointment_group_sub_contexts.create! :sub_context => @gc
      expect(@ag.possible_participants.sort_by(&:id)).to eql [@group1, @group2].sort_by(&:id)
      expect(@ag.possible_users).to eql [@users.last]
    end

    it "should allow filtering on registration status" do
      @ag.appointments.first.reserve_for(@users.first, @users.first)
      expect(@ag.possible_participants).to eql @users
      expect(@ag.possible_participants(registration_status: 'registered')).to eql [@users.first]
      expect(@ag.possible_participants(registration_status: 'unregistered')).to eql [@users.last]
    end

    it "should allow filtering on registration status (for groups)" do
      @ag.appointment_group_sub_contexts.create! :sub_context => @gc, :sub_context_code => @gc.asset_string
      @ag.appointments.first.reserve_for(@group1, @users.first)
      expect(@ag.possible_participants.sort_by(&:id)).to eql [@group1, @group2].sort_by(&:id)
      expect(@ag.possible_participants(registration_status: 'registered')).to eql [@group1]
      expect(@ag.possible_participants(registration_status: 'unregistered')).to eql [@group2]
    end
  end

  context "#requiring_action?" do
    before :once do
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
      expect(ag.requiring_action?(student)).to be_truthy
      # when
      res = ag.appointments.first.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      # expect
      expect(ag.requiring_action?(student)).to be_falsey
    end

    it "deals with custom-sized appointments" do
      ag = AppointmentGroup.create(:title => "test",
                                   :contexts => [@course],
                                   :participants_per_appointment => 1,
                                   :min_appointments_per_participant => 1,
                                   :new_appointments => [["#{Time.now.year + 1}-01-01 12:00:00", "#{Time.now.year + 1}-01-01 13:00:00"],
                                                         ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      ag.appointments.first.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      ag.appointments.last.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher)
      expect(ag).to be_all_appointments_filled
      ag.appointments.last.update_attribute :participants_per_appointment, 2
      expect(ag).not_to be_all_appointments_filled
    end
  end
end
