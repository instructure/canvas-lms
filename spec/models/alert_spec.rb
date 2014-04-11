#
# Copyright (C) 2012 Instructure, Inc.
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

describe Alert do
  before do
    @mock_notification = Notification.new
    Notification.stubs(:by_name).returns(@mock_notification)
  end

  context "Alerts" do
    context "mass assignment" do
      it "should translate string-symbols to symbols when assigning to recipients" do
        alert = Alert.new
        alert.recipients = [':student', :teachers, 'AccountAdmin']
        alert.recipients.should == [:student, :teachers, 'AccountAdmin']
      end

      it "should accept mass assignment of criteria" do
        alert = Alert.new(:context => Account.default, :recipients => [:student])
        alert.criteria = [{:criterion_type => 'Interaction', :threshold => 1}]
        alert.criteria.length.should == 1
        alert.criteria.first.criterion_type.should == 'Interaction'
        alert.criteria.first.threshold.should == 1
        alert.save!
        original_criterion_id = alert.criteria.first.id

        alert.criteria = [{:criterion_type => 'Interaction', :threshold => 7, :id => alert.criteria.first.id},
                          {:criterion_type => 'UserNote', :threshold => 6}]
        alert.criteria.length.should == 2
        alert.criteria.first.id.should == original_criterion_id
        alert.criteria.first.threshold.should == 7
        alert.criteria.last.should be_new_record

        alert.criteria = []
        alert.criteria be_empty

        AlertCriterion.find_by_id(original_criterion_id).should be_nil
      end
    end

    context "validation" do
      it "should require a context" do
        alert = Alert.new(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        alert.save.should be_false
      end

      it "should require recipients" do
        alert = Account.default.alerts.build(:criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        alert.save.should be_false
      end

      it "should require criteria" do
        alert = Account.default.alerts.build(:recipients => [:student])
        alert.save.should be_false
      end
    end

    context "basic evaluation" do
      it "should not trigger any alerts for unpublished courses" do
        course = mock('Course')
        course.stubs(:available?, false)
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(course)
      end

      it "should not trigger any alerts for courses with no alerts" do
        course = mock('Course')
        course.stubs(:available?).returns(true)
        course.stubs(:alerts).returns(stub(:all => []))
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(course)
      end

      it "should not trigger any alerts when there are no students in the class" do
        course = Account.default.courses.create!
        course.offer!
        course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(course)
      end

      it "should not trigger any alerts when there are no teachers in the class" do
        course_with_student(:active_course => 1)
        @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

      it "should not trigger any alerts in subsequent courses" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)
        @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
        @course.start_at = Time.now - 30.days
        account_alerts = []

        Alert.evaluate_for_course(@course, account_alerts)

        account_alerts.should be_empty
      end
    end

    context 'repetition' do
      it "should not keep sending alerts when repetition is nil" do
        enable_cache do
          course_with_teacher(:active_all => 1)
          student_in_course(:active_all => 1)
          alert = @course.alerts.create!(:recipients => [:student], :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          @course.start_at = Time.now - 30.days
          @mock_notification.expects(:create_message).with(anything, [@user.id], anything).once

          Alert.evaluate_for_course(@course)
          Alert.evaluate_for_course(@course)
        end
      end

      it "should not keep sending alerts when run on the same day" do
        enable_cache do
          course_with_teacher(:active_all => 1)
          student_in_course(:active_all => 1)
          alert = @course.alerts.create!(:recipients => [:student], :repetition => 1, :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          @course.start_at = Time.now - 30.days
          @mock_notification.expects(:create_message).with(anything, [@user.id], anything).once

          Alert.evaluate_for_course(@course)
          Alert.evaluate_for_course(@course)
        end
      end

      it "should keep sending alerts for daily repetition" do
        enable_cache do
          course_with_teacher(:active_all => 1)
          student_in_course(:active_all => 1)
          alert = @course.alerts.create!(:recipients => [:student], :repetition => 1, :criteria => [{:criterion_type => 'Interaction', :threshold => 7}])
          @course.start_at = Time.now - 30.days

          @mock_notification.expects(:create_message).with(anything, [@user.id], anything).twice

          Alert.evaluate_for_course(@course)
          # update sent_at
          Rails.cache.write([alert, @user.id].cache_key, (Time.now - 1.day).beginning_of_day)
          Alert.evaluate_for_course(@course)
        end
      end
    end

    context 'interaction' do
      it "should not alert for new courses" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)
        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

      it "should alert for old courses" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)
        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

        Alert.evaluate_for_course(@course)
      end

      it "should not alert for submission comments" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@user)
        SubmissionComment.create!(:submission => @submission, :comment => 'some comment', :author => @teacher, :recipient => @user)

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

      it "should alert for old submission comments" do
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
        @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

        Alert.evaluate_for_course(@course)
      end

      it "should not alert for conversation messages" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @conversation = @teacher.initiate_conversation([@user])
        @conversation.add_message("hello")

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

      it "should alert for old conversation messages" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @conversation = @teacher.initiate_conversation([@student, user])
        message = @conversation.add_message("hello")
        message.created_at = Time.now - 30.days
        message.save!

        alert = @course.alerts.build(:recipients => [:student], :repetition => 1)
        alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        Alert.expects(:send_alert).with(anything, [ @student.id ], anything).twice

        Alert.evaluate_for_course(@course)

        # create a generated message
        @conversation.add_participants([user])
        @conversation.messages.length.should == 2

        # it should still alert, ignoring the new message
        # update sent_at so it will send again
        Rails.cache.write([alert, @student.id].cache_key, (Time.now - 5.days).beginning_of_day)
        Alert.evaluate_for_course(@course)
      end
    end

    context 'ungraded count' do
      it "should not alert for no submissions" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UngradedCount', :threshold => 1)
        alert.save!
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

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

        Alert.evaluate_for_course(@course)
      end
    end

    context 'ungraded timespan' do
      it "should not alert for no submissions" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 1)
        alert.save!
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

      it "should not alert for submission within the threshold" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@user, :body => 'body')

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
        alert.save!
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course)
      end

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

        Alert.evaluate_for_course(@course)
      end

      it "should alert for multiple submissions when one matches and one doesn't" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@user, :body => 'body')
        @submission.update_attribute(:submitted_at, Time.now - 30.days);
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @submission = @assignment.submit_homework(@user, :body => 'body')
        @submission.update_attribute(:submitted_at, Time.now - 30.days);

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
        alert.save!
        @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

        Alert.evaluate_for_course(@course)
      end
    end

    context 'user notes' do
      it "should not alert for new courses" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)
        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
        alert.save!
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course, nil, true)
      end

      it "should alert for old courses" do
        course_with_teacher(:active_all => 1)
        student_in_course(:active_all => 1)
        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

        Alert.evaluate_for_course(@course, nil, true)
      end

      it "should not alert when a note exists" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        UserNote.create!(:creator => @teacher, :user => @user)

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        Notification.any_instance.expects(:create_message).never

        Alert.evaluate_for_course(@course, nil, true)
      end

      it "should alert when an old note exists" do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }

        alert = @course.alerts.build(:recipients => [:student])
        alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
        alert.save!
        @course.start_at = Time.now - 30.days
        @mock_notification.expects(:create_message).with(anything, [@user.id], anything)

        Alert.evaluate_for_course(@course, nil, true)
      end
    end
  end

  context "notification alert info" do
    before do
      Notification.create!(:name => 'Alert')
      course_with_teacher(:active_all => 1)
      @teacher = @user
      @user = nil
      student_in_course(:active_all => 1)
      @pseudonym = mock('Pseudonym')
      @pseudonym.stubs(:destroyed?).returns(false)
      Pseudonym.stubs(:find_by_user_id).returns(@pseudonym)
      a = @user.communication_channels.create(:path => "a@example.com")
      a.confirm!
      @assignment = @course.assignments.new(:title => "some assignment")
      @assignment.workflow_state = "published"
      @assignment.save
      @submission = @assignment.submit_homework(@user, :body => 'body')
    end

    it "should tell you what the alert is about timespan" do
      @submission.update_attribute(:submitted_at, Time.now - 30.days);
      alert = @course.alerts.build(:recipients => [:student])
      alert.criteria.build(:criterion_type => 'UngradedTimespan', :threshold => 7)
      alert.save!
      @mock_notification.expects(:create_message).with do |alert, _, _|
        alert.criteria.first.criterion_type.should == 'UngradedTimespan'
      end

      Alert.evaluate_for_course(@course)
    end

    it "should tell you what the alert is about count" do
      alert = @course.alerts.build(:recipients => [:student])
      alert.criteria.build(:criterion_type => 'UngradedCount', :threshold => 1)
      alert.save!
      @mock_notification.expects(:create_message).with do |alert, _, _|
        alert.criteria.first.criterion_type.should == 'UngradedCount'
      end

      Alert.evaluate_for_course(@course)
    end

    it "should tell you what the alert is about note" do
      UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }
      alert = @course.alerts.build(:recipients => [:student])
      alert.criteria.build(:criterion_type => 'UserNote', :threshold => 7)
      alert.save!
      @course.start_at = Time.now - 30.days
      @mock_notification.expects(:create_message).with do |alert, _, _|
        alert.criteria.first.criterion_type.should == 'UserNote'
      end

      Alert.evaluate_for_course(@course, nil, true)
    end

    it "should tell you what the alert is about interaction" do
      alert = @course.alerts.build(:recipients => [:student])
      alert.criteria.build(:criterion_type => 'Interaction', :threshold => 7)
      alert.save!
      @course.start_at = Time.now - 30.days
      @mock_notification.expects(:create_message).with do |alert, _, _|
        alert.criteria.first.criterion_type.should == 'Interaction'
      end

      Alert.evaluate_for_course(@course)
    end
  end
end
