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

module Alerts
  describe DelayedAlertSender do

    describe "scoped to unit" do
      before do
        @mock_notification = Notification.new
        BroadcastPolicy.stubs(notification_finder: stub(by_name: @mock_notification))
      end

      context "basic evaluation" do
        it "should not trigger any alerts for unpublished courses" do
          course = mock('Course')
          course.stubs(:available?, false)
          Notification.any_instance.expects(:create_message).never

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "should not trigger any alerts for courses with no alerts" do
          course = mock('Course')
          course.stubs(:available?).returns(true)
          course.stubs(:alerts).returns(stub(:all => []))
          Notification.any_instance.expects(:create_message).never

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "should not trigger any alerts when there are no students in the class" do
          course = Account.default.courses.create!
          course.offer!
          course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          Notification.any_instance.expects(:create_message).never

          DelayedAlertSender.evaluate_for_course(course, nil)
        end

        it "should not trigger any alerts when there are no teachers in the class" do
          course_with_student(:active_course => 1)
          @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          Notification.any_instance.expects(:create_message).never

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should not trigger any alerts in subsequent courses" do
          course_with_teacher(:active_all => 1)
          student_in_course(:active_all => 1)
          @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          @course.start_at = Time.now - 30.days
          account_alerts = []

          DelayedAlertSender.evaluate_for_course(@course, account_alerts)

          account_alerts.should == []
        end
      end

      context 'repetition' do
        it "should not keep sending alerts when repetition is nil" do
          enable_cache do
            course_with_teacher(:active_all => 1)
            student_in_course(:active_all => 1)
            @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
            @course.start_at = Time.now - 30.days
            @mock_notification.expects(:create_message).with(anything, [@user.id], anything).once

            DelayedAlertSender.evaluate_for_course(@course, nil)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "should not keep sending alerts when run on the same day" do
          enable_cache do
            course_with_teacher(:active_all => 1)
            student_in_course(:active_all => 1)
            @course.alerts.create!(:recipients => [:student], :repetition => 1, :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
            @course.start_at = Time.now - 30.days
            @mock_notification.expects(:create_message).with(anything, [@user.id], anything).once

            DelayedAlertSender.evaluate_for_course(@course, nil)
            DelayedAlertSender.evaluate_for_course(@course, nil)
          end
        end

        it "should keep sending alerts for daily repetition" do
          enable_cache do
            course_with_teacher(:active_all => 1)
            student_in_course(:active_all => 1)
            alert = @course.alerts.create!(:recipients => [:student], :repetition => 1, :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
            @course.start_at = Time.now - 30.days

            @mock_notification.expects(:create_message).with(anything, [@user.id], anything).twice

            DelayedAlertSender.evaluate_for_course(@course, nil)
            # update sent_at
            Rails.cache.write([alert, @user.id].cache_key, (Time.now - 1.day).beginning_of_day)
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
          @course.start_at = Time.now - 30.days
          @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

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
        SubmissionComment.create!(:submission => @submission, :comment => 'some comment', :author => @teacher, :recipient => @user) do |sc|
          sc.created_at = Time.now - 30.days
        end

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days

        mock_interaction = stub(should_not_receive_message?: true)
        Alerts::Interaction.expects(:new).once.returns(mock_interaction)

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
          @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

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
          @submission.update_attribute(:submitted_at, Time.now - 30.days);

          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
          alert.save!
          @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

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
          @course.start_at = Time.now - 30.days
          @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

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
          @pseudonym.stubs(:destroyed?).returns(false)
          Pseudonym.stubs(:find_by_user_id).returns(@pseudonym)
        end

        it "should tell you what the alert is about timespan" do
          @submission.update_attribute(:submitted_at, Time.now - 30.days);
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
          alert.save!
          @mock_notification.expects(:create_message).with do |alert, _, _|
            alert.criteria.first.criterion_type.should == 'UngradedTimespan'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should tell you what the alert is about count" do
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UngradedCount', :threshold => 1)
          alert.save!
          @mock_notification.expects(:create_message).with do |alert, _, _|
            alert.criteria.first.criterion_type.should == 'UngradedCount'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should tell you what the alert is about note" do
          root_account = @course.root_account
          root_account.enable_user_notes = true
          root_account.save!

          ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
          alert.save!
          @course.start_at = Time.now - 30.days
          @mock_notification.expects(:create_message).with do |alert, _, _|
            alert.criteria.first.criterion_type.should == 'UserNote'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end

        it "should tell you what the alert is about interaction" do
          alert = @course.alerts.build(:recipients => [:student])
          alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
          alert.save!
          @course.start_at = Time.now - 30.days
          @mock_notification.expects(:create_message).with do |alert, _, _|
            alert.criteria.first.criterion_type.should == 'Interaction'
          end

          DelayedAlertSender.evaluate_for_course(@course, nil)
        end
      end
    end

    it "should work end to end" do
      Notification.unstub(:by_name)
      Notification.create(:name => "Alert")

      course_with_teacher(:active_all => 1)
      student_in_course(:active_all => 1)
      @student.communication_channels.create(:path => "student@example.com").confirm!
      alert = @course.alerts.build(:recipients => [:student])
      alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
      alert.save!
      @course.start_at = Time.now - 30.days

      expect {
        DelayedAlertSender.evaluate_for_course(@course, nil)
      }.to change(DelayedMessage, :count).by(1)
    end
  end
end
