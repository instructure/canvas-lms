# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/notifications_common"
require_relative "../helpers/calendar2_common"

describe "Notifications" do
  include NotificationsCommon
  include_context "in-process server selenium tests"
  include Calendar2Common

  context "admin" do
    before :once do
      Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
      course_with_student(active_all: true)
      setup_comm_channel(@student, "student@example.com")
      @teacher = user_with_pseudonym(username: "teacher@example.com", active_all: 1)
      enrollment = teacher_in_course(course: @course, user: @teacher)
      enrollment.accept!
    end

    before do
      site_admin_logged_in
    end

    context "Assignment notifications" do
      before :once do
        setup_notification(@teacher, name: "Assignment Submitted")
        setup_notification(@teacher, name: "Assignment Resubmitted")
        @assignment = @course.assignments.create!(name: "assignment",
                                                  submission_types: "online_text_entry",
                                                  due_at: Time.zone.now.advance(days: 2))
        @submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "hello")
        @submission.workflow_state = "submitted"
        @submission.save!
      end

      it "shows assignment submitted notifications to teacher", priority: "1" do
        get "/users/#{@teacher.id}/messages"

        # Checks that the notification is there and has the correct "Notification Name" field
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff(".ic-Table--condensed.grid td").last).to include_text("Assignment Submitted")
        expect(ff(".ic-Table--condensed.grid td")[3]).to include_text("Submission: #{@student.name}, #{@assignment.name}")
      end

      it "shows assignment re-submitted notifications to teacher", priority: "1" do
        # Re-submit homework
        submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "hello heyy")
        submission.workflow_state = "submitted"
        submission.save!

        get "/users/#{@teacher.id}/messages"
        wait_for_ajaximations
        # Checks that the notification is there and has the correct "Notification Name" field
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff(".ic-Table--condensed.grid td").last).to include_text("Assignment Submitted")
        expect(ff(".ic-Table--condensed.grid td")[3]).to include_text("Re-Submission: #{@student.name}, #{@assignment.name}")
      end

      it "does not show the name of the reviewer for anonymous peer reviews", priority: "1" do
        @assignment.peer_reviews = true
        @assignment.anonymous_peer_reviews = true
        @assignment.save!
        @assignment.unmute!

        setup_notification(@student, name: "Submission Comment")

        reviewer = user_with_pseudonym(username: "reviewer@example.com", active_all: 1)
        enrollment = @course.enroll_user(reviewer, "StudentEnrollment")
        enrollment.accept!

        @assignment.assign_peer_review(@student, reviewer)
        submission_comment_model({ author: reviewer, submission: @assignment.find_or_create_submission(@student) })

        get "/users/#{@student.id}/messages"

        # Checks that the notification is there and has the correct "Notification Name" field
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff(".ic-Table--condensed.grid td").last).to include_text("Submission Comment")
        expect(ff(".ic-Table--condensed.grid td")[7]).to include_text("Anonymous User")

        fj('.ui-tabs-anchor:contains("Plain Text")').click
        expect(f(".message-body")).to include_text("Anonymous User just made a new comment on the " \
                                                   "submission for #{@student.reload.short_name} for assignment")
      end

      context "observer notifications" do
        before :once do
          @observer = user_with_pseudonym(username: "observer@example.com", active_all: 1)
          @course.enroll_user(@observer,
                              "ObserverEnrollment",
                              enrollment_state: "active",
                              associated_user_id: @student.id)
          setup_notification(@observer, name: "Submission Graded")
          setup_notification(@observer, name: "Submission Comment")
        end

        it "shows assignment graded notification to the observer", priority: "2" do
          @assignment.grade_student @student, grade: 2, grader: @teacher

          get "/users/#{@observer.id}/messages"

          # Checks that the notification is there and has the correct "Notification Name" field
          fj('.ui-tabs-anchor:contains("Meta Data")').click
          expect(ff(".ic-Table--condensed.grid td").last).to include_text("Submission Graded")
          expect(ff(".ic-Table--condensed.grid td")[3])
            .to include_text("Assignment Graded: #{@assignment.name}, #{@course.name}")
        end

        it "does not send assignment graded notification to observers not linked to students", priority: "2" do
          @observer2 = user_with_pseudonym(username: "observer2@example.com", active_all: 1)
          @course.enroll_user(@observer2, "ObserverEnrollment", enrollment_state: "active")
          @assignment.grade_student @student, grade: 2, grader: @teacher

          get "/users/#{@observer2.id}/messages"
          expect(f("#content")).not_to contain_css(".messages .message")
        end

        it "shows submission comment notification to the observer", priority: "2" do
          submission_comment_model({ author: @teacher, submission: @assignment.find_or_create_submission(@student) })

          get "/users/#{@observer.id}/messages"

          # Checks that the notification is there and has the correct "Notification Name" field
          fj('.ui-tabs-anchor:contains("Meta Data")').click
          expect(ff(".ic-Table--condensed.grid td").last).to include_text("Submission Comment")
          expect(ff(".ic-Table--condensed.grid td")[3])
            .to include_text("Submission Comment: #{@student.name}, #{@assignment.name}, #{@course.name}")
        end

        it "does not send submission comment notification to observers not linked to students", priority: "2" do
          @observer2 = user_with_pseudonym(username: "observer2@example.com", active_all: 1)
          @course.enroll_user(@observer2, "ObserverEnrollment", enrollment_state: "active")
          submission_comment_model({ author: @teacher, submission: @assignment.find_or_create_submission(@student) })

          get "/users/#{@observer2.id}/messages"
          expect(f("#content")).not_to contain_css(".messages .message")
        end
      end
    end

    context "Announcement notification" do
      before do
        setup_notification(@student, name: "New Announcement", category: "Announcement", sms: true)
      end

      it "shows announcement notifications to student", priority: "1" do
        @course.announcements.create!(title: "Announcement", message: "Announcement time!")
        # Checks that the notification is there and has the correct "Notification Name" field
        get "/users/#{@student.id}/messages"
        fj('.ui-tabs-anchor:contains("Meta Data")').click
        expect(ff(".ic-Table--condensed.grid td").last).to include_text("New Announcement")
        expect(ff(".ic-Table--condensed.grid td")[3]).to include_text("Announcement: #{@course.name}")
      end
    end

    context "Grading Policy notifications" do
      context "Observer notifications" do
        before :once do
          @observer = user_with_pseudonym(username: "observer@example.com", active_all: 1)
          @course.enroll_user(@observer,
                              "ObserverEnrollment",
                              enrollment_state: "active",
                              associated_user_id: @student.id)
          setup_notification(@student, name: "Grade Weight Changed")
        end

        it "shows grade chaged notifications to the observers", priority: "2" do
          @course.apply_assignment_group_weights = true
          @course.save!

          get "/users/#{@observer.id}/messages"

          # Checks that the notification is there and has the correct "Notification Name" field
          fj('.ui-tabs-anchor:contains("Meta Data")').click
          expect(ff(".ic-Table--condensed.grid td").last).to include_text("Grade Weight Changed")
          expect(ff(".ic-Table--condensed.grid td")[3])
            .to include_text("Grade Weight Changed: #{@course.name}")
        end
      end
    end

    context "Calendar Event notifications" do
      context "observer notifications" do
        before :once do
          @observer = user_with_pseudonym(username: "observer@example.com", active_all: 1)
          @course.enroll_user(@observer,
                              "ObserverEnrollment",
                              enrollment_state: "active",
                              associated_user_id: @student.id)
          setup_notification(@student, name: "New Event Created")
          setup_notification(@student, name: "Event Date Changed")
        end

        it "shows event created and updated notification to the observer", priority: "2" do
          event = make_event(title: "New Event", start_at: Time.zone.now.beginning_of_day + 6.hours)

          get "/users/#{@observer.id}/messages"

          # Checks that the notification is there and has the correct "Notification Name" field
          fj('.ui-tabs-anchor:contains("Meta Data")').click
          expect(ff(".ic-Table--condensed.grid td").last).to include_text("New Event Created")

          # update event
          event.start_at = Time.zone.now.beginning_of_day + 8.hours
          event.save!
          refresh_page

          wait_for_ajaximations
          fj('.ui-tabs-anchor:contains("Meta Data")').click
          expect(fj('.ic-Table--condensed.grid:first tr:contains("Notification Name")').text)
            .to include("Event Date Changed")
        end
      end
    end
  end
end
