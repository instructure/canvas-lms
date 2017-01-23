#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper.rb')
require_dependency "alerts/delayed_alert_sender"

module Alerts
  describe DelayedAlertSender do

    describe "scoped to unit" do
      before do
        @mock_notification = Notification.new
        allow(BroadcastPolicy).to receive(:notification_finder).and_return(double(by_name: @mock_notification))
      end

      context "basic evaluation" do
        it "should not trigger any alerts for unpublished courses" do
          course = double('Course', :available? => false)
          expect_any_instance_of(Notification).to receive(:create_message).never

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "should not trigger any alerts for courses with no alerts" do
          course = double('Course', :available? => true, :alerts => [])
          expect_any_instance_of(Notification).to receive(:create_message).never

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "should not trigger any alerts when there are no students in the class" do
          course = Account.default.courses.create!
          course.offer!
          course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          expect_any_instance_of(Notification).to receive(:create_message).never

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "should not trigger any alerts when there are no teachers in the class" do
          course_with_student(:active_course => true)
          @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          expect_any_instance_of(Notification).to receive(:create_message).never

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should not trigger any alerts in subsequent courses" do
          course_with_teacher(:active_all => true)
          student_in_course(:active_all => true)
          @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          @course.start_at = Time.zone.now - 30.days
          account_alerts = []

          DelayedAlertSender.evaluate_for_course(@course, account_alerts)

          expect(account_alerts).to eq []
        end

        it "should not trigger to rejected teacher enrollments" do
          course_with_teacher(:active_course => true)
          student_in_course(:active_all => true)
          @teacher.enrollments.first.reject!
          @course.alerts.create!(
            :recipients => [:teachers],
            :criteria => [{:criterion_type => 'Interaction', :threshold => 7}]
          )
          @course.reload
          @course.start_at = Time.zone.now - 30.days

          expect_any_instance_of(Notification).to receive(:create_message).never
          DelayedAlertSender.evaluate_for_course(@course, [])
        end

        it "should not trigger to rejected student enrollments" do
          course_with_teacher(:active_course => true)
          student_in_course(:active_all => true)
          @student.enrollments.first.reject!
          @course.alerts.create!(
            :recipients => [:teachers],
            :criteria => [{:criterion_type => 'Interaction', :threshold => 7}]
          )
          @course.reload
          @course.start_at = Time.zone.now - 30.days

          expect_any_instance_of(Notification).to receive(:create_message).never
          DelayedAlertSender.evaluate_for_course(@course, [])
        end
      end

      context 'repetition' do
        it "should not keep sending alerts when repetition is nil" do
          enable_cache do
            course_with_teacher(:active_all => 1)
            student_in_course(:active_all => 1)
            @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
            @course.start_at = Time.zone.now - 30.days
            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything).once

            DelayedAlertSender.evaluate_for_course(@course, nil)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "should not keep sending alerts when run on the same day" do
          enable_cache do
            course_with_teacher(:active_all => 1)
            student_in_course(:active_all => 1)
            @course.alerts.create!(:recipients => [:student], :repetition => 1, :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
            @course.start_at = Time.zone.now - 30.days
            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything).once

            DelayedAlertSender.evaluate_for_course(@course, nil)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "should keep sending alerts for daily repetition" do
          enable_cache do
            course_with_teacher(:active_all => 1)
            student_in_course(:active_all => 1)
            alert = @course.alerts.create!(:recipients => [:student], :repetition => 1, :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
            @course.start_at = Time.zone.now - 30.days

            expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything).twice

            DelayedAlertSender.evaluate_for_course(@course, nil)
            # update sent_at
            Rails.cache.write([alert, @user.id].cache_key, (Time.zone.now - 1.day).beginning_of_day)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end
      end

      context 'interaction' do
        it "should alert" do
          course_with_teacher(:active_all => 1)
          student_in_course(:active_all => 1)
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
          alert.save!
          @course.start_at = Time.zone.now - 30.days
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      it "memoizes alert checker creation" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@user)
        SubmissionComment.create!(:submission => @submission, :comment => 'some comment', :author => @teacher) do |sc|
          sc.created_at = Time.zone.now - 30.days
        end

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        @course.start_at = Time.zone.now - 30.days

        mock_interaction = double(should_not_receive_message?: true)
        expect(Alerts::Interaction).to receive(:new).once.and_return(mock_interaction)

        DelayedAlertSender.evaluate_for_course(@course, [alert])
      end

      context 'ungraded count' do
        it "should alert" do
          course_with_teacher(:active_all => 1)
          @teacher = @user
          @user = nil
          student_in_course(:active_all => 1)
          @assignment = @course.assignments.new(:title => "some assignment")
          @assignment.workflow_state = "published"
          @assignment.save
          @submission = @assignment.submit_homework(@user, :body => 'body')

          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedCount', :threshold => 1)
          alert.save!
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      context 'ungraded timespan' do

        it "should alert" do
          course_with_teacher(:active_all => 1)
          @teacher = @user
          @user = nil
          student_in_course(:active_all => 1)
          @assignment = @course.assignments.new(:title => "some assignment")
          @assignment.workflow_state = "published"
          @assignment.save
          @submission = @assignment.submit_homework(@user, :body => 'body')
          @submission.update_attribute(:submitted_at, Time.zone.now - 30.days)

          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
          alert.save!
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      context 'user notes' do
        it "should alert" do
          course_with_teacher(:active_all => 1)
          root_account = @course.root_account
          root_account.enable_user_notes = true
          root_account.save!

          student_in_course(:active_all => 1)
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
          alert.save!
          @course.start_at = Time.zone.now - 30.days
          expect(@mock_notification).to receive(:create_message).with(anything, [@user.id], anything)

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end

      context "notification alert info" do
        before :once do
          Notification.create!(:name => 'Alert')
          course_with_teacher(:active_all => 1)
          @teacher = @user
          @user = nil
          student_in_course(:active_all => 1)
          a = @user.communication_channels.create(:path => "a@example.com")
          a.confirm!
          @assignment = @course.assignments.new(:title => "some assignment")
          @assignment.workflow_state = "published"
          @assignment.save
          @submission = @assignment.submit_homework(@user, :body => 'body')
        end

        before :each do
          @pseudonym = mock('Pseudonym')
          allow(@pseudonym).to receive(:destroyed?).and_return(false)
          allow(Pseudonym).to receive(:find_by_user_id).and_return(@pseudonym)
        end

        it "should tell you what the alert is about timespan" do
          @submission.update_attribute(:submitted_at, Time.zone.now - 30.days)
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
          alert.save!
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq 'UngradedTimespan'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should tell you what the alert is about count" do
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedCount', :threshold => 1)
          alert.save!
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq 'UngradedCount'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should tell you what the alert is about note" do
          root_account = @course.root_account
          root_account.enable_user_notes = true
          root_account.save!

          ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.zone.now - 30.days }
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
          alert.save!
          @course.start_at = Time.zone.now - 30.days
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq 'UserNote'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should tell you what the alert is about interaction" do
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
          alert.save!
          @course.start_at = Time.zone.now - 30.days
          expect(@mock_notification).to receive(:create_message) do |alert_in, _, _|
            expect(alert_in.criteria.first.criterion_type).to eq 'Interaction'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end
    end

    it "should work end to end" do
      Notification.create(:name => "Alert")

      course_with_teacher(:active_all => 1)
      student_in_course(:active_all => 1)
      @student.communication_channels.create(:path => "student@example.com").confirm!
      alert = @course.alerts.build(:recipients => [:student])
      alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
      alert.save!
      @course.start_at = Time.zone.now - 30.days

      expect {
        DelayedAlertSender.evaluate_for_course(@course, nil)
      }.to change(DelayedMessage, :count).by(1)
    end
  end
end
