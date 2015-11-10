require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/notifications_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

describe "Notifications" do
  include_context "in-process server selenium tests"

  context "admin" do
    before :once do
      course_with_student(active_all: true)
      setup_comm_channel(@student, 'student@example.com')
      @teacher = user_with_pseudonym(username: 'teacher@example.com', active_all: 1)
      enrollment = teacher_in_course(course: @course, user: @teacher)
      enrollment.accept!
    end

    before :each do
      site_admin_logged_in
    end

    it "should send a notification to users that appointment groups are available", priority: "1", test_id: 186566 do
      note_name = 'Appointment Group Published'
      setup_notification(@student, name: note_name)
      create_appointment_group

      get "/users/#{@student.id}/messages"

      # Checks that the notification is there and has the correct "Notification Name" field
      fj('.ui-tabs-anchor:contains("Meta Data")').click
      expect(ff('.table-condensed.grid td').last).to include_text(note_name)
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