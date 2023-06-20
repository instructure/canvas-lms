# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Alerts
  describe DelayedAlertSender do
    describe "scoped to unit" do
      before do
        @mock_notification = Notification.new
        allow(BroadcastPolicy).to receive(:notification_finder).and_return(double(by_name: @mock_notification))
      end

      context "basic evaluation" do
        it "does not trigger any alerts for unpublished courses" do
          course = double("Course", available?: false)
          expect_any_instance_of(Notification).not_to receive(:create_message)

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "does not trigger any alerts for courses with no alerts" do
          course = double("Course", available?: true, alerts: [])
          expect_any_instance_of(Notification).not_to receive(:create_message)

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "does not trigger any alerts when there are no students in the class" do
          course = Account.default.courses.create!
          course.offer!
          course.alerts.create!(recipients: [:student], criteria: [{ criterion_type: "Interaction", threshold: 7 }])
          expect_any_instance_of(Notification).not_to receive(:create_message)

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "does not trigger any alerts when there are no teachers in the class" do
          course_with_student(active_course: true)
          @course.alerts.create!(recipients: [:student], criteria: [{ criterion_type: "Interaction", threshold: 7 }])
          expect_any_instance_of(Notification).not_to receive(:create_message)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "does not trigger any alerts in subsequent courses" do
          course_with_teacher(active_all: true)
          student_in_course(active_all: true)
          @course.alerts.create!(recipients: [:student], criteria: [{ criterion_type: "Interaction", threshold: 7 }])
          @course.start_at = 30.days.ago
          account_alerts = []

          DelayedAlertSender.evaluate_for_course(@course, account_alerts)

          expect(account_alerts).to eq []
        end

        it "does not trigger to rejected teacher enrollments" do
          course_with_teacher(active_course: true)
          student_in_course(active_all: true)
          @teacher.enrollments.first.reject!
          @course.alerts.create!(
            recipients: [:teachers],
            criteria: [{ criterion_type: "Interaction", threshold: 7 }]
          )
          @course.reload
          @course.start_at = 30.days.ago

          expect_any_instance_of(Notification).not_to receive(:create_message)
          DelayedAlertSender.evaluate_for_course(@course, [])
        end

        it "does not trigger to rejected student enrollments" do
          course_with_teacher(active_course: true)
          student_in_course(active_all: true)
          @student.enrollments.first.reject!
          @course.alerts.create!(
            recipients: [:teachers],
            criteria: [{ criterion_type: "Interaction", threshold: 7 }]
          )
          @course.reload
          @course.start_at = 30.days.ago

          expect_any_instance_of(Notification).not_to receive(:create_message)
          DelayedAlertSender.evaluate_for_course(@course, [])
        end
      end

      context "repetition" do
        it "does not keep sending alerts when repetition is nil" do
          enable_cache do
            course_with_teacher(active_all: 1)
            student_in_course(active_all: 1)
            @course.alerts.create!(recipients: [:student], criteria: [{ criterion_type: "Interaction", threshold: 7 }])
            @course.start_at = 30.days.ago
            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything).once

            DelayedAlertSender.evaluate_for_course(@course, nil)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "does not keep sending alerts when run on the same day" do
          enable_cache do
            course_with_teacher(active_all: 1)
            student_in_course(active_all: 1)
            @course.alerts.create!(recipients: [:student], repetition: 1, criteria: [{ criterion_type: "Interaction", threshold: 7 }])
            @course.start_at = 30.days.ago
            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything).once

            DelayedAlertSender.evaluate_for_course(@course, nil)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "keeps sending alerts for daily repetition" do
          enable_cache do
            course_with_teacher(active_all: 1)
            student_in_course(active_all: 1)
            alert = @course.alerts.create!(recipients: [:student], repetition: 1, criteria: [{ criterion_type: "Interaction", threshold: 7 }])
            @course.start_at = 30.days.ago

            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything).twice

            DelayedAlertSender.evaluate_for_course(@course, nil)
            # update sent_at
            Rails.cache.write([alert, @user.id].cache_key, 1.day.ago.beginning_of_day)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end
      end

      context "interaction" do
        it "alerts" do
          course_with_teacher(active_all: 1)
          student_in_course(active_all: 1)
          alert = @course.alerts.build(recipients: [:student])
          alert.criteria.build(criterion_type: "Interaction", threshold: 7)
          alert.save!
          @course.start_at = 30.days.ago
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      it "memoizes alert checker creation" do
        course_with_teacher(active_all: 1)
        @teacher = @user
        @user = nil
        student_in_course(active_all: 1)
        @assignment = @course.assignments.new(title: "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@user)
        SubmissionComment.create!(submission: @submission, comment: "some comment", author: @teacher) do |sc|
          sc.created_at = 30.days.ago
        end

        alert = @course.alerts.build(recipients: [:student])
        alert.criteria.build(criterion_type: "Interaction", threshold: 7)
        alert.save!
        @course.start_at = 30.days.ago

        mock_interaction = double(should_not_receive_message?: true)
        expect(Alerts::Interaction).to receive(:new).once.and_return(mock_interaction)

        DelayedAlertSender.evaluate_for_course(@course, [alert])
      end

      context "ungraded count" do
        it "alerts" do
          course_with_teacher(active_all: 1)
          @teacher = @user
          @user = nil
          student_in_course(active_all: 1)
          @assignment = @course.assignments.new(title: "some assignment")
          @assignment.workflow_state = "published"
          @assignment.save
          @submission = @assignment.submit_homework(@user, body: "body")

          alert = @course.alerts.build(recipients: [:student])
          alert.criteria.build(criterion_type: "UngradedCount", threshold: 1)
          alert.save!
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      context "ungraded timespan" do
        it "alerts" do
          course_with_teacher(active_all: 1)
          @teacher = @user
          @user = nil
          student_in_course(active_all: 1)
          @assignment = @course.assignments.new(title: "some assignment")
          @assignment.workflow_state = "published"
          @assignment.save
          @submission = @assignment.submit_homework(@user, body: "body")
          @submission.update_attribute(:submitted_at, 30.days.ago)

          alert = @course.alerts.build(recipients: [:student])
          alert.criteria.build(criterion_type: "UngradedTimespan", threshold: 7)
          alert.save!
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      context "user notes" do
        context "when the deprecate_faculty_journal flag is disabled" do
          before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

          it "alerts" do
            course_with_teacher(active_all: 1)
            root_account = @course.root_account
            root_account.enable_user_notes = true
            root_account.save!

            student_in_course(active_all: 1)
            alert = @course.alerts.build(recipients: [:student])
            alert.criteria.build(criterion_type: "UserNote", threshold: 7)
            alert.save!
            @course.start_at = 30.days.ago
            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        context "when the deprecate_faculty_journal flag is enabled" do
          it "does not alert" do
            course_with_teacher(active_all: 1)
            root_account = @course.root_account
            root_account.enable_user_notes = true
            root_account.save!

            student_in_course(active_all: 1)
            alert = @course.alerts.build(recipients: [:student])
            alert.criteria.build(criterion_type: "UserNote", threshold: 7)
            alert.save!
            @course.start_at = 30.days.ago
            expect(@mock_notification).to_not receive(:create_message).with(anything, [@user.id], anything)

            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end
      end

      context "notification alert info" do
        before :once do
          Notification.create!(name: "Alert")
          course_with_teacher(active_all: 1)
          @teacher = @user
          @user = nil
          student_in_course(active_all: 1)
          communication_channel(@user, { username: "a@example.com", active_cc: true })
          @assignment = @course.assignments.new(title: "some assignment")
          @assignment.workflow_state = "published"
          @assignment.save
          @submission = @assignment.submit_homework(@user, body: "body")
        end

        before do
          @pseudonym = double("Pseudonym")
          allow(@pseudonym).to receive(:destroyed?).and_return(false)
          allow(Pseudonym).to receive(:find_by_user_id).and_return(@pseudonym)
        end

        it "tells you what the alert is about timespan" do
          @submission.update_attribute(:submitted_at, 30.days.ago)
          alert = @course.alerts.build(recipients: [:student])
          alert.criteria.build(criterion_type: "UngradedTimespan", threshold: 7)
          alert.save!
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq "UngradedTimespan"
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "tells you what the alert is about count" do
          alert = @course.alerts.build(recipients: [:student])
          alert.criteria.build(criterion_type: "UngradedCount", threshold: 1)
          alert.save!
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq "UngradedCount"
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        context "when the deprecate_faculty_journal flag is disabled" do
          before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

          it "tells you what the alert is about note" do
            root_account = @course.root_account
            root_account.enable_user_notes = true
            root_account.save!

            ::UserNote.create!(creator: @teacher, user: @user, root_account_id: root_account.id) { |un| un.created_at = 30.days.ago }
            alert = @course.alerts.build(recipients: [:student])
            alert.criteria.build(criterion_type: "UserNote", threshold: 7)
            alert.save!
            @course.start_at = 30.days.ago
            expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
              expect(alert_in.criteria.first.criterion_type).to eq "UserNote"
            end

            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "tells you what the alert is about interaction" do
          alert = @course.alerts.build(recipients: [:student])
          alert.criteria.build(criterion_type: "Interaction", threshold: 7)
          alert.save!
          @course.start_at = 30.days.ago
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq "Interaction"
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end
    end

    it "works end to end" do
      Notification.create(name: "Alert")

      course_with_teacher(active_all: 1)
      student_in_course(active_all: 1)
      communication_channel(@student, { username: "student@example.com", active_cc: true })
      alert = @course.alerts.build(recipients: [:student])
      alert.criteria.build(criterion_type: "Interaction", threshold: 7)
      alert.save!
      @course.start_at = 30.days.ago

      expect do
        DelayedAlertSender.evaluate_for_course(@course, nil)
      end.to change(DelayedMessage, :count).by(1)
    end

    it "does not create delayed messages when suppress_notifications = true" do
      Account.default.settings[:suppress_notifications] = true
      Account.default.save!
      Notification.create(name: "Alert")

      course_with_teacher(active_all: 1)
      student_in_course(active_all: 1)
      communication_channel(@student, { username: "student@example.com", active_cc: true })
      alert = @course.alerts.build(recipients: [:student])
      alert.criteria.build(criterion_type: "Interaction", threshold: 7)
      alert.save!
      @course.start_at = 30.days.ago
      expect do
        DelayedAlertSender.evaluate_for_course(@course, nil)
      end.not_to change(DelayedMessage, :count)
    end
  end
end
