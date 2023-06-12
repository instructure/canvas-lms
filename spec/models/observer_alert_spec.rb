# frozen_string_literal: true

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

describe ObserverAlert do
  include Api
  include Api::V1::ObserverAlertThreshold

  describe "validations" do
    before :once do
      @student = user_model
      @observer = user_model
      add_linked_observer(@student, @observer)
      @threshold = ObserverAlertThreshold.create!(student: @student, observer: @observer, alert_type: "assignment_missing")
      @assignment = assignment_model
    end

    it "can link to a threshold and observer and student" do
      alert = ObserverAlert.create(student: @student,
                                   observer: @observer,
                                   observer_alert_threshold: @threshold,
                                   context: @assignment,
                                   alert_type: "assignment_missing",
                                   action_date: Time.zone.now,
                                   title: "Assignment missing")

      expect(alert.valid?).to be true
      expect(alert.user_id).not_to be_nil
      expect(alert.observer_id).not_to be_nil
      expect(alert.observer_alert_threshold).not_to be_nil
    end

    it "observer must be linked to student" do
      alert = ObserverAlert.create(student: user_model,
                                   observer: @observer,
                                   observer_alert_threshold: @threshold,
                                   context: @assignment,
                                   alert_type: "assignment_missing",
                                   action_date: Time.zone.now,
                                   title: "Assignment missing")

      expect(alert.valid?).to be false
    end

    it "wont allow random alert_type" do
      alert = ObserverAlert.create(student: @student,
                                   observer: @observer,
                                   observer_alert_threshold: @threshold,
                                   context: @assignment,
                                   alert_type: "jigglypuff",
                                   action_date: Time.zone.now,
                                   title: "Assignment missing")

      expect(alert.valid?).to be false
    end
  end

  describe "course_grade alerts" do
    before :once do
      course_with_teacher
      observer_alert_threshold_model(course: @course, alert_type: "course_grade_low", threshold: 50)
      @threshold1 = observer_alert_threshold_model(course: @course, alert_type: "course_grade_high", threshold: 80)
      @student1 = @student
      @enrollment1 = @student1.enrollments.where(course: @course).first

      @threshold2 = observer_alert_threshold_model(course: @course, alert_type: "course_grade_low", threshold: 30)
      @student2 = @student
      @enrollment2 = @student2.enrollments.where(course: @course).first

      @assignment = assignment_model(context: @course, points_possible: 100)
    end

    it "doesnt create an alert if the threshold isnt met" do
      @assignment.grade_student(@student1, score: 70, grader: @teacher)
      @assignment.grade_student(@student2, score: 40, grader: @teacher)
      alerts = ObserverAlert.where(context: @course)
      expect(alerts.count).to eq 0
    end

    it "creates an alert if the threshold is met" do
      @assignment.grade_student(@student1, score: 90, grader: @teacher)
      @assignment.grade_student(@student2, score: 20, grader: @teacher)

      alert1 = ObserverAlert.where(observer_alert_threshold: @threshold1).first
      alert2 = ObserverAlert.where(observer_alert_threshold: @threshold2).first

      expect(alert1).not_to be_nil
      expect(alert2).not_to be_nil

      expect(alert1.title).to include("Course grade: ")
      expect(alert2.title).to include("Course grade: ")
    end

    it "creates only one alert per student if the student is enrolled in multiple sections per course" do
      Enrollment.create!(
        course_section: @course.course_sections.create!,
        type: "StudentEnrollment",
        user_id: @student1.id,
        course: @course,
        workflow_state: "active"
      )
      @assignment.grade_student(@student1, score: 90, grader: @teacher)
      expect(
        ObserverAlert.where(observer_alert_threshold: @threshold1, user_id: @student1.id).count
      ).to equal(1)
    end

    it "doesnt create an alert if the old score was already above the threshold" do
      @assignment.grade_student(@student1, score: 100, grader: @teacher)
      @assignment.grade_student(@student2, score: 0, grader: @teacher)

      alert1 = ObserverAlert.where(observer_alert_threshold: @threshold1)
      alert2 = ObserverAlert.where(observer_alert_threshold: @threshold2)

      expect(alert1.count).to eq 1
      expect(alert2.count).to eq 1
    end

    it "doesnt create an alert for courses the user is not enrolled in" do
      course_with_teacher
      course_with_student(course: @course)
      assignment = assignment_model(context: @course, points_possible: 100)

      course_with_student(user: @student)
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user

      ObserverAlertThreshold.create(observer:, student: @student, alert_type: "course_grade_high", threshold: 80)

      assignment.grade_student(@student, score: 100, grader: @teacher)

      expect(ObserverAlert.where(student: @student).count).to eq 0
    end
  end

  describe "course_announcement" do
    before :once do
      @course = course_factory(active_all: true)
      @student = student_in_course(active_all: true, course: @course).user
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      ObserverAlertThreshold.create!(student: @student, observer: @observer, alert_type: "course_announcement")

      # user without a threshold
      @observer2 = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      @observer = observer
    end

    it "creates an alert in a job when a user has a threshold for course announcements" do
      a = announcement_model(context: @course)
      run_jobs

      alert1 = ObserverAlert.where(student: @student, observer: @observer)
      expect(alert1.count).to eq 1
      alert = alert1.first
      expect(alert).not_to be_nil
      expect(alert.context).to eq a
      expect(alert.title).to include("Course announcement: ")

      alert2 = ObserverAlert.where(student: @student, observer: @observer2).first
      expect(alert2).to be_nil
    end

    it "creates an alert when the delayed announcement becomes active" do
      a = announcement_model(context: @course, delayed_post_at: Time.zone.now, workflow_state: :post_delayed)
      alert = ObserverAlert.where(student: @student, observer: @observer, context: a).first
      expect(alert).to be_nil

      a.workflow_state = "active"
      a.save!
      run_jobs

      alert = ObserverAlert.where(student: @student, observer: @observer, context: a).first
      expect(alert).not_to be_nil
    end

    it "creates an alert for each student" do
      student1 = student_in_course(active_all: true, course: @course).user
      student2 = student_in_course(active_all: true, course: @course).user
      observer = course_with_observer(course: @course, associated_user_id: student1.id, active_all: true).user
      course_with_observer(user: observer, course: @course, associated_user_id: student2.id, active_all: true).user
      ObserverAlertThreshold.create!(student: student1, observer:, alert_type: "course_announcement")
      ObserverAlertThreshold.create!(student: student2, observer:, alert_type: "course_announcement")

      a = announcement_model(context: @course)
      run_jobs

      alert1 = ObserverAlert.where(student: student1, observer:, context: a)
      alert2 = ObserverAlert.where(student: student2, observer:, context: a)

      expect(alert1.count).to eq 1
      expect(alert2.count).to eq 1
    end

    it "does not create an alert if the course is unpublished" do
      @course.claim!
      announcement_model(context: @course)
      run_jobs
      alerts = ObserverAlert.where(student: @student, observer: @observer)
      expect(alerts.count).to eq 0
    end

    it "creates alerts only for observers in sections where the announcement is created" do
      @section1 = @course.default_section
      @section2 = @course.course_sections.create!

      Announcement.create!(
        message: "Just for section 2",
        context: @course,
        workflow_state: "published",
        is_section_specific: true,
        course_sections: [@section2]
      )
      run_jobs
      alerts = ObserverAlert.where(student: @student, observer: @observer)
      expect(alerts.count).to eq 0

      Announcement.create!(
        message: "Just for section 1",
        context: @course,
        workflow_state: "published",
        is_section_specific: true,
        course_sections: [@section1]
      )
      run_jobs
      expect(alerts.count).to eq 1
    end
  end

  describe "clean_up_old_alerts" do
    it "deletes alerts older than 6 months ago but leaves newer ones" do
      observer_alert_threshold_model(alert_type: "institution_announcement")
      a1 = ObserverAlert.create(student: @student,
                                observer: @observer,
                                observer_alert_threshold: @observer_alert_threshold,
                                context: @account,
                                alert_type: "institution_announcement",
                                title: "announcement",
                                action_date: Time.zone.now,
                                created_at: 6.months.ago)
      a2 = ObserverAlert.create(student: @student,
                                observer: @observer,
                                observer_alert_threshold: @observer_alert_threshold,
                                context: @account,
                                alert_type: "institution_announcement",
                                title: "announcement",
                                action_date: Time.zone.now)

      ObserverAlert.clean_up_old_alerts
      expect(ObserverAlert.where(id: a1.id).first).to be_nil
      expect(ObserverAlert.find(a2.id)).not_to be_nil
    end
  end

  describe "create_assignment_missing_alerts" do
    before :once do
      @course = course_factory
      @student1 = student_in_course(active_all: true, course: @course).user
      @observer1 = course_with_observer(course: @course, associated_user_id: @student1.id, active_all: true).user
      observer_alert_threshold_model(student: @student1, observer: @observer1, alert_type: "assignment_missing")
      observer_alert_threshold_model(student: @student1, observer: @observer1, alert_type: "course_announcement")

      @student2 = student_in_course(active_all: true, course: @course).user
      @observer2 = course_with_observer(course: @course, associated_user_id: @student2.id, active_all: true).user
      @link2 = add_linked_observer(@student2, @observer2)

      assignment_model(context: @course, due_at: 5.minutes.ago, submission_types: "online_text_entry")
      @student3 = student_in_course(active_all: true, course: @course).user
      @observer3 = course_with_observer(course: @course, associated_user_id: @student3.id, active_all: true).user
      observer_alert_threshold_model(student: @student3, observer: @observer3, alert_type: "assignment_missing")
      @assignment.submit_homework(@student3, submission_type: "online_text_entry", body: "done")

      # student with multiple observers
      @student4 = student_in_course(active_all: true, course: @course).user
      @observer4 = course_with_observer(course: @course, associated_user_id: @student4.id, active_all: true).user
      @observer5 = course_with_observer(course: @course, associated_user_id: @student4.id, active_all: true).user
      observer_alert_threshold_model(student: @student4, observer: @observer4, alert_type: "assignment_missing")
      observer_alert_threshold_model(student: @student4, observer: @observer5, alert_type: "assignment_missing")

      ObserverAlert.create_assignment_missing_alerts
    end

    it "creates an assignment_missing_alert" do
      alerts = ObserverAlert.active.where(student: @student1, alert_type: "assignment_missing")
      expect(alerts.count).to eq 1
      alert = alerts.first
      expect(alert.alert_type).to eq "assignment_missing"
      expect(alert.context.user).to eq @student1
      expect(alert.title).to include("Assignment missing:")
    end

    it "deletes the alert if the submission is deleted" do
      submission = ObserverAlert.active.where(student: @student1, alert_type: "assignment_missing").first.context
      expect { submission.destroy }.to change { ObserverAlert.count }.by(-1)
    end

    it "doesnt create another alert if one already exists" do
      alert = ObserverAlert.active.where(student: @student2, alert_type: "assignment_missing").first
      expect(alert).to be_nil
    end

    it "doesnt create an alert if the submission is not missing" do
      alert = ObserverAlert.where(student: @student3, alert_type: "assignment_missing").first
      expect(alert).to be_nil
    end

    it "doesnt create an alert if there is no threshold" do
      alert = ObserverAlert.where(student: @student2).first

      expect(alert).to be_nil
    end

    it "doesnt create an alert if the assignment is not published" do
      @course = course_factory
      @student = student_in_course(active_all: true, course: @course).user
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      ObserverAlertThreshold.create(observer:, student: @student, alert_type: "assignment_missing")
      assignment_model(context: @course, due_at: 5.minutes.ago, submission_types: "online_text_entry", workflow_state: "unpublished")

      ObserverAlert.create_assignment_missing_alerts

      expect(ObserverAlert.where(student: @student).count).to eq 0
    end

    it "creates an alert for each observer" do
      alert1 = ObserverAlert.active.where(student: @student4, alert_type: "assignment_missing", observer: @observer4)
      alert2 = ObserverAlert.active.where(student: @student4, alert_type: "assignment_missing", observer: @observer5)
      expect(alert1.count).to eq 1
      expect(alert2.count).to eq 1
    end

    it "only sends alerts for assignment_missing" do
      alerts = ObserverAlert.active.where(student: @student1, alert_type: "course_announcement", observer: @observer1)
      expect(alerts).to be_empty
    end

    it "doesnt create an assignment_missing alert for courses the observer is not in" do
      # course with just the student
      course_with_teacher
      course_with_student(course: @course)
      assignment_model(context: @course, due_at: 5.minutes.ago, submission_types: "online_text_entry", points_possible: 100)

      # course with the student and observer
      course_with_student(user: @student)
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user

      ObserverAlertThreshold.create(observer:, student: @student, alert_type: "assignment_missing")

      ObserverAlert.create_assignment_missing_alerts

      expect(ObserverAlert.where(student: @student).count).to eq 0
    end

    context "when the assignment has no due date" do
      let(:course) { Course.create! }
      let(:student) { course.enroll_student(User.create!).user }
      let(:observer) { course.enroll_user(User.create!, "ObserverEnrollment", associated_user_id: student.id).user }
      let(:assignment) { course.assignments.create!(title: "missing", submission_types: "online_text_entry") }

      before do
        ObserverAlertThreshold.create!(observer:, student:, alert_type: "assignment_missing")
        assignment.submission_for_student(student).update!(late_policy_status: "missing")
      end

      it "creates an alert for submissions manually marked as missing when the assignment has no due date" do
        expect do
          ObserverAlert.create_assignment_missing_alerts
        end.to change {
          ObserverAlert.where(student:, alert_type: "assignment_missing").count
        }.by(1)
      end

      it "does not create an alert for missing submissions if one has already been created" do
        ObserverAlert.create_assignment_missing_alerts
        expect do
          ObserverAlert.create_assignment_missing_alerts
        end.not_to change {
          ObserverAlert.where(student:, alert_type: "assignment_missing").count
        }
      end
    end

    it "creates an alert for assignments due within the past day" do
      course = Course.create!
      student = course.enroll_student(User.create!).user
      observer = course.enroll_user(User.create!, "ObserverEnrollment", associated_user_id: student.id).user
      ObserverAlertThreshold.create!(observer:, student:, alert_type: "assignment_missing")

      course.assignments.create!(title: "missing", due_at: 1.hour.ago, submission_types: "online_text_entry")
      expect do
        ObserverAlert.create_assignment_missing_alerts
      end.to change {
        ObserverAlert.where(student:, alert_type: "assignment_missing").count
      }.by(1)
    end

    it "does not create an alert for assignments due more than one day ago" do
      course = Course.create!
      student = course.enroll_student(User.create!).user
      observer = course.enroll_user(User.create!, "ObserverEnrollment", associated_user_id: student.id).user
      ObserverAlertThreshold.create!(observer:, student:, alert_type: "assignment_missing")

      course.assignments.create!(title: "missing", due_at: 2.days.ago, submission_types: "online_text_entry")
      expect do
        ObserverAlert.create_assignment_missing_alerts
      end.not_to change {
        ObserverAlert.where(student:, alert_type: "assignment_missing").count
      }
    end
  end

  describe "institution_announcement" do
    before :once do
      @no_link_account = account_model
      @student = student_in_course(active_all: true).user
      @account = @course.account
      @observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user
      @threshold = ObserverAlertThreshold.create!(student: @student, observer: @observer, alert_type: "institution_announcement")
    end

    it "doesnt create an alert if the notificaiton is not for the root account" do
      sub_account = account_model(root_account: @account, parent_account: @account)
      notification = sub_account_notification(account: sub_account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it "doesnt create an alert if the start_at time is in the future" do
      notification = account_notification(start_at: 1.day.from_now, account: @account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it "doesnt create an alert if the roles dont include student or observer" do
      role_ids = ["TeacherEnrollment", "AccountAdmin"].map { |name| Role.get_built_in_role(name, root_account_id: @course.root_account_id).id }
      notification = account_notification(account: @account, role_ids:)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it "doesnt create an alert if there are no links" do
      notification = account_notification(account: @no_link_account)
      alert = ObserverAlert.where(context: notification).first
      expect(alert).to be_nil
    end

    it "creates an alert for each threshold set" do
      notification = account_notification(account: @account)
      alert = ObserverAlert.where(context: notification)
      expect(alert.count).to eq 1

      expect(alert.first.context).to eq notification
      expect(alert.first.title).to include("Institution announcement:")
    end

    it "does not duplicate alerts" do
      notification = account_notification(account: @account)
      alert = ObserverAlert.where(context: notification)
      expect(alert.count).to eq 1
      notification.save!
      expect(alert.count).to eq 1
    end

    it "creates an alert if student role is selected but not observer" do
      role_ids = ["StudentEnrollment", "AccountAdmin"].map { |name| Role.get_built_in_role(name, root_account_id: @course.root_account_id).id }
      notification = account_notification(account: @account, role_ids:)
      alert = ObserverAlert.where(context: notification).first
      expect(alert.context).to eq notification
    end

    it "creates an alert if observer role is selected but not student" do
      role_ids = ["ObserverEnrollment", "AccountAdmin"].map { |name| Role.get_built_in_role(name, root_account_id: @course.root_account_id).id }
      notification = account_notification(account: @account, role_ids:)
      alert = ObserverAlert.where(context: notification).first
      expect(alert.context).to eq notification
    end
  end

  describe "assignment_grade" do
    before :once do
      course_with_teacher
      @threshold1 = observer_alert_threshold_model(alert_type: "assignment_grade_high", threshold: "80", course: @course)
      @threshold2 = observer_alert_threshold_model(alert_type: "assignment_grade_low", threshold: "40", course: @course)
      @assignment1 = assignment_model(context: @course, points_possible: 100)
      @assignment2 = assignment_model(context: @course, points_possible: 10)
      @assignment3 = assignment_model(context: @course, points_possible: 0)
    end

    it "doesnt create an alert if there are no observers on that student" do
      student = student_in_course(course: @course).user
      @assignment1.grade_student(student, score: 50, grader: @teacher)

      alerts = ObserverAlert.where(context: @assignment1)
      expect(alerts.count).to eq 0
    end

    it "doesnt create an alert if there are no points possible" do
      @assignment3.grade_student(@threshold1.student, score: 100, grader: @teacher)
      alerts = ObserverAlert.where(context: @assignment3)
      expect(alerts.count).to eq 0
    end

    it "doesnt create an alert if there is no threshold for that observer" do
      student = student_in_course(course: @course).user
      course_with_observer(course: @course, associated_user_id: student.id)

      @assignment1.grade_student(student, score: 80, grader: @teacher)

      alerts = ObserverAlert.where(context: @assignment1)
      expect(alerts.count).to eq 0
    end

    it "doesnt create an alert if the threshold is not met" do
      @assignment1.grade_student(@threshold1.student, score: 70, grader: @teacher)
      @assignment1.grade_student(@threshold2.student, score: 50, grader: @teacher)

      alerts = ObserverAlert.where(context: @assignment1)
      expect(alerts.count).to eq 0
    end

    it "creates an alert if the threshold is met" do
      @assignment1.grade_student(@threshold1.student, score: 100, grader: @teacher)
      @assignment1.grade_student(@threshold2.student, score: 10, grader: @teacher)

      alert1 = ObserverAlert.where(context: @assignment1, alert_type: "assignment_grade_high").first
      expect(alert1).not_to be_nil
      expect(alert1.observer_alert_threshold).to eq @threshold1
      expect(alert1.title).to include("Assignment graded: ")

      alert2 = ObserverAlert.where(context: @assignment1, alert_type: "assignment_grade_low").first
      expect(alert2).not_to be_nil
      expect(alert2.observer_alert_threshold).to eq @threshold2
      expect(alert2.title).to include("Assignment graded: ")
    end

    it "creates an alert if the threshold percentage is met" do
      @assignment2.grade_student(@threshold1.student, score: 10, grader: @teacher)
      @assignment2.grade_student(@threshold2.student, score: 1, grader: @teacher)

      alert1 = ObserverAlert.where(context: @assignment2, alert_type: "assignment_grade_high").first
      expect(alert1).not_to be_nil
      expect(alert1.observer_alert_threshold).to eq @threshold1

      alert2 = ObserverAlert.where(context: @assignment2, alert_type: "assignment_grade_low").first
      expect(alert2).not_to be_nil
      expect(alert2.observer_alert_threshold).to eq @threshold2
    end

    it "doesnt create an alert if the threshold percentage isnt met" do
      @assignment2.grade_student(@threshold1.student, score: 7, grader: @teacher)
      @assignment2.grade_student(@threshold2.student, score: 5, grader: @teacher)

      alerts = ObserverAlert.where(context: @course)

      expect(alerts.count).to eq 0
    end

    it "doesnt create alerts for courses the observer is not in" do
      # course with just the student
      course_with_teacher
      course_with_student(course: @course)
      assignment = assignment_model(context: @course, points_possible: 100)

      # course with the student and observer
      course_with_student(user: @student)
      observer = course_with_observer(course: @course, associated_user_id: @student.id, active_all: true).user

      ObserverAlertThreshold.create(observer:, student: @student, alert_type: "assignment_grade_high", threshold: 80)

      assignment.grade_student(@student, score: 90, grader: @teacher)

      expect(ObserverAlert.where(student: @student).count).to eq 0
    end
  end
end
