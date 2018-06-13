#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../sharding_spec_helper'

describe ObserverAlert do
  include Api
  include Api::V1::ObserverAlertThreshold

  describe 'validations' do
    before :once do
      @student = user_model
      @observer = user_model
      UserObservationLink.create(student: @student, observer: @observer)
      @threshold = ObserverAlertThreshold.create!(student: @student, observer: @observer, alert_type: 'assignment_missing')
      @assignment = assignment_model
    end

    it 'can link to a threshold and observer and student' do
      alert = ObserverAlert.create(student: @student, observer: @observer, observer_alert_threshold: @threshold,
                        context: @assignment, alert_type: 'assignment_missing', action_date: Time.zone.now,
                        title: 'Assignment missing')

      expect(alert.valid?).to eq true
      expect(alert.user_id).not_to be_nil
      expect(alert.observer_id).not_to be_nil
      expect(alert.observer_alert_threshold).not_to be_nil
    end

    it 'observer must be linked to student' do
      alert = ObserverAlert.create(student: user_model, observer: @observer, observer_alert_threshold: @threshold,
        context: @assignment, alert_type: 'assignment_missing', action_date: Time.zone.now, title: 'Assignment missing')

      expect(alert.valid?).to eq false
    end

    it 'wont allow random alert_type' do
      alert = ObserverAlert.create(student: @student, observer: @observer, observer_alert_threshold: @threshold,
        context: @assignment, alert_type: 'jigglypuff', action_date: Time.zone.now, title: 'Assignment missing')

      expect(alert.valid?).to eq false
    end
  end

  describe 'course_announcement' do
    before :once do
      @course = course_factory
      @student = student_in_course(active_all: true, course: @course).user
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      ObserverAlertThreshold.create!(student: @student, observer: @observer, alert_type: 'course_announcement')

      # user without a threshold
      @observer2 = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      @observer = observer
    end

    it 'creates an alert when a user has a threshold for course announcements' do
      a = announcement_model(:context => @course)
      alert = ObserverAlert.where(student: @student, observer: @observer).first
      expect(alert).not_to be_nil
      expect(alert.context).to eq a
      expect(alert.title).to include('Announcement posted: ')

      alert2 = ObserverAlert.where(student: @student, observer: @observer2).first
      expect(alert2).to be_nil
    end

    it 'creates an alert when the delayed announcement becomes active' do
      a = announcement_model(context: @course, delayed_post_at: Time.zone.now, workflow_state: :post_delayed)
      alert = ObserverAlert.where(student: @student, observer: @observer, context: a).first
      expect(alert).to be_nil

      a.workflow_state = 'active'
      a.save!

      alert = ObserverAlert.where(student: @student, observer: @observer, context: a).first
      expect(alert).not_to be_nil
    end
  end

  describe 'clean_up_old_alerts' do
    it 'deletes alerts older than 6 months ago but leaves newer ones' do
      observer_alert_threshold_model(alert_type: 'institution_announcement')
      a1 = ObserverAlert.create(student: @student, observer: @observer, observer_alert_threshold: @observer_alert_threshold,
                           context: @account, alert_type: 'institution_announcement', title: 'announcement',
                           action_date: Time.zone.now, created_at: 6.months.ago)
      a2 = ObserverAlert.create(student: @student, observer: @observer, observer_alert_threshold: @observer_alert_threshold,
                           context: @account, alert_type: 'institution_announcement', title: 'announcement',
                           action_date: Time.zone.now)

      ObserverAlert.clean_up_old_alerts
      expect(ObserverAlert.where(id: a1.id).first).to be_nil
      expect(ObserverAlert.find(a2.id)).not_to be_nil
    end
  end

  describe 'institution_announcement' do
    before :once do
      @no_link_account = account_model
      @student = student_in_course(active_all: true).user
      @account = @course.account
      @observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      @threshold = ObserverAlertThreshold.create!(student: @student, observer: @observer, alert_type: 'institution_announcement')
    end

    it 'doesnt create an alert if the notificaiton is not for the root account' do
      sub_account = account_model(root_account: @account, parent_account: @account)
      notification = sub_account_notification(account: sub_account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'doesnt create an alert if the start_at time is in the future' do
      notification = account_notification(start_at: 1.day.from_now, account: @account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'doesnt create an alert if the roles dont include student or observer' do
      role_ids = ["TeacherEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
      notification = account_notification(account: @account, role_ids: role_ids)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'doesnt create an alert if there are no links' do
      notification = account_notification(account: @no_link_account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it 'creates an alert for each threshold set' do
      notification = account_notification(account: @account)
      alert = ObserverAlert.where(context: notification)
      expect(alert.count).to eq 1

      expect(alert.first.context).to eq notification
    end

    it 'creates an alert if student role is selected but not observer' do
      role_ids = ["StudentEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
      notification = account_notification(account: @account, role_ids: role_ids)
      alert = ObserverAlert.where(context: notification).first
      expect(alert.context).to eq notification
    end

    it 'creates an alert if observer role is selected but not student' do
      role_ids = ["ObserverEnrollment", "AccountAdmin"].map{|name| Role.get_built_in_role(name).id}
      notification = account_notification(account: @account, role_ids: role_ids)
      alert = ObserverAlert.where(context: notification).first
      expect(alert.context).to eq notification
    end
  end

  describe 'assignment_grade' do
    before :once do
      course_with_teacher
      @threshold1 = observer_alert_threshold_model(alert_type: 'assignment_grade_high', threshold: '80', course: @course)
      @threshold2 = observer_alert_threshold_model(alert_type: 'assignment_grade_low', threshold: '40', course: @course)
      assignment_model(context: @course)
    end

    it 'doesnt create an alert if there are no observers on that student' do
      student = student_in_course(course: @course).user
      @assignment.grade_student(student, score: 50, grader: @teacher)

      alerts = ObserverAlert.where(context: @assignment)
      expect(alerts.count).to eq 0
    end

    it 'doesnt create an alert if there is no threshold for that observer' do
      student = student_in_course(course: @course).user
      course_with_observer(course: @course, associated_user_id: student.id)

      @assignment.grade_student(student, score: 80, grader: @teacher)

      alerts = ObserverAlert.where(context: @assignment)
      expect(alerts.count).to eq 0
    end

    it 'doesnt create an alert if the threshold is not met' do
      @assignment.grade_student(@threshold1.student, score: 70, grader: @teacher)
      @assignment.grade_student(@threshold2.student, score: 50, grader: @teacher)

      alerts = ObserverAlert.where(context: @assignment)
      expect(alerts.count).to eq 0
    end

    it 'creates an alert if the threshold is met' do
      @course.enroll_user(@threshold1.student, 'StudentEnrollment')
      @course.enroll_user(@threshold2.student, 'StudentEnrollment')

      @assignment.grade_student(@threshold1.student, score: 100, grader: @teacher)
      @assignment.grade_student(@threshold2.student, score: 10, grader: @teacher)

      alert1 = ObserverAlert.where(context: @assignment, alert_type: 'assignment_grade_high').first
      expect(alert1).not_to be_nil
      expect(alert1.observer_alert_threshold).to eq @threshold1
      expect(alert1.title).to include('Assignment graded: ')

      alert2 = ObserverAlert.where(context: @assignment, alert_type: 'assignment_grade_low').first
      expect(alert2).not_to be_nil
      expect(alert2.observer_alert_threshold).to eq @threshold2
      expect(alert2.title).to include('Assignment graded: ')
    end
  end
end
