# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::QueryType do
  it "works" do
    # set up courses, teacher, and enrollments
    test_course_1 = Course.create! name: "TEST"
    test_course_2 = Course.create! name: "TEST2"
    Course.create! name: "TEST3"

    teacher = user_factory(name: "Coolguy Mcgee")
    test_course_1.enroll_user(teacher, "TeacherEnrollment")
    test_course_2.enroll_user(teacher, "TeacherEnrollment")

    # this is a set of course ids to check against

    # get query_type.allCourses
    expect(
      CanvasSchema.execute(
        "{ allCourses { _id } }",
        context: { current_user: teacher }
      ).dig("data", "allCourses").pluck("_id")
    ).to match_array [test_course_1, test_course_2].map(&:to_param)
  end

  context "courses query" do
    it "works with ids" do
      course1 = Course.create! name: "TEST1"
      course2 = Course.create! name: "TEST2", is_public_to_auth_users: true, workflow_state: "available"
      course3 = Course.create! name: "TEST3", workflow_state: "available"
      teacher = user_factory(name: "Teacher")
      course1.enroll_user(teacher, "TeacherEnrollment", enrollment_state: "active")

      result = CanvasSchema.execute(
        "{ courses(ids: [\"#{course1.id}\", \"#{course2.id}\", \"#{course3.id}\"]) { _id } }",
        context: { current_user: teacher }
      )

      expect(result.dig("data", "courses").pluck("_id"))
        .to match_array([course1.to_param, course2.to_param])
    end

    it "works with sis ids" do
      course1 = Course.create! name: "TEST1", sis_source_id: "sis_course_1"
      course2 = Course.create! name: "TEST2", sis_source_id: "sis_course_2", is_public_to_auth_users: true, workflow_state: "available"
      Course.create! name: "TEST3", sis_source_id: "sis_course_3", workflow_state: "available"
      teacher = user_factory(name: "Teacher")
      course1.enroll_user(teacher, "TeacherEnrollment", enrollment_state: "active")

      result = CanvasSchema.execute(
        "{ courses(sisIds: [\"sis_course_1\", \"sis_course_2\", \"sis_course_3\"]) { _id } }",
        context: { current_user: teacher }
      )

      expect(result.dig("data", "courses").pluck("_id"))
        .to match_array([course1.to_param, course2.to_param])
    end

    it "errors when both ids and sis_ids provided" do
      result = CanvasSchema.execute(
        "{ courses(ids: [\"123\"], sisIds: [\"sis123\"]) { _id } }",
        context: { current_user: user_factory }
      )

      expect(result.dig("errors", 0, "message")).to eq "Must specify exactly one of ids or sisIds"
    end

    it "errors when neither ids nor sis_ids provided" do
      result = CanvasSchema.execute(
        "{ courses { _id } }",
        context: { current_user: user_factory }
      )

      expect(result.dig("errors", 0, "message")).to eq "Must specify exactly one of ids or sisIds"
    end

    it "errors when requesting more than 100 courses at once" do
      course_ids = (1..101).map(&:to_s)
      result = CanvasSchema.execute(
        "{ courses(ids: #{course_ids.to_json}) { _id } }",
        context: { current_user: user_factory }
      )

      expect(result.dig("errors", 0, "message")).to eq "Cannot request more than 100 courses at once"
    end

    it "errors when requesting more than 100 courses via sis_ids" do
      sis_ids = (1..101).map { |i| "sis_course_#{i}" }
      result = CanvasSchema.execute(
        "{ courses(sisIds: #{sis_ids.to_json}) { _id } }",
        context: { current_user: user_factory }
      )

      expect(result.dig("errors", 0, "message")).to eq "Cannot request more than 100 courses at once"
    end
  end

  context "OutcomeCalculationMethod" do
    it "works" do
      @course = Course.create! name: "TEST"
      @admin = account_admin_user(account: @course.account)
      @calc_method = outcome_calculation_method_model(@course.account)

      expect(
        CanvasSchema.execute(
          "{ outcomeCalculationMethod(id: #{@calc_method.id}) { _id } }",
          context: { current_user: @admin }
        ).dig("data", "outcomeCalculationMethod", "_id")
      ).to eq @calc_method.id.to_s
    end
  end

  context "OutcomeProficiency" do
    it "works" do
      @course = Course.create! name: "TEST"
      @admin = account_admin_user(account: @course.account)
      @proficiency = outcome_proficiency_model(@course.account)

      expect(
        CanvasSchema.execute(
          "{ outcomeProficiency(id: #{@proficiency.id}) { _id } }",
          context: { current_user: @admin }
        ).dig("data", "outcomeProficiency", "_id")
      ).to eq @proficiency.id.to_s
    end
  end

  context "sisId" do
    let_once(:generic_sis_id) { "di_ecruos_sis" }
    let_once(:course) { Course.create!(name: "TEST", sis_source_id: generic_sis_id, account:) }
    let_once(:account) do
      acct = Account.default.sub_accounts.create!(name: "sub")
      acct.update!(sis_source_id: generic_sis_id)
      acct
    end
    let_once(:assignment) { course.assignments.create!(name: "test", sis_source_id: generic_sis_id) }
    let_once(:assignmentGroup) do
      assignment.assignment_group.update!(sis_source_id: generic_sis_id)
      assignment.assignment_group
    end
    let_once(:term) do
      course.enrollment_term.update!(sis_source_id: generic_sis_id)
      course.enrollment_term
    end
    let_once(:admin) { account_admin_user(account: Account.default) }

    %w[account course assignment assignmentGroup term].each do |type|
      it "doesn't allow searching #{type} when given both types of ids" do
        expect(
          CanvasSchema.execute("{#{type}(id: \"123\", sisId: \"123\") { id }}").dig("errors", 0, "message")
        ).to eq("Must specify exactly one of id or sisId")
      end

      it "allows searching #{type} by sisId" do
        original_object = send(type)
        expect(
          CanvasSchema.execute(%/{#{type}(sisId: "#{generic_sis_id}") { _id }}/, context: { current_user: admin })
          .dig("data", type, "_id")
        ).to eq(original_object.id.to_s)
      end
    end

    context "with multiple root accounts on same shard" do
      let_once(:shared_sis_id) { "SHARED_SIS_ID" }
      let_once(:root_account_1) { Account.create! }
      let_once(:root_account_2) { Account.create! }
      let_once(:account_1) { root_account_1.sub_accounts.create!(name: "Sub Account 1") }
      let_once(:account_2) { root_account_2.sub_accounts.create!(name: "Sub Account 2") }
      let_once(:course_1) do
        Course.create!(
          account: account_1,
          root_account: root_account_1,
          sis_source_id: shared_sis_id,
          name: "Course 1"
        )
      end
      let_once(:course_2) do
        Course.create!(
          account: account_2,
          root_account: root_account_2,
          sis_source_id: shared_sis_id,
          name: "Course 2"
        )
      end

      it "returns course from domain root account for local user" do
        user = user_factory
        course_1.enroll_teacher(user, enrollment_state: "active")

        result = CanvasSchema.execute(
          "{ course(sisId: \"#{shared_sis_id}\") { _id name } }",
          context: { current_user: user, domain_root_account: root_account_1 }
        )

        expect(result.dig("data", "course", "_id")).to eq(course_1.id.to_s)
        expect(result.dig("data", "course", "name")).to eq("Course 1")
      end

      it "returns null for local user querying from wrong account" do
        user = user_factory
        course_2.enroll_teacher(user, enrollment_state: "active")

        result = CanvasSchema.execute(
          "{ course(sisId: \"#{shared_sis_id}\") { _id name } }",
          context: { current_user: user, domain_root_account: root_account_1 }
        )

        expect(result.dig("data", "course")).to be_nil
      end

      it "returns course from domain root account for siteadmin" do
        siteadmin = site_admin_user

        result = CanvasSchema.execute(
          "{ course(sisId: \"#{shared_sis_id}\") { _id name } }",
          context: { current_user: siteadmin, domain_root_account: root_account_2 }
        )

        expect(result.dig("data", "course", "_id")).to eq(course_2.id.to_s)
        expect(result.dig("data", "course", "name")).to eq("Course 2")
      end

      it "scopes account queries to domain root account" do
        account_1.update!(sis_source_id: shared_sis_id)
        account_2.update!(sis_source_id: shared_sis_id)
        siteadmin = site_admin_user

        result = CanvasSchema.execute(
          "{ account(sisId: \"#{shared_sis_id}\") { _id name } }",
          context: { current_user: siteadmin, domain_root_account: root_account_1 }
        )

        expect(result.dig("data", "account", "_id")).to eq(account_1.id.to_s)
      end

      it "scopes assignment queries to domain root account" do
        assignment_1 = course_1.assignments.create!(name: "Assignment 1", sis_source_id: shared_sis_id)
        course_2.assignments.create!(name: "Assignment 2", sis_source_id: shared_sis_id)
        siteadmin = site_admin_user

        result = CanvasSchema.execute(
          "{ assignment(sisId: \"#{shared_sis_id}\") { _id name } }",
          context: { current_user: siteadmin, domain_root_account: root_account_1 }
        )

        expect(result.dig("data", "assignment", "_id")).to eq(assignment_1.id.to_s)
        expect(result.dig("data", "assignment", "name")).to eq("Assignment 1")
      end

      it "scopes term queries to domain root account" do
        root_account_1.enrollment_terms.create!(name: "Term 1", sis_source_id: shared_sis_id)
        term_2 = root_account_2.enrollment_terms.create!(name: "Term 2", sis_source_id: shared_sis_id)
        siteadmin = site_admin_user

        result = CanvasSchema.execute(
          "{ term(sisId: \"#{shared_sis_id}\") { _id name } }",
          context: { current_user: siteadmin, domain_root_account: root_account_2 }
        )

        expect(result.dig("data", "term", "_id")).to eq(term_2.id.to_s)
        expect(result.dig("data", "term", "name")).to eq("Term 2")
      end
    end
  end

  context "LearningOutcome" do
    it "works" do
      @course = Course.create! name: "TEST"
      @admin = account_admin_user(account: @course.account)

      outcome_with_rubric(context: @course)

      expect(
        CanvasSchema.execute(
          "{ learningOutcome(id: #{@outcome.id}) { _id } }",
          context: { current_user: @admin }
        ).dig("data", "learningOutcome", "_id")
      ).to eq @outcome.id.to_s
    end
  end

  context "internalSetting" do
    before :once do
      @setting = Setting.create!(name: "sadmississippi_num_strands", value: 10)
    end

    context "as site admin" do
      before :once do
        @admin = site_admin_user
      end

      it "loads by id" do
        thing = CanvasSchema.execute("{internalSetting(id: #{@setting.id}) { name }}",
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => { "name" => "sadmississippi_num_strands" } })
      end

      it "loads by name" do
        thing = CanvasSchema.execute('{internalSetting(name: "sadmississippi_num_strands") { _id }}',
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => { "_id" => @setting.id.to_s } })
      end

      it "errors if neither is provided" do
        thing = CanvasSchema.execute("{internalSetting { _id }}",
                                     context: { current_user: @admin })
        expect(thing["errors"][0]["message"]).to eq "Must specify exactly one of id or name"
      end

      it "errors if both are provided" do
        thing = CanvasSchema.execute('{internalSetting(id: 5, name: "foo") { _id }}',
                                     context: { current_user: @admin })
        expect(thing["errors"][0]["message"]).to eq "Must specify exactly one of id or name"
      end
    end

    context "as non site admin" do
      before :once do
        @admin = account_admin_user
      end

      it "rejects by id" do
        thing = CanvasSchema.execute("{internalSetting(id: #{@setting.id}) { name }}",
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => nil })
      end

      it "rejects by name" do
        thing = CanvasSchema.execute('{internalSetting(name: "sadmississippi_num_strands") { _id }}',
                                     context: { current_user: @admin })
        expect(thing["data"]).to eq({ "internalSetting" => nil })
      end
    end
  end

  context "submission" do
    before :once do
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      @assignment = @course.assignments.create!(name: "asdf", points_possible: 10)
    end

    let(:submission) { @assignment.submissions.find_by(user: @student1) }

    it "allows fetching the submission via ID as a teacher" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("data", "submission", "_id")
      ).to eq submission.id.to_s
    end

    it "allows fetching the submission via ID as the submission owner" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}) { _id } }",
          context: { current_user: @student1 }
        ).dig("data", "submission", "_id")
      ).to eq submission.id.to_s
    end

    it "does not allow fetching the submission via ID as a non-owner student" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}) { _id } }",
          context: { current_user: @student2 }
        ).dig("data", "submission")
      ).to be_nil
    end

    it "returns an error when fetching the submission via ID in combination with the assignment ID" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}, assignmentId: #{@assignment.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id or an assignment_id and an anonymous_id"
    end

    it "returns an error when fetching the submission via ID in combination with the user ID" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}, userId: #{@student1.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id or an assignment_id and an anonymous_id"
    end

    it "returns an error when fetching the submission via ID in combination with the anonymous ID" do
      expect(
        CanvasSchema.execute(
          "{ submission(id: #{submission.id}, anonymousId: #{@student1.id}) { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id or an assignment_id and an anonymous_id"
    end

    it "returns an error when not providing an id or assignment_id and user_id" do
      expect(
        CanvasSchema.execute(
          "{ submission { _id } }",
          context: { current_user: @teacher }
        ).dig("errors", 0, "message")
      ).to eq "Must specify an id or an assignment_id and user_id or an assignment_id and an anonymous_id"
    end
  end

  context "myInboxSettings" do
    before do
      Account.site_admin.enable_feature!(:inbox_settings)
      Inbox::Repositories::InboxSettingsRepository.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: nil,
        out_of_office_last_date: nil,
        out_of_office_subject: "Out of office",
        out_of_office_message: "Out of office for a week"
      )
    end

    let(:account) { Account.create! }
    let(:course) { account.courses.create! }
    let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
    let(:user_id) { teacher.id }
    let(:context) { { current_user: teacher, domain_root_account: account } }
    let(:root_account_id) { account.id }

    it "works" do
      settings = CanvasSchema.execute(
        "{ myInboxSettings {
          userId,
          useSignature,
          signature
          useOutOfOffice,
          outOfOfficeFirstDate,
          outOfOfficeLastDate,
          outOfOfficeSubject,
          outOfOfficeMessage
        } }",
        context:
      ).dig("data", "myInboxSettings")

      expect(settings["userId"]).to eq user_id.to_s
      expect(settings["useSignature"]).to be true
      expect(settings["signature"]).to eq "John Doe"
      expect(settings["useOutOfOffice"]).to be true
      expect(settings["outOfOfficeFirstDate"]).to be_nil
      expect(settings["outOfOfficeLastDate"]).to be_nil
      expect(settings["outOfOfficeSubject"]).to eq "Out of office"
      expect(settings["outOfOfficeMessage"]).to eq "Out of office for a week"
    end
  end

  context "accountNotifications" do
    before(:once) do
      @account = Account.default
      @admin = account_admin_user(account: @account)
      @student = student_in_course(account: @account, active_all: true).user
      @teacher = teacher_in_course(account: @account, active_all: true).user
    end

    def create_notification(opts = {})
      AccountNotification.create!(
        {
          account: @account,
          subject: "Test Notification",
          message: "<p>Test message</p>",
          start_at: 1.day.ago,
          end_at: 30.days.from_now,
          user: @admin
        }.merge(opts)
      )
    end

    def execute_query(context_user = @student, account_id = nil)
      query = <<~GQL
        query {
          accountNotifications#{"(accountId: \"#{account_id}\")" if account_id} {
            id
            _id
            subject
            message
            startAt
            endAt
            accountName
            siteAdmin
            notificationType
          }
        }
      GQL
      CanvasSchema.execute(query, context: { current_user: context_user, domain_root_account: @account })
    end

    describe "fetching notifications" do
      it "returns empty array when no notifications exist" do
        result = execute_query(@student)
        expect(result.dig("data", "accountNotifications")).to eq []
      end

      it "returns empty array for unauthenticated users" do
        result = execute_query(nil)
        expect(result.dig("data", "accountNotifications")).to eq []
      end

      it "returns active notifications for authenticated users" do
        notification = create_notification
        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications.length).to eq 1
        expect(notifications[0]["subject"]).to eq "Test Notification"
        expect(notifications[0]["_id"]).to eq notification.id.to_s
      end

      it "excludes expired notifications" do
        create_notification(start_at: 2.days.ago, end_at: 1.day.ago)
        result = execute_query(@student)
        expect(result.dig("data", "accountNotifications")).to eq []
      end

      it "excludes future notifications" do
        create_notification(start_at: 1.day.from_now)
        result = execute_query(@student)
        expect(result.dig("data", "accountNotifications")).to eq []
      end

      it "includes currently active notifications" do
        active_notification = create_notification(
          start_at: 1.hour.ago,
          end_at: 1.hour.from_now
        )
        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications.length).to eq 1
        expect(notifications[0]["_id"]).to eq active_notification.id.to_s
      end
    end

    describe "role-based filtering" do
      before(:once) do
        @student_notification = create_notification(subject: "Student Only")
        @student_role = Role.get_built_in_role("StudentEnrollment", root_account_id: @account.root_account.id)
        AccountNotificationRole.create!(
          account_notification: @student_notification,
          role: @student_role
        )

        @teacher_notification = create_notification(subject: "Teacher Only")
        @teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @account.root_account.id)
        AccountNotificationRole.create!(
          account_notification: @teacher_notification,
          role: @teacher_role
        )

        @all_users_notification = create_notification(subject: "All Users")
      end

      it "shows role-specific notifications to users with that role" do
        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")
        subjects = notifications.pluck("subject")

        expect(subjects).to include("Student Only")
        expect(subjects).to include("All Users")
        expect(subjects).not_to include("Teacher Only")
      end

      it "shows teacher notifications to teachers" do
        result = execute_query(@teacher)
        notifications = result.dig("data", "accountNotifications")
        subjects = notifications.pluck("subject")

        expect(subjects).to include("Teacher Only")
        expect(subjects).to include("All Users")
        expect(subjects).not_to include("Student Only")
      end

      it "shows all notifications when no role restrictions" do
        result = execute_query(@teacher)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications.any? { |n| n["subject"] == "All Users" }).to be true
      end
    end

    describe "dismissed notifications" do
      before(:once) do
        @notification1 = create_notification(subject: "Notification 1")
        @notification2 = create_notification(subject: "Notification 2")
      end

      it "excludes dismissed notifications" do
        @student.set_preference(:closed_notifications, [@notification1.id])

        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications.length).to eq 1
        expect(notifications[0]["subject"]).to eq "Notification 2"
      end

      it "shows all notifications when none are dismissed" do
        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications.length).to eq 2
      end

      it "excludes multiple dismissed notifications" do
        @student.set_preference(:closed_notifications, [@notification1.id, @notification2.id])

        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications).to eq []
      end
    end

    describe "with account_id parameter" do
      before(:once) do
        @other_account = Account.create!(name: "Other Account")
        @other_notification = AccountNotification.create!(
          account: @other_account,
          subject: "Other Account Notification",
          message: "Message",
          start_at: 1.day.ago,
          end_at: 30.days.from_now,
          user: @admin
        )
      end

      it "returns notifications for specified account" do
        result = execute_query(@admin, @other_account.id)
        notifications = result.dig("data", "accountNotifications")

        expect(notifications.length).to eq 1
        expect(notifications[0]["subject"]).to eq "Other Account Notification"
      end

      it "returns empty array when account not found" do
        result = execute_query(@student, "99999999")
        expect(result.dig("data", "accountNotifications")).to eq []
      end
    end

    describe "notification ordering" do
      it "orders notifications by end date descending" do
        create_notification(subject: "First", end_at: 10.days.from_now)
        create_notification(subject: "Second", end_at: 20.days.from_now)
        create_notification(subject: "Third", end_at: 15.days.from_now)

        result = execute_query(@student)
        notifications = result.dig("data", "accountNotifications")
        subjects = notifications.pluck("subject")

        expect(subjects).to eq %w[Second Third First]
      end
    end
  end

  context "courseInstructorsConnection" do
    before(:once) do
      @course1 = Course.create!(name: "Course 1", workflow_state: "available")
      @course2 = Course.create!(name: "Course 2", workflow_state: "available")
      @course3 = Course.create!(name: "Course 3", workflow_state: "available")

      @instructor1 = user_factory(name: "Instructor 1")
      @instructor2 = user_factory(name: "Instructor 2")

      @teacher_enrollment1 = @course1.enroll_teacher(@instructor1)
      @teacher_enrollment1.accept!
      @teacher_enrollment2 = @course2.enroll_teacher(@instructor2)
      @teacher_enrollment2.accept!
      @teacher_enrollment3 = @course3.enroll_teacher(@instructor1)
      @teacher_enrollment3.accept!

      @student = user_factory(name: "Student")
      @course1.enroll_student(@student, enrollment_state: "active")
      @course2.enroll_student(@student, enrollment_state: "active")

      @observer = user_factory(name: "Observer")
      @observed_user = user_factory(name: "Observed Student")
      @course1.enroll_student(@observed_user, enrollment_state: "active")
      @course2.enroll_student(@observed_user, enrollment_state: "active")
      @course3.enroll_student(@observed_user, enrollment_state: "active")
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_user.id, enrollment_state: "active")
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_user.id, enrollment_state: "active")
    end

    let(:query) do
      <<~GQL
        query($courseIds: [ID!]!, $observedUserId: ID) {
          courseInstructorsConnection(courseIds: $courseIds, observedUserId: $observedUserId) {
            nodes {
              user {
                _id
                name
              }
              course {
                _id
                name
              }
            }
          }
        }
      GQL
    end

    it "returns instructors for current user's courses" do
      result = CanvasSchema.execute(
        query,
        variables: { courseIds: [@course1.id.to_s, @course2.id.to_s] },
        context: { current_user: @student }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      expect(instructors.length).to eq(2)
      instructor_names = instructors.pluck("user").pluck("name").sort
      expect(instructor_names).to eq(["Instructor 1", "Instructor 2"])
    end

    it "does not return instructors for pending enrollments" do
      @course4 = Course.create!(name: "Course 4", workflow_state: "available")
      @instructor4 = user_factory(name: "Instructor 4")
      @teacher_enrollment4 = @course4.enroll_teacher(@instructor4)
      @teacher_enrollment4.accept!
      @course4.enroll_student(@student, enrollment_state: "invited")
      result = CanvasSchema.execute(
        query,
        variables: { courseIds: [@course4.id.to_s] },
        context: { current_user: @student }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      expect(instructors).to be_empty
    end

    it "returns instructors for observed user's courses when observer" do
      result = CanvasSchema.execute(
        query,
        variables: {
          courseIds: [@course1.id.to_s, @course2.id.to_s, @course3.id.to_s],
          observedUserId: @observed_user.id.to_s
        },
        context: { current_user: @observer }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      expect(instructors.length).to eq(2)
      instructor_names = instructors.pluck("user").pluck("name").sort
      expect(instructor_names).to eq(["Instructor 1", "Instructor 2"])
    end

    it "returns empty result for invalid observed user id" do
      result = CanvasSchema.execute(
        query,
        variables: {
          courseIds: [@course1.id.to_s],
          observedUserId: "999999"
        },
        context: { current_user: @observer }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      expect(instructors).to be_empty
    end

    it "only returns instructors for courses observer is authorized to see" do
      result = CanvasSchema.execute(
        query,
        variables: {
          courseIds: [@course1.id.to_s, @course2.id.to_s, @course3.id.to_s],
          observedUserId: @observed_user.id.to_s
        },
        context: { current_user: @observer }
      )

      course_ids = result.dig("data", "courseInstructorsConnection", "nodes")
                         .pluck("course").pluck("_id").sort
      expect(course_ids).to eq([@course1.id.to_s, @course2.id.to_s])
    end

    it "deduplicates instructors with multiple section enrollments in the same course" do
      # Create multiple sections in course1
      section1 = @course1.course_sections.create!(name: "Section 1")
      section2 = @course1.course_sections.create!(name: "Section 2")
      section3 = @course1.course_sections.create!(name: "Section 3")

      # Enroll instructor1 in multiple sections
      enrollment1 = @course1.enroll_teacher(@instructor1, section: section1, allow_multiple_enrollments: true)
      enrollment1.accept!
      enrollment2 = @course1.enroll_teacher(@instructor1, section: section2, allow_multiple_enrollments: true)
      enrollment2.accept!
      enrollment3 = @course1.enroll_teacher(@instructor1, section: section3, allow_multiple_enrollments: true)
      enrollment3.accept!

      result = CanvasSchema.execute(
        query,
        variables: { courseIds: [@course1.id.to_s] },
        context: { current_user: @student }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      # Should only return instructor1 once, not three times (one per section)
      expect(instructors.length).to eq(1)
      expect(instructors[0].dig("user", "name")).to eq("Instructor 1")
      expect(instructors[0].dig("course", "_id")).to eq(@course1.id.to_s)
    end

    it "filters out past enrollments based on course end dates" do
      # Create a course that ended in the past
      @past_course = Course.create!(name: "Past Course", workflow_state: "available", conclude_at: 1.week.ago)
      @past_instructor = user_factory(name: "Past Instructor")
      past_enrollment = @past_course.enroll_teacher(@past_instructor)
      past_enrollment.accept!
      @past_course.enroll_student(@student, enrollment_state: "active")

      result = CanvasSchema.execute(
        query,
        variables: { courseIds: [@past_course.id.to_s] },
        context: { current_user: @student }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      # Should not return instructors from past courses
      expect(instructors).to be_empty
    end

    it "filters out hard inactive enrollments" do
      # Make instructor2's enrollment inactive
      @teacher_enrollment2.deactivate

      result = CanvasSchema.execute(
        query,
        variables: { courseIds: [@course2.id.to_s] },
        context: { current_user: @student }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      # Should not return inactive instructors
      expect(instructors).to be_empty
    end

    it "filters out instructors from unpublished courses" do
      # Create an unpublished course with a teacher
      @unpublished_course = Course.create!(name: "Unpublished Course", workflow_state: "unpublished")
      @unpublished_instructor = user_factory(name: "Unpublished Instructor")
      unpublished_enrollment = @unpublished_course.enroll_teacher(@unpublished_instructor)
      unpublished_enrollment.accept!
      @unpublished_course.enroll_student(@student, enrollment_state: "active")

      result = CanvasSchema.execute(
        query,
        variables: { courseIds: [@unpublished_course.id.to_s] },
        context: { current_user: @student }
      )

      instructors = result.dig("data", "courseInstructorsConnection", "nodes")
      # Should not return instructors from unpublished courses
      expect(instructors).to be_empty
    end

    describe "pagination" do
      before(:once) do
        @paginated_course = Course.create!(name: "Paginated Course", workflow_state: "available")
        @paginated_student = user_factory(name: "Paginated Student")
        @paginated_course.enroll_student(@paginated_student, enrollment_state: "active")

        # Create 10 instructors
        @paginated_instructors = (1..10).map do |i|
          instructor = user_factory(name: "Instructor #{i.to_s.rjust(2, "0")}", sortable_name: "Instructor #{i.to_s.rjust(2, "0")}")
          enrollment = @paginated_course.enroll_teacher(instructor)
          enrollment.accept!
          instructor
        end
      end

      let(:paginated_query) do
        <<~GQL
          query($courseIds: [ID!]!, $first: Int, $after: String) {
            courseInstructorsConnection(courseIds: $courseIds, first: $first, after: $after) {
              nodes {
                user {
                  _id
                  name
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
                totalCount
              }
            }
          }
        GQL
      end

      it "respects the first parameter to limit results" do
        result = CanvasSchema.execute(
          paginated_query,
          variables: { courseIds: [@paginated_course.id.to_s], first: 5 },
          context: { current_user: @paginated_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        page_info = result.dig("data", "courseInstructorsConnection", "pageInfo")

        expect(nodes.length).to eq(5)
        expect(page_info["hasNextPage"]).to be true
        expect(page_info["hasPreviousPage"]).to be false
        expect(page_info["totalCount"]).to eq(10)
      end

      it "handles cursor-based pagination correctly" do
        # First page
        first_result = CanvasSchema.execute(
          paginated_query,
          variables: { courseIds: [@paginated_course.id.to_s], first: 3 },
          context: { current_user: @paginated_student }
        )

        first_nodes = first_result.dig("data", "courseInstructorsConnection", "nodes")
        first_page_info = first_result.dig("data", "courseInstructorsConnection", "pageInfo")
        end_cursor = first_page_info["endCursor"]

        expect(first_nodes.length).to eq(3)
        expect(first_page_info["hasNextPage"]).to be true
        expect(end_cursor).not_to be_nil

        # Second page
        second_result = CanvasSchema.execute(
          paginated_query,
          variables: { courseIds: [@paginated_course.id.to_s], first: 3, after: end_cursor },
          context: { current_user: @paginated_student }
        )

        second_nodes = second_result.dig("data", "courseInstructorsConnection", "nodes")
        second_page_info = second_result.dig("data", "courseInstructorsConnection", "pageInfo")

        expect(second_nodes.length).to eq(3)
        expect(second_page_info["hasNextPage"]).to be true
        expect(second_page_info["hasPreviousPage"]).to be true

        # Verify no duplicate instructors between pages
        first_ids = first_nodes.pluck("user").pluck("_id")
        second_ids = second_nodes.pluck("user").pluck("_id")
        expect(first_ids & second_ids).to be_empty
      end

      it "returns accurate totalCount after deduplication with multiple section enrollments" do
        # Create multiple sections and enroll instructor in all of them
        section1 = @paginated_course.course_sections.create!(name: "Section A")
        section2 = @paginated_course.course_sections.create!(name: "Section B")
        section3 = @paginated_course.course_sections.create!(name: "Section C")

        multi_section_instructor = @paginated_instructors.first
        @paginated_course.enroll_teacher(multi_section_instructor, section: section1, allow_multiple_enrollments: true).accept!
        @paginated_course.enroll_teacher(multi_section_instructor, section: section2, allow_multiple_enrollments: true).accept!
        @paginated_course.enroll_teacher(multi_section_instructor, section: section3, allow_multiple_enrollments: true).accept!

        result = CanvasSchema.execute(
          paginated_query,
          variables: { courseIds: [@paginated_course.id.to_s] },
          context: { current_user: @paginated_student }
        )

        page_info = result.dig("data", "courseInstructorsConnection", "pageInfo")
        nodes = result.dig("data", "courseInstructorsConnection", "nodes")

        # Should still be 10 unique instructors, not 13 (10 + 3 additional enrollments)
        expect(page_info["totalCount"]).to eq(10)
        expect(nodes.length).to eq(10)
      end

      it "handles pagination when last page has fewer items than requested" do
        result = CanvasSchema.execute(
          paginated_query,
          variables: { courseIds: [@paginated_course.id.to_s], first: 7 },
          context: { current_user: @paginated_student }
        )

        result.dig("data", "courseInstructorsConnection", "nodes")
        first_page_info = result.dig("data", "courseInstructorsConnection", "pageInfo")

        # Get second page
        second_result = CanvasSchema.execute(
          paginated_query,
          variables: { courseIds: [@paginated_course.id.to_s], first: 7, after: first_page_info["endCursor"] },
          context: { current_user: @paginated_student }
        )

        second_nodes = second_result.dig("data", "courseInstructorsConnection", "nodes")
        second_page_info = second_result.dig("data", "courseInstructorsConnection", "pageInfo")

        expect(second_nodes.length).to eq(3) # Only 3 remaining
        expect(second_page_info["hasNextPage"]).to be false
      end
    end

    describe "TA enrollments" do
      before(:once) do
        @ta_course = Course.create!(name: "TA Course", workflow_state: "available")
        @ta_student = user_factory(name: "TA Student")
        @ta_course.enroll_student(@ta_student, enrollment_state: "active")

        @teacher = user_factory(name: "Teacher User")
        @ta1 = user_factory(name: "TA User 1")
        @ta2 = user_factory(name: "TA User 2")

        @teacher_enrollment = @ta_course.enroll_teacher(@teacher)
        @teacher_enrollment.accept!
        @ta_enrollment1 = @ta_course.enroll_ta(@ta1)
        @ta_enrollment1.accept!
        @ta_enrollment2 = @ta_course.enroll_ta(@ta2)
        @ta_enrollment2.accept!
      end

      it "returns TAs alongside teachers" do
        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [@ta_course.id.to_s] },
          context: { current_user: @ta_student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(instructors.length).to eq(3)

        instructor_names = instructors.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["TA User 1", "TA User 2", "Teacher User"])
      end

      it "correctly identifies enrollment type for TAs" do
        result = CanvasSchema.execute(
          <<~GQL,
            query($courseIds: [ID!]!) {
              courseInstructorsConnection(courseIds: $courseIds) {
                nodes {
                  user {
                    name
                  }
                  type
                }
              }
            }
          GQL
          variables: { courseIds: [@ta_course.id.to_s] },
          context: { current_user: @ta_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        ta_nodes = nodes.select { |n| n["user"]["name"].include?("TA User") }
        teacher_nodes = nodes.select { |n| n["user"]["name"].include?("Teacher User") }

        expect(ta_nodes.length).to eq(2)
        expect(ta_nodes.all? { |n| n["type"] == "TaEnrollment" }).to be true
        expect(teacher_nodes.length).to eq(1)
        expect(teacher_nodes.first["type"]).to eq("TeacherEnrollment")
      end

      it "returns TAs when course has only TAs and no teachers" do
        @ta_only_course = Course.create!(name: "TA Only Course", workflow_state: "available")
        @ta_only_course.enroll_student(@ta_student, enrollment_state: "active")
        @ta_only_course.enroll_ta(@ta1).accept!
        @ta_only_course.enroll_ta(@ta2).accept!

        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [@ta_only_course.id.to_s] },
          context: { current_user: @ta_student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(instructors.length).to eq(2)
        instructor_names = instructors.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["TA User 1", "TA User 2"])
      end
    end

    describe "enrollment_types filter" do
      before(:once) do
        @filter_course = Course.create!(name: "Filter Course", workflow_state: "available")
        @filter_student = user_factory(name: "Filter Student")
        @filter_course.enroll_student(@filter_student, enrollment_state: "active")

        @filter_teacher1 = user_factory(name: "Filter Teacher 1")
        @filter_teacher2 = user_factory(name: "Filter Teacher 2")
        @filter_ta1 = user_factory(name: "Filter TA 1")
        @filter_ta2 = user_factory(name: "Filter TA 2")

        @filter_course.enroll_teacher(@filter_teacher1).accept!
        @filter_course.enroll_teacher(@filter_teacher2).accept!
        @filter_course.enroll_ta(@filter_ta1).accept!
        @filter_course.enroll_ta(@filter_ta2).accept!
      end

      let(:filter_query) do
        <<~GQL
          query($courseIds: [ID!]!, $enrollmentTypes: [String!]) {
            courseInstructorsConnection(courseIds: $courseIds, enrollmentTypes: $enrollmentTypes) {
              nodes {
                user {
                  _id
                  name
                }
                type
              }
            }
          }
        GQL
      end

      it "filters to only teachers when enrollmentTypes is [TeacherEnrollment]" do
        result = CanvasSchema.execute(
          filter_query,
          variables: { courseIds: [@filter_course.id.to_s], enrollmentTypes: ["TeacherEnrollment"] },
          context: { current_user: @filter_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(nodes.length).to eq(2)

        instructor_names = nodes.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["Filter Teacher 1", "Filter Teacher 2"])

        types = nodes.pluck("type").uniq
        expect(types).to eq(["TeacherEnrollment"])
      end

      it "filters to only TAs when enrollmentTypes is [TaEnrollment]" do
        result = CanvasSchema.execute(
          filter_query,
          variables: { courseIds: [@filter_course.id.to_s], enrollmentTypes: ["TaEnrollment"] },
          context: { current_user: @filter_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(nodes.length).to eq(2)

        instructor_names = nodes.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["Filter TA 1", "Filter TA 2"])

        types = nodes.pluck("type").uniq
        expect(types).to eq(["TaEnrollment"])
      end

      it "returns both teachers and TAs when enrollmentTypes includes both types" do
        result = CanvasSchema.execute(
          filter_query,
          variables: {
            courseIds: [@filter_course.id.to_s],
            enrollmentTypes: ["TeacherEnrollment", "TaEnrollment"]
          },
          context: { current_user: @filter_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(nodes.length).to eq(4)

        instructor_names = nodes.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["Filter TA 1", "Filter TA 2", "Filter Teacher 1", "Filter Teacher 2"])

        types = nodes.pluck("type").uniq.sort
        expect(types).to eq(["TaEnrollment", "TeacherEnrollment"])
      end

      it "returns both teachers and TAs when enrollmentTypes is not provided" do
        result = CanvasSchema.execute(
          filter_query,
          variables: { courseIds: [@filter_course.id.to_s] },
          context: { current_user: @filter_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(nodes.length).to eq(4)

        instructor_names = nodes.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["Filter TA 1", "Filter TA 2", "Filter Teacher 1", "Filter Teacher 2"])
      end

      it "returns both teachers and TAs when enrollmentTypes is empty array" do
        result = CanvasSchema.execute(
          filter_query,
          variables: { courseIds: [@filter_course.id.to_s], enrollmentTypes: [] },
          context: { current_user: @filter_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(nodes.length).to eq(4)

        instructor_names = nodes.pluck("user").pluck("name").sort
        expect(instructor_names).to eq(["Filter TA 1", "Filter TA 2", "Filter Teacher 1", "Filter Teacher 2"])
      end

      it "does not include invalid enrollment types" do
        result = CanvasSchema.execute(
          filter_query,
          variables: { courseIds: [@filter_course.id.to_s], enrollmentTypes: ["InvalidType", "TeacherEnrollment"] },
          context: { current_user: @filter_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(nodes.length).to eq(2)

        types = nodes.pluck("type").uniq
        expect(types).to eq(["TeacherEnrollment"])
      end
    end

    describe "enrollment priority and deduplication" do
      before(:once) do
        @priority_course = Course.create!(name: "Priority Course", workflow_state: "available")
        @priority_student = user_factory(name: "Priority Student")
        @priority_course.enroll_student(@priority_student, enrollment_state: "active")
      end

      it "returns active enrollment over invited when user has both" do
        instructor = user_factory(name: "Multi-State Instructor")

        # Create invited enrollment
        invited_enrollment = @priority_course.enroll_teacher(instructor)
        expect(invited_enrollment.workflow_state).to eq("invited")

        # Create active enrollment in different section
        section2 = @priority_course.course_sections.create!(name: "Active Section")
        active_enrollment = @priority_course.enroll_teacher(instructor, section: section2, allow_multiple_enrollments: true)
        active_enrollment.accept!
        expect(active_enrollment.workflow_state).to eq("active")

        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [@priority_course.id.to_s] },
          context: { current_user: @priority_student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(instructors.length).to eq(1)
        expect(instructors[0].dig("user", "name")).to eq("Multi-State Instructor")

        # Verify the active enrollment is returned (we can check via enrollmentState field)
        result_with_state = CanvasSchema.execute(
          <<~GQL,
            query($courseIds: [ID!]!) {
              courseInstructorsConnection(courseIds: $courseIds) {
                nodes {
                  user { name }
                  enrollmentState
                }
              }
            }
          GQL
          variables: { courseIds: [@priority_course.id.to_s] },
          context: { current_user: @priority_student }
        )

        enrollment_state = result_with_state.dig("data", "courseInstructorsConnection", "nodes", 0, "enrollmentState")
        expect(enrollment_state).to eq("active")
      end

      it "filters out restricted access enrollments" do
        instructor = user_factory(name: "Restricted Instructor")
        enrollment = @priority_course.enroll_teacher(instructor)
        enrollment.accept!

        # Set restricted access
        enrollment.enrollment_state.update!(restricted_access: true)

        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [@priority_course.id.to_s] },
          context: { current_user: @priority_student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        instructor_names = instructors.pluck("user").pluck("name")
        expect(instructor_names).not_to include("Restricted Instructor")
      end

      it "handles user with both Teacher and TA enrollments in same course" do
        instructor = user_factory(name: "Dual Role Instructor")

        # Enroll as teacher
        teacher_enrollment = @priority_course.enroll_teacher(instructor)
        teacher_enrollment.accept!

        # Also enroll as TA in different section
        section2 = @priority_course.course_sections.create!(name: "TA Section")
        ta_enrollment = @priority_course.enroll_ta(instructor, section: section2, allow_multiple_enrollments: true)
        ta_enrollment.accept!

        result = CanvasSchema.execute(
          <<~GQL,
            query($courseIds: [ID!]!) {
              courseInstructorsConnection(courseIds: $courseIds) {
                nodes {
                  user { name }
                  type
                }
              }
            }
          GQL
          variables: { courseIds: [@priority_course.id.to_s] },
          context: { current_user: @priority_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        dual_role_nodes = nodes.select { |n| n["user"]["name"] == "Dual Role Instructor" }

        # Should return only one enrollment (deduplicated by course_id + user_id)
        expect(dual_role_nodes.length).to eq(1)
      end

      it "filters out completed enrollments even when user has no active enrollment" do
        instructor = user_factory(name: "Completed Instructor")
        enrollment = @priority_course.enroll_teacher(instructor)
        enrollment.accept!
        enrollment.complete!

        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [@priority_course.id.to_s] },
          context: { current_user: @priority_student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        instructor_names = instructors.pluck("user").pluck("name")
        expect(instructor_names).not_to include("Completed Instructor")
      end
    end

    describe "sorting" do
      before(:once) do
        @course_z = Course.create!(name: "Z Course", workflow_state: "available")
        @course_a = Course.create!(name: "A Course", workflow_state: "available")
        @course_m = Course.create!(name: "M Course", workflow_state: "available")

        @sort_student = user_factory(name: "Sort Student")
        @course_z.enroll_student(@sort_student, enrollment_state: "active")
        @course_a.enroll_student(@sort_student, enrollment_state: "active")
        @course_m.enroll_student(@sort_student, enrollment_state: "active")

        # Add instructors with specific sortable names
        @instructor_z = user_factory(name: "Instructor Z", sortable_name: "Z, Instructor")
        @instructor_a = user_factory(name: "Instructor A", sortable_name: "A, Instructor")
        @instructor_m = user_factory(name: "Instructor M", sortable_name: "M, Instructor")

        @course_z.enroll_teacher(@instructor_z).accept!
        @course_a.enroll_teacher(@instructor_a).accept!
        @course_a.enroll_teacher(@instructor_z).accept! # Add Z to A course too
        @course_m.enroll_teacher(@instructor_m).accept!
      end

      it "sorts by course name ascending, then by user sortable name ascending" do
        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [@course_z.id.to_s, @course_a.id.to_s, @course_m.id.to_s] },
          context: { current_user: @sort_student }
        )

        nodes = result.dig("data", "courseInstructorsConnection", "nodes")
        course_names = nodes.pluck("course").pluck("name")

        # Should be sorted by course name: A Course, M Course, Z Course
        expect(course_names).to eq(["A Course", "A Course", "M Course", "Z Course"])

        # Within A Course, should be sorted by sortable name: A then Z
        a_course_instructors = nodes.select { |n| n["course"]["name"] == "A Course" }
        a_course_names = a_course_instructors.pluck("user").pluck("name")
        expect(a_course_names).to eq(["Instructor A", "Instructor Z"])
      end
    end

    describe "empty courseIds" do
      before(:once) do
        @empty_student = user_factory(name: "Empty Student")

        # Enroll in 5 courses
        @student_courses = (1..5).map do |i|
          course = Course.create!(name: "Student Course #{i}", workflow_state: "available")
          course.enroll_student(@empty_student, enrollment_state: "active")

          instructor = user_factory(name: "Instructor #{i}")
          course.enroll_teacher(instructor).accept!

          course
        end
      end

      it "returns instructors from all user's courses when courseIds is empty array" do
        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [] },
          context: { current_user: @empty_student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")

        # Should return instructors from all 5 courses
        expect(instructors.length).to eq(5)
        instructor_names = instructors.pluck("user").pluck("name").sort
        expect(instructor_names).to eq((1..5).map { |i| "Instructor #{i}" })
      end
    end

    context "multi-section scenarios" do
      it "deduplicates instructors enrolled in multiple sections" do
        # Create course with instructor teaching 3 sections
        course = Course.create!(name: "Multi-Section Course", account: Account.default, workflow_state: "available")
        section1 = course.default_section
        section2 = course.course_sections.create!(name: "Section 2")
        section3 = course.course_sections.create!(name: "Section 3")

        student = User.create!(name: "Student")
        course.enroll_student(student, section: section1, enrollment_state: "active")

        shared_instructor = User.create!(name: "Shared Instructor")
        [section1, section2, section3].each do |section|
          enroll = Enrollment.create!(
            user: shared_instructor,
            course:,
            course_section: section,
            type: "TeacherEnrollment",
            workflow_state: "active",
            root_account_id: Account.default.id
          )
          enroll.enrollment_state.update!(state: "active", restricted_access: false)
        end

        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [course.id.to_s] },
          context: { current_user: student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        instructor_ids = instructors.pluck("user").pluck("_id")

        # GraphQL uses DISTINCT ON (course_id, user_id) - instructor appears once despite 3 enrollments
        expect(instructor_ids.count(shared_instructor.id.to_s)).to eq(1)
        expect(instructor_ids.uniq).to eq(instructor_ids) # No duplicates
      end

      it "returns empty result for course with no instructors" do
        course = Course.create!(name: "Empty Course", account: Account.default, workflow_state: "available")
        student = User.create!(name: "Student")
        course.enroll_student(student, section: course.default_section, enrollment_state: "active")

        result = CanvasSchema.execute(
          query,
          variables: { courseIds: [course.id.to_s] },
          context: { current_user: student }
        )

        instructors = result.dig("data", "courseInstructorsConnection", "nodes")
        expect(instructors).to be_empty
      end
    end
  end

  context "peerReviewSubAssignment query" do
    before(:once) do
      @course = Course.create!(name: "Test Course")
      @teacher = teacher_in_course(course: @course, active_all: true).user
      @course.enable_feature!(:peer_review_allocation_and_grading)

      @parent_assignment = @course.assignments.create!(
        title: "Parent Assignment",
        peer_reviews: true,
        peer_review_count: 2
      )
      @peer_review_sub_assignment = peer_review_model(parent_assignment: @parent_assignment)
    end

    let(:query) do
      <<~GQL
        query($id: ID!) {
          peerReviewSubAssignment(id: $id) {
            _id
            name
            parentAssignmentId
          }
        }
      GQL
    end

    def execute_query(query_string = query, user = @teacher, id = @peer_review_sub_assignment.id.to_s, other_context = {})
      CanvasSchema.execute(
        query_string,
        variables: { id: },
        context: { current_user: user }.merge(other_context)
      )
    end

    context "with valid id" do
      it "returns peer review sub assignment" do
        result = execute_query

        assignment = result.dig("data", "peerReviewSubAssignment")
        expect(assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
        expect(assignment["name"]).to eq @peer_review_sub_assignment.name
        expect(assignment["parentAssignmentId"]).to eq @parent_assignment.id.to_s
      end

      it "works with relay id format" do
        relay_id = GraphQLHelpers.relay_or_legacy_id_prepare_func("PeerReviewSubAssignment").call(@peer_review_sub_assignment.id.to_s)
        result = execute_query(query, @teacher, relay_id)

        assignment = result.dig("data", "peerReviewSubAssignment")
        expect(assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
      end
    end

    context "when feature flag is disabled" do
      before do
        @course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "returns nil" do
        result = execute_query

        expect(result.dig("data", "peerReviewSubAssignment")).to be_nil
      end
    end

    context "with invalid permissions" do
      before(:once) do
        @other_course = Course.create!(name: "Other Course")
        @other_teacher = teacher_in_course(course: @other_course, active_all: true).user
      end

      it "returns nil for user without access" do
        result = execute_query(query, @other_teacher)

        expect(result.dig("data", "peerReviewSubAssignment")).to be_nil
      end
    end

    context "with non-existent id" do
      it "returns nil" do
        result = execute_query(query, @teacher, "999999")

        expect(result.dig("data", "peerReviewSubAssignment")).to be_nil
      end
    end

    context "querying inherited fields" do
      it "resolves fields inherited from AssignmentType" do
        extended_query = <<~GQL
          query($id: ID!) {
            peerReviewSubAssignment(id: $id) {
              _id
              name
              pointsPossible
              courseId
              state
            }
          }
        GQL

        result = execute_query(extended_query, @teacher, @peer_review_sub_assignment.id.to_s, request: ActionDispatch::TestRequest.create)

        peer_review_sub_assignment = result.dig("data", "peerReviewSubAssignment")
        expect(peer_review_sub_assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
        expect(peer_review_sub_assignment["name"]).to eq @peer_review_sub_assignment.name
        expect(peer_review_sub_assignment["pointsPossible"]).to eq @peer_review_sub_assignment.points_possible
        expect(peer_review_sub_assignment["courseId"]).to eq @course.id.to_s
        expect(peer_review_sub_assignment["state"]).to eq @peer_review_sub_assignment.workflow_state
      end

      context "overridden fields" do
        it "returns html_url pointing to parent assignment" do
          extended_query = <<~GQL
            query($id: ID!) {
              peerReviewSubAssignment(id: $id) {
                htmlUrl
                parentAssignment {
                  htmlUrl
                }
              }
            }
          GQL

          result = execute_query(extended_query, @teacher, @peer_review_sub_assignment.id.to_s, request: ActionDispatch::TestRequest.create)

          peer_review_sub_assignment = result.dig("data", "peerReviewSubAssignment")
          parent_assignment = peer_review_sub_assignment["parentAssignment"]
          expect(peer_review_sub_assignment["htmlUrl"]).to eq(parent_assignment["htmlUrl"])
        end
      end
    end
  end

  context "assignment query with includeTypes parameter" do
    before(:once) do
      @course = Course.create!(name: "Test Course")
      @teacher = teacher_in_course(course: @course, active_all: true).user
      @course.enable_feature!(:peer_review_allocation_and_grading)

      @course.offer!
      @parent_assignment = @course.assignments.create!(
        title: "Parent Assignment",
        peer_reviews: true,
        peer_review_count: 2,
        submission_types: "online_text_entry"
      )
      @peer_review_sub_assignment = peer_review_model(parent_assignment: @parent_assignment)
    end

    let(:base_query) do
      <<~GQL
        query($id: ID!) {
          assignment(id: $id) {
            _id
            name
            assignmentType
            parentAssignmentId
          }
        }
      GQL
    end

    let(:query_with_include_types) do
      <<~GQL
        query($id: ID!, $includeTypes: [AssignmentTypeEnum!]) {
          assignment(id: $id, includeTypes: $includeTypes) {
            _id
            name
            assignmentType
            parentAssignmentId
            parentAssignment {
              _id
              name
            }
          }
        }
      GQL
    end

    def execute_query(query_string, user, variables = {})
      CanvasSchema.execute(
        query_string,
        variables:,
        context: { current_user: user, request: ActionDispatch::TestRequest.create }
      )
    end

    context "default behavior (backward compatible)" do
      it "returns Assignment when queried by assignment ID" do
        result = execute_query(base_query, @teacher, { id: @parent_assignment.id.to_s })

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "ASSIGNMENT"
        expect(assignment["parentAssignmentId"]).to be_nil
      end

      it "returns nil when queried by PRSA ID without includeTypes" do
        result = execute_query(base_query, @teacher, { id: @peer_review_sub_assignment.id.to_s })

        expect(result.dig("data", "assignment")).to be_nil
      end

      it "defaults to Assignment when includeTypes is empty" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: @parent_assignment.id.to_s, includeTypes: [] }
        )

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "ASSIGNMENT"
      end
    end

    context "with includeTypes: [PEER_REVIEW_SUB_ASSIGNMENT]" do
      it "returns PRSA when queried by PRSA ID" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: @peer_review_sub_assignment.id.to_s, includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "PEER_REVIEW_SUB_ASSIGNMENT"
        expect(assignment["parentAssignmentId"]).to eq @parent_assignment.id.to_s
        expect(assignment.dig("parentAssignment", "_id")).to eq @parent_assignment.id.to_s
      end

      it "returns nil when queried by Assignment ID" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: @parent_assignment.id.to_s, includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        expect(result.dig("data", "assignment")).to be_nil
      end
    end

    context "with includeTypes: [ASSIGNMENT, PEER_REVIEW_SUB_ASSIGNMENT]" do
      it "returns Assignment when queried by Assignment ID" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: @parent_assignment.id.to_s, includeTypes: %w[ASSIGNMENT PEER_REVIEW_SUB_ASSIGNMENT] }
        )

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "ASSIGNMENT"
        expect(assignment["parentAssignmentId"]).to be_nil
        expect(assignment["parentAssignment"]).to be_nil
      end

      it "returns PRSA when queried by PRSA ID" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: @peer_review_sub_assignment.id.to_s, includeTypes: %w[ASSIGNMENT PEER_REVIEW_SUB_ASSIGNMENT] }
        )

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "PEER_REVIEW_SUB_ASSIGNMENT"
        expect(assignment["parentAssignmentId"]).to eq @parent_assignment.id.to_s
      end
    end

    context "when feature flag is disabled" do
      before do
        @course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "returns nil for PRSA even with includeTypes" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: @peer_review_sub_assignment.id.to_s, includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        expect(result.dig("data", "assignment")).to be_nil
      end

      it "still returns Assignment normally" do
        result = execute_query(base_query, @teacher, { id: @parent_assignment.id.to_s })

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
      end
    end

    context "with invalid permissions" do
      before(:once) do
        @other_course = Course.create!(name: "Other Course")
        @other_teacher = teacher_in_course(course: @other_course, active_all: true).user
      end

      it "returns nil for user without access" do
        result = execute_query(
          query_with_include_types,
          @other_teacher,
          { id: @peer_review_sub_assignment.id.to_s, includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        expect(result.dig("data", "assignment")).to be_nil
      end
    end

    context "with sisId parameter" do
      before(:once) do
        @parent_assignment.update!(sis_source_id: "SIS_ASSIGNMENT_123")
      end

      it "returns assignment by sisId (ignores includeTypes for SIS lookup)" do
        query = <<~GQL
          query($sisId: String!) {
            assignment(sisId: $sisId, includeTypes: [ASSIGNMENT, PEER_REVIEW_SUB_ASSIGNMENT]) {
              _id
              name
              assignmentType
            }
          }
        GQL

        result = execute_query(query, @teacher, { sisId: "SIS_ASSIGNMENT_123" })

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "ASSIGNMENT"
      end
    end

    context "with non-existent ID" do
      it "returns nil for non-existent assignment ID" do
        result = execute_query(base_query, @teacher, { id: "999999999" })

        expect(result.dig("data", "assignment")).to be_nil
      end

      it "returns nil for non-existent PRSA ID with includeTypes" do
        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: "999999999", includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        expect(result.dig("data", "assignment")).to be_nil
      end
    end

    context "with student user" do
      before(:once) do
        @student = student_in_course(course: @course, active_all: true).user
      end

      it "allows students to query Assignment" do
        result = execute_query(base_query, @student, { id: @parent_assignment.id.to_s })

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "ASSIGNMENT"
      end

      it "allows students to query PRSA with includeTypes" do
        result = execute_query(
          query_with_include_types,
          @student,
          { id: @peer_review_sub_assignment.id.to_s, includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "PEER_REVIEW_SUB_ASSIGNMENT"
      end
    end

    context "with Relay global ID format" do
      it "accepts Relay global ID for Assignment" do
        relay_id = CanvasSchema.id_from_object(@parent_assignment, Types::AssignmentType, nil)

        result = execute_query(base_query, @teacher, { id: relay_id })

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @parent_assignment.id.to_s
      end

      it "accepts Relay global ID for PRSA with includeTypes" do
        relay_id = CanvasSchema.id_from_object(@peer_review_sub_assignment, Types::AssignmentType, nil)

        result = execute_query(
          query_with_include_types,
          @teacher,
          { id: relay_id, includeTypes: ["PEER_REVIEW_SUB_ASSIGNMENT"] }
        )

        assignment = result.dig("data", "assignment")
        expect(assignment["_id"]).to eq @peer_review_sub_assignment.id.to_s
        expect(assignment["assignmentType"]).to eq "PEER_REVIEW_SUB_ASSIGNMENT"
      end
    end
  end
end
