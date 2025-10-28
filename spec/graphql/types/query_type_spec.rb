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
  end
end
