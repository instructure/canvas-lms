require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/notifications_common')
include NotificationsCommon
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

describe "Notifications" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  context "admin" do
    before :once do
      course_with_student(active_all: true)
      NotificationsCommon.setup_comm_channel(@student, 'student@example.com')
      @teacher = user_with_pseudonym(username: 'teacher@example.com', active_all: 1)
      enrollment = teacher_in_course(course: @course, user: @teacher)
      enrollment.accept!
    end

    before :each do
      site_admin_logged_in
    end

    context "with all notifications loaded" do
      before :once do
        NotificationsCommon.load_all_notifications
      end

      context "with appointment group created" do
        before(:each) do
          create_appointment_group
          @appt_grp = AppointmentGroup.last
        end

        it "should send a notification that appointment group is available", priority: "1", test_id: 186566 do
          expected_notification = 'Appointment Group Published'

          expect(Message.last.notification_name).to eql(expected_notification)
          expect(Message.last.subject).to include_text("Appointment \"#{@appt_grp.title}\" is available for signup")
          expect(Message.last.to).to eql(@student.email)
        end

        it "should send a notification when appointment group is updated", priority: "1", test_id: 193138 do
          expected_notification = 'Appointment Group Updated'
          @appt_grp.update_attributes(new_appointments: [[Time.zone.today + 2.days, Time.zone.today + 3.days]])

          expect(Message.last.notification_name).to eql(expected_notification)
          expect(Message.last.subject).to include_text("Appointment \"#{@appt_grp.title}\" has been updated")
          expect(Message.last.to).to eql(@student.email)
        end

        it "should send a notification when appointment group is deleted", priority: "1", test_id: 193137 do
          expected_notification = 'Appointment Group Deleted'
          @appt_grp.destroy

          expect(Message.last.notification_name).to eql(expected_notification)
          expect(Message.last.subject).to include_text("Appointments for #{@appt_grp.title} have been canceled")
          expect(Message.last.to).to eql(@student.email)
        end

        it "should notify teacher when appointment is reserved by user", priority: "1", test_id: 193144 do
          skip "This spec is blocked by CNVS-24671"

          # TODO: Verify this is the correct Notification name
          expected_notification = 'Appointment Reserved By User'
          appt_grp_evt = @appt_grp.appointments[0]
          appt_grp_evt.reserve_for(@student, @student)

          expect(Message.last.notification_name).to eql(expected_notification)

          # TODO: Update the text for the notification
          expect(Message.last.subject).to include_text("Appointments for #{@appt_grp.title} have been canceled")
          expect(Message.last.to).to eql(@teacher.email)
        end

        it "should notify student when appointment scheduled on their behalf", priority: "1", test_id: 193149 do
          expected_notification = 'Appointment Reserved For User'
          appt_grp_evt = @appt_grp.appointments[0]
          appt_grp_evt.reserve_for(@student, @teacher)

          expect(Message.last.notification_name).to eql(expected_notification)
          expect(Message.last.subject).to include_text("You have been signed up for \"#{@appt_grp.title}\"")
          expect(Message.last.to).to eql(@student.email)
        end

        it "should notify teacher when student deletes appointment", priority: "1", test_id: 193147 do
          skip "This spec is blocked by CNVS-24671"

          # TODO: Verify this is the correct Notification name
          expected_notification = 'Appointment Deleted By User'
          appt_grp_evt = @appt_grp.appointments[0]
          appt_grp_evt.reserve_for(@student, @student)
          appt_grp_evt.updating_user = @student
          appt_grp_evt.destroy

          expect(Message.last.notification_name).to eql(expected_notification)

          # TODO: Update the text for the notification
          expect(Message.last.subject).to include_text("Your time slot for #{@appt_grp.title} has been canceled")
          expect(Message.last.to).to eql(@student.email)
        end

        it "should notify student when appointment is deleted", priority: "1", test_id: 193148 do
          expected_notification = 'Appointment Deleted For User'
          appt_grp_evt = @appt_grp.appointments[0]
          appt_grp_evt.reserve_for(@student, @student)
          appt_grp_evt.updating_user = @teacher
          appt_grp_evt.destroy

          expect(Message.last.notification_name).to eql(expected_notification)
          expect(Message.last.subject).to include_text("Your time slot for #{@appt_grp.title} has been canceled")
          expect(Message.last.to).to eql(@student.email)
        end

        it "should notify student when appointment is un-reserved", priority: "1", test_id: 502005 do
          expected_notification = 'Appointment Deleted For User'
          appt_grp_evt = @appt_grp.appointments[0]
          appt_grp_evt.reserve_for(@student, @student)
          user_evt = CalendarEvent.where(context_type: 'User').first
          user_evt.updating_user = @teacher
          user_evt.destroy

          expect(Message.last.notification_name).to eql(expected_notification)
          expect(Message.last.subject).to include_text("Your time slot for #{@appt_grp.title} has been canceled")
          expect(Message.last.to).to eql(@student.email)
        end
      end
    end

    context "Assignment notifications" do
      before :each do
        setup_notification(@teacher, name: 'Assignment Submitted', sms: true)
        @assignment = @course.assignments.create!(name: 'assignment',
                                                  submission_types: 'online_text_entry',
                                                  due_at: Time.zone.now.advance(days:2),
                                                 )
        @submission = @assignment.submit_homework(@student, submission_type: 'online_text_entry', body: 'hello')
        @submission.workflow_state = 'submitted'
        @submission.save!
      end

      it "should show assignment submitted notifications to teacher", priority: "1", test_id: 186561 do
        get "/users/#{@teacher.id}/messages"

        # Checks that the notification is there and has the correct "Notification Name" field
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff('.table-condensed.grid td').last).to include_text('Assignment Submitted')
        expect(ff('.table-condensed.grid td')[3]).to include_text("Submission: #{@student.name}, #{@assignment.name}")
      end

      it "should show assignment re-submitted notifications to teacher", priority: "1", test_id: 186562 do
        user_session(@student)
        setup_notification(@teacher, name: 'Assignment Resubmitted')
        # Re-submit homework
        submission = @assignment.submit_homework(@student, submission_type: 'online_text_entry', body: 'hello heyy')
        submission.workflow_state = 'submitted'
        submission.save!

        user_session(@admin)
        get "/users/#{@teacher.id}/messages"
        wait_for_ajaximations
        # Checks that the notification is there and has the correct "Notification Name" field
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff('.table-condensed.grid td').last).to include_text('Assignment Submitted')
        keep_trying_until do
          expect(ff('.table-condensed.grid td')[3]).to include_text("Re-Submission: #{@student.name}, #{@assignment.name}")
        end
      end

      it "should not show the name of the reviewer for anonymous peer reviews", priority: "1", test_id: 360185 do
        @assignment.peer_reviews = true
        @assignment.anonymous_peer_reviews = true
        @assignment.save!

        setup_notification(@student, name: 'Submission Comment', sms: true)

        reviewer = user_with_pseudonym(username: 'reviewer@example.com', active_all: 1)
        enrollment = @course.enroll_user(reviewer, 'StudentEnrollment')
        enrollment.accept!

        @assignment.assign_peer_review(@student, reviewer)
        submission_comment_model({author: reviewer, recipient: @student})

        get "/users/#{@student.id}/messages"
        # Checks that the notification is there and has the correct "Notification Name" field
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff('.table-condensed.grid td').last).to include_text('Submission Comment')
        keep_trying_until do
          expect(ff('.table-condensed.grid td')[7]).to include_text('Anonymous User')
        end

        fj('.ui-tabs-anchor:contains("Plain Text")').click
        keep_trying_until do
          expect(f('.message-body').text).to include('Anonymous User just made a new comment on the '\
                                                     'submission for User for assignment')
        end
      end
    end

    context "Announcement notification" do
      before :each do
        setup_notification(@student, name: 'New Announcement', category: 'Announcement', sms: true)
      end

      it "should show announcement notifications to student", priority: "1", test_id: 186563 do
        @course.announcements.create!(:title => 'Announcement', :message => 'Announcement time!')
        # Checks that the notification is there and has the correct "Notification Name" field
        get "/users/#{@student.id}/messages"
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff('.table-condensed.grid td').last).to include_text('New Announcement')
        keep_trying_until do
          expect(ff('.table-condensed.grid td')[3]).to include_text("Announcement: #{@course.name}")
        end
      end
    end
  end
end
