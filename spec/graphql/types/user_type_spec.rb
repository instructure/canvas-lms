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
require "helpers/k5_common"

describe Types::UserType do
  include K5Common

  before(:once) do
    student = student_in_course(active_all: true).user
    course = @course
    teacher = @teacher
    @other_student = student_in_course(active_all: true).user

    @other_course = course_factory
    @random_person = teacher_in_course(active_all: true).user

    @course = course
    @student = student
    @teacher = teacher
    @ta = ta_in_course(active_all: true).user
  end

  let(:user_type) do
    GraphQLTypeTester.new(
      @student,
      current_user: @teacher,
      domain_root_account: @course.account.root_account,
      request: ActionDispatch::TestRequest.create
    )
  end

  let(:student_user_type) do
    GraphQLTypeTester.new(
      @student,
      current_user: @student,
      domain_root_account: @course.account.root_account,
      request: ActionDispatch::TestRequest.create
    )
  end

  context "node" do
    it "works" do
      expect(user_type.resolve("_id")).to eq @student.id.to_s
      expect(user_type.resolve("name")).to eq @student.name
    end

    it "works for users in the same course" do
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s
    end

    it "works for users without a current enrollment" do
      user = user_model
      type = GraphQLTypeTester.new(user, current_user: user, domain_root_account: user.account, request: ActionDispatch::TestRequest.create)
      expect(type.resolve("_id")).to eq user.id.to_s
      expect(type.resolve("name")).to eq user.name
    end

    it "doesn't work for just anyone" do
      expect(user_type.resolve("_id", current_user: @random_person)).to be_nil
    end

    it "loads inactive and concluded users" do
      @student.enrollments.update_all workflow_state: "inactive"
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s

      @student.enrollments.update_all workflow_state: "completed"
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s
    end
  end

  context "login_id" do
    before(:once) do
      @student.pseudonyms.create!(
        account: @course.account,
        unique_id: "alex@columbia.edu",
        workflow_state: "active"
      )
    end

    let(:admin) { account_admin_user }
    let(:user_type_as_admin) do
      GraphQLTypeTester.new(@student,
                            current_user: admin,
                            domain_root_account: @course.account.root_account,
                            request: ActionDispatch::TestRequest.create)
    end

    context "returns login_id" do
      it "if there is no pseudonym" do
        expect(user_type_as_admin.resolve("loginId")).to be_nil
      end
    end

    context "returns nil" do
      it "when there is no course in context" do
        expect(user_type_as_admin.resolve("loginId")).to be_nil
      end

      it "when requesting user has no permission :view_user_logins" do
        account_admin_user_with_role_changes(role_changes: { view_user_logins: false })
        expect(user_type_as_admin.resolve("loginId")).to be_nil
      end

      it "when there is no pseudonym created" do
        expect(user_type_as_admin.resolve("loginId", current_user: @other_student)).to be_nil
      end
    end
  end

  context "shortName" do
    before(:once) do
      @student.update! short_name: "new display name"
    end

    it "is displayed if set" do
      expect(user_type.resolve("shortName")).to eq "new display name"
    end

    it "returns full name if shortname is not set" do
      @student.update! short_name: nil
      expect(user_type.resolve("shortName")).to eq @student.name
    end
  end

  context "uuid" do
    it "is displayed when requested" do
      expect(user_type.resolve("uuid")).to eq @student.uuid.to_s
    end
  end

  context "avatarUrl" do
    before(:once) do
      @student.update! avatar_image_url: "not-a-fallback-avatar.png"
    end

    it "is nil when avatars are not enabled" do
      expect(user_type.resolve("avatarUrl")).to be_nil
    end

    it "returns an avatar url when avatars are enabled" do
      @student.account.enable_service(:avatars)
      expect(user_type.resolve("avatarUrl")).to match(/avatar.*png/)
    end

    it "returns nil when a user has no avatar" do
      @student.account.enable_service(:avatars)
      @student.update! avatar_image_url: nil
      expect(user_type.resolve("avatarUrl")).to be_nil
    end
  end

  context "htmlUrl" do
    it "returns the user's profile url" do
      html_url = user_type.resolve(%|htmlUrl(courseId: "#{@course.id}")|)
      expect(html_url.end_with?("courses/#{@course.id}/users/#{@student.id}")).to be_truthy
    end
  end

  context "pronouns" do
    it "returns user pronouns" do
      @student.account.root_account.settings[:can_add_pronouns] = true
      @student.account.root_account.save!
      @student.pronouns = "Dude/Guy"
      @student.save!
      expect(user_type.resolve("pronouns")).to eq "Dude/Guy"
    end
  end

  context "sisId" do
    before(:once) do
      @student.pseudonyms.create!(
        account: @course.account,
        unique_id: "alex@columbia.edu",
        workflow_state: "active",
        sis_user_id: "a.ham"
      )
    end

    context "as admin" do
      let(:admin) { account_admin_user }
      let(:user_type_as_admin) do
        GraphQLTypeTester.new(@student,
                              current_user: admin,
                              domain_root_account: @course.account.root_account,
                              request: ActionDispatch::TestRequest.create)
      end

      it "returns the sis user id if the user has permissions to read it" do
        expect(user_type_as_admin.resolve("sisId")).to eq "a.ham"
      end

      it "returns nil if the user does not have permission to read the sis user id" do
        account_admin_user_with_role_changes(role_changes: { read_sis: false, manage_sis: false })
        admin_type = GraphQLTypeTester.new(@student,
                                           current_user: @admin,
                                           domain_root_account: @course.account.root_account,
                                           request: ActionDispatch::TestRequest.create)
        expect(admin_type.resolve("sisId")).to be_nil
      end
    end

    context "as teacher" do
      it "returns the sis user id if the user has permissions to read it" do
        expect(user_type.resolve("sisId")).to eq "a.ham"
      end

      it "returns null if the user does not have permission to read the sis user id" do
        @teacher.enrollments.find_by(course: @course).role
                .role_overrides.create!(permission: "read_sis", enabled: false, account: @course.account)
        expect(user_type.resolve("sisId")).to be_nil
      end
    end
  end

  context "integrationId" do
    before(:once) do
      @student.pseudonyms.create!(
        account: @course.account,
        unique_id: "rlands@eab.com",
        workflow_state: "active",
        integration_id: "Rachel.Lands"
      )
    end

    context "as admin" do
      let(:admin) { account_admin_user }
      let(:user_type_as_admin) do
        GraphQLTypeTester.new(@student,
                              current_user: admin,
                              domain_root_account: @course.account.root_account,
                              request: ActionDispatch::TestRequest.create)
      end

      it "returns the integration id if admin user has permissions to read SIS info" do
        expect(user_type_as_admin.resolve("integrationId")).to eq "Rachel.Lands"
      end

      it "returns null for integration id if admin user does not have permission to read SIS info" do
        account_admin_user_with_role_changes(role_changes: { read_sis: false, manage_sis: false })
        admin_type = GraphQLTypeTester.new(@student,
                                           current_user: @admin,
                                           domain_root_account: @course.account.root_account,
                                           request: ActionDispatch::TestRequest.create)
        expect(admin_type.resolve("integrationId")).to be_nil
      end
    end

    context "as teacher" do
      it "returns the integration id if teacher user has permissions to read SIS info" do
        expect(user_type.resolve("integrationId")).to eq "Rachel.Lands"
      end

      it "returns null if teacher user does not have permission to read SIS info" do
        @teacher.enrollments.find_by(course: @course).role
                .role_overrides.create!(permission: "read_sis", enabled: false, account: @course.account)
        expect(user_type.resolve("integrationId")).to be_nil
      end
    end
  end

  context "enrollments" do
    before(:once) do
      @course1 = @course
      @course2 = course_factory
      @course2.enroll_student(@student, enrollment_state: "active")
    end

    it "returns enrollments for a given course" do
      expect(
        user_type.resolve(%|enrollments(courseId: "#{@course1.id}") { _id }|)
      ).to eq [@student.enrollments.first.to_param]
    end

    it "returns all enrollments for a user (that can be read)" do
      @course1.enroll_student(@student, enrollment_state: "active")

      expect(
        user_type.resolve("enrollments { _id }")
      ).to eq [@student.enrollments.first.to_param]

      site_admin_user
      expect(
        user_type.resolve(
          "enrollments { _id }",
          current_user: @admin
        )
      ).to match_array @student.enrollments.map(&:to_param)
    end

    it "excludes deleted course enrollments for a user" do
      @course1.enroll_student(@student, enrollment_state: "active")
      @course2.destroy

      site_admin_user
      expect(
        user_type.resolve(
          "enrollments { _id }",
          current_user: @admin
        )
      ).to eq [@student.enrollments.first.to_param]
    end

    it "excludes unavailable courses when currentOnly is true" do
      @course1.complete

      expect(user_type.resolve("enrollments(currentOnly: true) { _id }")).to eq []
    end

    it "excludes concluded courses when currentOnly is true" do
      @course1.start_at = 2.weeks.ago
      @course1.conclude_at = 1.week.ago
      @course1.restrict_enrollments_to_course_dates = true
      @course1.save!

      expect(user_type.resolve("enrollments(currentOnly: true) { _id }")).to eq []
    end

    it "sorts correctly when orderBy is provided" do
      @course2.start_at = 1.week.ago
      @course2.save!

      expect(user_type.resolve('enrollments(orderBy: ["courses.start_at"]) {
          _id
          course {
            _id
          }
        }',
                               current_user: @student).map(&:to_i)).to eq [@course2.id, @course1.id]
    end

    it "throws when orderBy is SQL injection" do
      error = assert_raises GraphQLTypeTester::Error do
        user_type.resolve('enrollments(orderBy: ["pg_sleep(3)::text"]) {
          _id
          course {
            _id
          }
        }')
      end

      expect(error.message).to eq(%([{"message" => "orderBy is not included in the list", "locations" => [{"line" => 4, "column" => 7}], "path" => ["node", "enrollments"]}]))
    end

    context "sort" do
      before(:once) do
        @course1 = course_factory
        course_with_teacher(course: @course1)
        @section1 = @course1.course_sections.create!(name: "Section A")
        @section2 = @course1.course_sections.create!(name: "Section B")
        @section3 = @course1.course_sections.create!(name: "Section C")

        @student1 = user_factory
        @enrollment1 = @course.enroll_student(@student1, section: @section1, enrollment_state: "active", allow_multiple_enrollments: true)
        @enrollment2 = @course.enroll_student(@student1, section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)
        @enrollment3 = @course.enroll_student(@student1, section: @section3, enrollment_state: "active", allow_multiple_enrollments: true)
      end

      let(:one_day_ago) { 1.day.ago }
      let(:two_days_ago) { 2.days.ago }
      let(:three_days_ago) { 3.days.ago }

      let(:user_type1) do
        GraphQLTypeTester.new(
          @student1,
          current_user: @teacher,
          domain_root_account: @course1.account.root_account,
          request: ActionDispatch::TestRequest.create
        )
      end

      def format_date(date)
        Time.zone.parse(date.to_s)
      end

      def resolve_last_activity_at(order = "asc")
        user_type1.resolve("enrollments(
          courseId: \"#{@course1.id}\",
          sort: {
            field: last_activity_at,
            direction: #{order}
          }
          ) {
              lastActivityAt
            }").map { |date_str| format_date(date_str) }
      end

      def resolve_last_activity_at_with_section_name(order = "asc")
        user_type1.resolve("enrollments(
          courseId: \"#{@course1.id}\",
          sort: {
            field: last_activity_at,
            direction: #{order}
          }
          ) {
              section {
                name
              }
            }")
      end

      def resolve_section_name(order = "asc")
        user_type1.resolve("enrollments(
          courseId: \"#{@course1.id}\",
          sort: {
            field: section_name,
            direction: #{order}
          }
        ) {
            section {
              name
            }
          }")
      end

      def resolve_role(order = "asc")
        user_type1.resolve("enrollments(
          courseId: \"#{@course1.id}\",
          sort: {
            field: role,
            direction: #{order}
          }
        ) {
            type
          }")
      end

      def resolve_role_with_section_name(order = "asc")
        user_type1.resolve("enrollments(
          courseId: \"#{@course1.id}\",
          sort: {
            field: role,
            direction: #{order}
          }
        ) {
            section {
              name
            }
          }")
      end

      context "last_activity_at" do
        before(:once) do
          @enrollment1.update!(last_activity_at: one_day_ago)
          @enrollment2.update!(last_activity_at: two_days_ago)
          @enrollment3.update!(last_activity_at: three_days_ago)
        end

        it "sorts by last_activity_at ascending" do
          expect(resolve_last_activity_at).to match [format_date(@enrollment1.last_activity_at), format_date(@enrollment2.last_activity_at), format_date(@enrollment3.last_activity_at)]
        end

        it "sorts by last_activity_at descending" do
          expect(resolve_last_activity_at("desc")).to match [format_date(@enrollment3.last_activity_at), format_date(@enrollment2.last_activity_at), format_date(@enrollment1.last_activity_at)]
        end

        it "performs secondary sort by section name ascending" do
          @enrollment1.update!(last_activity_at: one_day_ago)
          @enrollment3.update!(last_activity_at: one_day_ago)
          # enrollment1 - one_day_ago, Section A
          # enrollment3 - one_day_ago, Section C
          # enrollment2 - two_days_ago, Section B
          expect(resolve_last_activity_at_with_section_name).to match ["Section A", "Section C", "Section B"]
          # enrollment2 - two_days_ago, Section B
          # enrollment1 - one_day_ago, Section A
          # enrollment3 - one_day_ago, Section C
          expect(resolve_last_activity_at_with_section_name("desc")).to match ["Section B", "Section A", "Section C"]
        end
      end

      context "section_name" do
        it "sorts by section_name ascending" do
          expect(resolve_section_name).to match [@section1.name, @section2.name, @section3.name]
        end

        it "sorts by section_name descending" do
          expect(resolve_section_name("desc")).to match [@section3.name, @section2.name, @section1.name]
        end
      end

      context "role" do
        before(:once) do
          @enrollment2.update!(type: "TeacherEnrollment")
          @enrollment3.update!(type: "TaEnrollment")
        end

        it "sorts by role ascending" do
          expect(resolve_role).to match %w[TeacherEnrollment TaEnrollment StudentEnrollment]
        end

        it "sorts by role descending" do
          expect(resolve_role("desc")).to match %w[StudentEnrollment TaEnrollment TeacherEnrollment]
        end

        it "performs secondary sort by section name ascending" do
          @enrollment3.update!(type: "StudentEnrollment")
          # enrollment2 - teacher, Section B
          # enrollment1 - student, Section A
          # enrollment3 - student, Section C
          expect(resolve_role_with_section_name).to match ["Section B", "Section A", "Section C"]
          # enrollment1 - student, Section A
          # enrollment3 - student, Section C
          # enrollment2 - teacher, Section B
          expect(resolve_role_with_section_name("desc")).to match ["Section A", "Section C", "Section B"]
        end
      end
    end

    it "doesn't return enrollments for courses the user doesn't have permission for" do
      expect(
        user_type.resolve(%|enrollments(courseId: "#{@course2.id}") { _id }|)
      ).to eq []
    end

    it "excludes deactivated enrollments when currentOnly is true" do
      @student.enrollments.each(&:deactivate)
      results = user_type.resolve("enrollments(currentOnly: true) { _id }")
      expect(results).to be_empty
    end

    it "includes deactivated enrollments when currentOnly is false" do
      @student.enrollments.each(&:deactivate)
      results = user_type.resolve("enrollments(currentOnly: false) { _id }")
      expect(results).not_to be_empty
    end

    it "excludes concluded enrollments when excludeConcluded is true" do
      expect(user_type.resolve("enrollments(excludeConcluded: true) { _id }").length).to eq 1
      @student.enrollments.update_all workflow_state: "completed"
      expect(user_type.resolve("enrollments(excludeConcluded: true) { _id }")).to eq []
    end

    it "excludes enrollments that have a state of creation_pending" do
      expect(user_type.resolve("enrollments { _id }").length).to eq 1
      @student.enrollments.update(workflow_state: "creation_pending")
      expect(user_type.resolve("enrollments { _id }")).to eq []
    end

    it "excludes enrollments that have a enrollment_state of pending_active" do
      expect(user_type.resolve("enrollments { _id }", current_user: @student).length).to eq @student.enrollments.count

      @course1.update(start_at: 1.week.from_now, restrict_enrollments_to_course_dates: true)

      expect(@student.enrollments.where(course_id: @course1)[0].enrollment_state.state).to eq "pending_active"

      expect(user_type.resolve("enrollments { _id }", current_user: @student)).to eq [@student.enrollments.where(course_id: @course2).first.to_param]
    end

    context "Horizon courses" do
      before :once do
        @course3 = course_factory
        @course3.update!(horizon_course: true)
      end

      it "return only horizon courses if included" do
        @course3.enroll_student(@student, enrollment_state: "active")
        expect(user_type.resolve("enrollments(horizonCourses: true) { _id }", current_user: @student).length).to eq 1
      end

      it "returns only non-horizon courses if false" do
        @course3.enroll_student(@student, enrollment_state: "active")
        expect(user_type.resolve("enrollments(horizonCourses: false) { _id }", current_user: @student).length).to eq @student.enrollments.length - 1
      end
    end
  end

  context "enrollments_connection" do
    before(:once) do
      @course1 = @course
      @course2 = course_factory
      @course2.enroll_student(@student, enrollment_state: "active")
      @course3 = course_factory
      @course3.enroll_student(@student, enrollment_state: "active")
      @course4 = course_factory
      @course4.enroll_student(@student, enrollment_state: "active")
    end

    it "returns paginated enrollments with default limit" do
      user_type.extract_result = false
      result = user_type.resolve("enrollmentsConnection { nodes { _id } pageInfo { hasNextPage hasPreviousPage } }")
      enrollments_result = result["enrollmentsConnection"]

      expect(enrollments_result["nodes"]).to be_an(Array)
      expect(enrollments_result["pageInfo"]).to include("hasNextPage", "hasPreviousPage")
    end

    it "returns enrollments with specified limit" do
      user_type.extract_result = false
      result = user_type.resolve("enrollmentsConnection(first: 2) { nodes { _id } pageInfo { hasNextPage hasPreviousPage endCursor startCursor } }")
      enrollments_result = result["enrollmentsConnection"]
      expect(enrollments_result["nodes"].length).to be <= 2
      expect(enrollments_result["pageInfo"]).to include("hasNextPage", "hasPreviousPage", "endCursor", "startCursor")
    end

    it "supports cursor-based pagination" do
      user_type.extract_result = false
      # Get first page
      first_page_result = user_type.resolve("enrollmentsConnection(first: 2) { nodes { _id } pageInfo { endCursor hasNextPage } }")
      first_page = first_page_result["enrollmentsConnection"]

      if first_page["pageInfo"]["hasNextPage"]
        cursor = first_page["pageInfo"]["endCursor"]
        # Get second page
        second_page_result = user_type.resolve(%|enrollmentsConnection(first: 2, after: "#{cursor}") { nodes { _id } pageInfo { hasPreviousPage } }|)
        second_page = second_page_result["enrollmentsConnection"]
        expect(second_page["pageInfo"]["hasPreviousPage"]).to be true

        # Ensure different results
        first_ids = first_page["nodes"].pluck("_id")
        second_ids = second_page["nodes"].pluck("_id")
        expect(first_ids & second_ids).to be_empty
      end
    end

    it "returns enrollments for a given course with pagination" do
      user_type.extract_result = false
      result = user_type.resolve(%|enrollmentsConnection(courseId: "#{@course1.id}", first: 1) { nodes { _id } }|)
      enrollments_result = result["enrollmentsConnection"]
      expect(enrollments_result["nodes"].length).to eq 1
      expect(enrollments_result["nodes"].first["_id"]).to eq @student.enrollments.where(course: @course1).first.to_param
    end

    it "excludes unavailable courses when currentOnly is true" do
      @course1.complete
      user_type.extract_result = false
      result = user_type.resolve("enrollmentsConnection(currentOnly: true) { nodes { _id } }")
      enrollments_result = result["enrollmentsConnection"]
      course1_enrollment_id = @student.enrollments.where(course: @course1).first.to_param
      node_ids = enrollments_result["nodes"].pluck("_id")
      expect(node_ids).not_to include(course1_enrollment_id)
    end

    it "excludes concluded enrollments when excludeConcluded is true" do
      @student.enrollments.where(course: @course1).update_all(workflow_state: "completed")
      user_type.extract_result = false
      result = user_type.resolve("enrollmentsConnection(excludeConcluded: true) { nodes { _id } }")
      enrollments_result = result["enrollmentsConnection"]
      course1_enrollment_id = @student.enrollments.where(course: @course1).first.to_param
      node_ids = enrollments_result["nodes"].pluck("_id")
      expect(node_ids).not_to include(course1_enrollment_id)
    end

    it "applies same permission checks as regular enrollments field" do
      # Test that user can't see enrollments for courses they don't have permission for
      user_type.extract_result = false
      result = user_type.resolve(%|enrollmentsConnection(courseId: "#{@course2.id}") { nodes { _id } }|)
      enrollments_result = result["enrollmentsConnection"]
      expect(enrollments_result["nodes"]).to eq []
    end

    it "supports sorting with orderBy parameter" do
      @course2.start_at = 1.week.ago
      @course2.save!

      user_type.extract_result = false
      result = user_type.resolve('enrollmentsConnection(orderBy: ["courses.start_at"]) {
                                   nodes {
                                     _id
                                     course { _id }
                                   }
                                 }',
                                 current_user: @student)
      enrollments_result = result["enrollmentsConnection"]

      course_ids = enrollments_result["nodes"].map { |n| n["course"]["_id"].to_i }
      expect(course_ids).to include(@course2.id, @course1.id)
    end

    context "with many enrollments" do
      before(:once) do
        # Create additional courses to test pagination behavior
        5.times do |i|
          course = course_factory(course_name: "Test Course #{i + 5}")
          course.enroll_student(@student, enrollment_state: "active")
        end
      end

      it "properly paginates through all enrollments" do
        user_type.extract_result = false
        all_enrollment_ids = []
        has_next = true
        cursor = nil

        while has_next
          query = if cursor
                    %|enrollmentsConnection(first: 3, after: "#{cursor}") { nodes { _id } pageInfo { hasNextPage endCursor } }|
                  else
                    "enrollmentsConnection(first: 3) { nodes { _id } pageInfo { hasNextPage endCursor } }"
                  end

          result = user_type.resolve(query, current_user: @student)
          enrollments_result = result["enrollmentsConnection"]
          page_ids = enrollments_result["nodes"].pluck("_id")
          all_enrollment_ids.concat(page_ids)

          has_next = enrollments_result["pageInfo"]["hasNextPage"]
          cursor = enrollments_result["pageInfo"]["endCursor"]

          # Safety break to prevent infinite loops in tests
          break if all_enrollment_ids.length > 20
        end

        # Verify we got all enrollments and no duplicates
        expect(all_enrollment_ids.uniq.length).to eq all_enrollment_ids.length
        expect(all_enrollment_ids.length).to eq @student.enrollments.count
      end
    end

    context "permission handling" do
      before(:once) do
        @admin = account_admin_user
        @observer = user_factory(name: "Observer")
        @other_course = course_factory
        @other_student = user_factory(name: "Other Student")

        @other_course.enroll_student(@other_student, enrollment_state: "active")
        @other_course.enroll_teacher(@teacher, enrollment_state: "active")

        student_course = @student.enrollments.first.course
        observer_enrollment = student_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active")
        observer_enrollment.update!(associated_user_id: @student.id)
        UserObservationLink.create!(
          student: @student,
          observer: @observer,
          root_account: @course.account.root_account
        )
      end

      let(:admin_type) do
        GraphQLTypeTester.new(
          @student,
          current_user: @admin,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )
      end

      it "allows admin with manage_students permission to view all user enrollments" do
        admin_type.extract_result = false
        result = admin_type.resolve("enrollmentsConnection { nodes { _id } }")
        enrollments_result = result["enrollmentsConnection"]

        expected_ids = @student.enrollments.pluck(:id).map(&:to_param)
        actual_ids = enrollments_result["nodes"].pluck("_id")
        expect(actual_ids).to match_array(expected_ids)
      end

      it "allows observer to view their observee's enrollments" do
        observer_viewing_student = GraphQLTypeTester.new(
          @student,
          current_user: @observer,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )

        observer_viewing_student.extract_result = false
        result = observer_viewing_student.resolve("enrollmentsConnection { nodes { _id } }")
        enrollments_result = result["enrollmentsConnection"]

        student_course = @student.enrollments.first.course
        expected_enrollment = @student.enrollments.find_by(course: student_course)
        expected_ids = [expected_enrollment.id.to_param]
        actual_ids = enrollments_result["nodes"].pluck("_id")
        expect(actual_ids).to match_array(expected_ids)
      end

      it "allows teacher to view enrollments for students in their course" do
        teacher_viewing_student = GraphQLTypeTester.new(
          @student,
          current_user: @teacher,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )

        teacher_viewing_student.extract_result = false
        result = teacher_viewing_student.resolve("enrollmentsConnection { nodes { _id } }")
        enrollments_result = result["enrollmentsConnection"]

        actual_ids = enrollments_result["nodes"].pluck("_id")
        expect(actual_ids.length).to eq(1)
        expect(@student.enrollments.pluck(:id).map(&:to_s)).to include(actual_ids.first)
      end

      it "returns empty result when user has no shared courses" do
        separate_course = course_factory
        separate_course.enroll_student(@student, enrollment_state: "active")
        separate_teacher = user_factory
        separate_course.enroll_teacher(separate_teacher, enrollment_state: "active")

        teacher_no_access = GraphQLTypeTester.new(
          @student,
          current_user: separate_teacher,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )

        teacher_no_access.extract_result = false
        result = teacher_no_access.resolve(%|enrollmentsConnection(courseId: "#{@course.id}") { nodes { _id } }|)
        enrollments_result = result["enrollmentsConnection"]

        expect(enrollments_result["nodes"]).to be_empty
      end

      it "allows users to view their own enrollments" do
        user_type.extract_result = false
        result = user_type.resolve("enrollmentsConnection { nodes { _id } }", current_user: @student)
        enrollments_result = result["enrollmentsConnection"]

        expected_ids = @student.enrollments.pluck(:id).map(&:to_param)
        actual_ids = enrollments_result["nodes"].pluck("_id")
        expect(actual_ids).to match_array(expected_ids)
      end

      it "respects course_id filtering with proper permissions" do
        admin_type.extract_result = false
        result = admin_type.resolve(%|enrollmentsConnection(courseId: "#{@course.id}") { nodes { _id } }|)
        enrollments_result = result["enrollmentsConnection"]

        expected_ids = @student.enrollments.where(course: @course).pluck(:id).map(&:to_param)
        actual_ids = enrollments_result["nodes"].pluck("_id")
        expect(actual_ids).to match_array(expected_ids)
      end

      it "returns empty result when requesting course without permissions" do
        user_type.extract_result = false
        result = user_type.resolve(%|enrollmentsConnection(courseId: "#{@other_course.id}") { nodes { _id } }|, current_user: @student)
        enrollments_result = result["enrollmentsConnection"]

        expect(enrollments_result["nodes"]).to be_empty
      end
    end
  end

  context "email" do
    let!(:read_email_override) do
      RoleOverride.create!(
        context: @teacher.account,
        permission: "read_email_addresses",
        role: teacher_role,
        enabled: true
      )
    end

    let!(:admin) { account_admin_user }

    before(:once) do
      @student.update! email: "cooldude@example.com"
    end

    it "returns email for admins" do
      admin_tester = GraphQLTypeTester.new(
        @student,
        current_user: admin,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )

      expect(admin_tester.resolve("email")).to eq @student.email

      # this is for the cached branch
      allow(@student).to receive(:email_cached?).and_return(true)
      expect(admin_tester.resolve("email")).to eq @student.email
    end

    it "returns email for teachers" do
      expect(user_type.resolve("email")).to eq @student.email

      # this is for the cached branch
      allow(@student).to receive(:email_cached?).and_return(true)
      expect(user_type.resolve("email")).to eq @student.email
    end

    it "doesn't return email for others" do
      expect(user_type.resolve("email", current_user: nil)).to be_nil
      expect(user_type.resolve("email", current_user: @other_student)).to be_nil
      expect(user_type.resolve("email", current_user: @random_person)).to be_nil
    end

    it "respects :read_email_addresses permission" do
      read_email_override.update!(enabled: false)

      expect(user_type.resolve("email")).to be_nil
    end

    context "permission check priority" do
      before(:once) do
        @other_student = student_in_course(course: @course).user
      end

      before do
        @resolver = GraphQLTypeTester.new(
          @student,
          current_user: @other_student,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )
      end

      context "with course context" do
        before do
          # Object level permissions should be never called if course is in context
          expect(@student).not_to receive(:grants_right?)
        end

        it "checks account-level permission first" do
          expect(@course.account.root_account).to receive(:grants_right?)
            .with(@admin, :read_email_addresses)
            .and_call_original
          expect(@course).not_to receive(:grants_right?)

          expect(@resolver.resolve("email", current_user: @admin, course: @course)).to eq @student.email
        end

        it "checks course-level permission if account-level fails" do
          expect(@course.account.root_account).to receive(:grants_right?)
            .with(@teacher, :read_email_addresses)
            .and_call_original
          expect(@course).to receive(:grants_right?)
            .with(@teacher, :read_email_addresses)
            .and_call_original

          expect(@resolver.resolve("email", current_user: @teacher, course: @course)).to eq @student.email
        end

        it "returns nil account-level and course-level permission checks fail" do
          expect(@course.account.root_account).to receive(:grants_right?)
            .with(@other_student, :read_email_addresses)
            .and_call_original
          expect(@course).to receive(:grants_right?)
            .with(@other_student, :read_email_addresses)
            .and_call_original

          expect(@resolver.resolve("email", course: @course)).to be_nil
        end
      end

      context "without course context" do
        before do
          # Course-level permissions should be never called if course is not in context
          expect(@course).not_to receive(:grants_right?)
        end

        it "checks account-level permission first" do
          expect(@course.account.root_account).to receive(:grants_right?)
            .with(@admin, :read_email_addresses)
            .and_call_original
          expect(@student).not_to receive(:grants_right?)

          expect(@resolver.resolve("email", current_user: @admin)).to eq @student.email
        end

        it "checks object-level permission if account-level fails" do
          expect(@course.account.root_account).to receive(:grants_right?)
            .with(@teacher, :read_email_addresses)
            .and_call_original

          # Must use any_instance_of because GraphQL's IDLoader reloads User from DB (new instance)
          # allow_any_instance_of: lets ALL grants_right? calls proceed (e.g., :read_full_profile checks)
          # expect_any_instance_of: verifies our specific :read_email_addresses call happens
          allow_any_instance_of(User).to receive(:grants_right?).and_call_original
          expect_any_instance_of(User).to receive(:grants_right?)
            .with(@teacher, :read_email_addresses)
            .and_call_original

          expect(@resolver.resolve("email", current_user: @teacher)).to eq @student.email
        end

        it "returns nil account-level and object-level permission checks fail" do
          expect(@course.account.root_account).to receive(:grants_right?)
            .with(@other_student, :read_email_addresses)
            .and_call_original

          # Must use any_instance_of because GraphQL's IDLoader reloads User from DB (new instance)
          # allow_any_instance_of: lets ALL grants_right? calls proceed (e.g., :read_full_profile checks)
          # expect_any_instance_of: verifies our specific :read_email_addresses call happens
          allow_any_instance_of(User).to receive(:grants_right?).and_call_original
          expect_any_instance_of(User).to receive(:grants_right?)
            .with(@other_student, :read_email_addresses)
            .and_call_original

          expect(@resolver.resolve("email")).to be_nil
        end
      end
    end
  end

  context "groups" do
    before(:once) do
      @user_group_ids = (1..5).map do
        group_with_user({ user: @student, active_all: true }).group_id.to_s
      end
      @deleted_user_group_ids = (1..3).map do
        group = group_with_user({ user: @student, active_all: true })
        group.destroy
        group.group_id.to_s
      end
    end

    it "fetches the groups associated with a user" do
      user_type.resolve("groups { _id }", current_user: @student).all? do |id|
        expect(@user_group_ids.include?(id)).to be true
        expect(@deleted_user_group_ids.include?(id)).to be false
      end
    end

    it "only returns groups for current_user" do
      expect(
        user_type.resolve("groups { _id }", current_user: @teacher)
      ).to be_nil
    end
  end

  context "groupMemberships" do
    before(:once) do
      @group_category_a = @course.group_categories.create!(name: "Test Category A", non_collaborative: true)
      @group_category_b = @course.group_categories.create!(name: "Test Category B", non_collaborative: false)
      @group_a = @course.groups.create!(name: "Group A", group_category: @group_category_a)
      @group_b = @course.groups.create!(name: "Group B", group_category: @group_category_b)

      @gm1 = @group_a.add_user(@student)
      @gm2 = @group_b.add_user(@student)
    end

    it "returns group memberships for the user" do
      expect(
        user_type.resolve("groupMemberships { group { _id } }")
      ).to match_array [@gm1.group.id.to_s, @gm2.group.id.to_s]
    end
  end

  context "notificationPreferences" do
    it "returns the users notification preferences" do
      Notification.delete_all
      @student.communication_channels.create!(path: "test@test.com").confirm!
      notification_model(name: "test", category: "Announcement")

      expect(
        user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }")[0][0]
      ).to eq "test"
    end

    it "only returns active communication channels" do
      Notification.delete_all
      communication_channel = @student.communication_channels.create!(path: "test@test.com")
      communication_channel.confirm!
      notification_model(name: "test", category: "Announcement")

      expect(
        user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }")[0][0]
      ).to eq "test"

      communication_channel.destroy
      expect(
        user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }").count
      ).to eq 0
    end

    context "when the requesting user does not have permission to view the communication channels" do
      let(:user_type) do
        GraphQLTypeTester.new(
          @student,
          current_user: @other_student,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )
      end

      it "returns nil" do
        expect(
          user_type.resolve("notificationPreferences { channels { notificationPolicies(contextType: Course) { notification { name } } } }")
        ).to be_nil
      end
    end
  end

  context "differentiation_tags_connection" do
    def resolve_user_type(course_id = @course.id)
      user_type.resolve(%|differentiationTagsConnection(courseId: "#{course_id}") { edges { node { group { _id name } } } }|)
    end

    it "calls the DifferentiationTagsLoader" do
      loader_instance = instance_double(GraphQL::Schema::Loader)
      expect(loader_instance).to receive(:load).with(@student.id).and_return([])
      expect(Loaders::UserLoaders::DifferentiationTagsLoader)
        .to receive(:for)
        .and_return(loader_instance)

      resolve_user_type
    end

    it "passes correct parameters to the the DifferentiationTagsLoader" do
      loader_instance = instance_double(GraphQL::Schema::Loader)
      expect(loader_instance).to receive(:load).with(@student.id).and_return([])
      expect(Loaders::UserLoaders::DifferentiationTagsLoader)
        .to receive(:for)
        .with(@teacher, @course.id.to_s)
        .and_return(loader_instance)

      resolve_user_type
    end
  end

  context "conversations" do
    it "returns conversations for the user" do
      c = conversation(@student, @teacher)
      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      expect(
        type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")[0][0]
      ).to eq c.conversation.conversation_messages.first.body
    end

    context "with horizon courses" do
      before do
        # Create a horizon course and conversation
        @course.update!(horizon_course: true)
        @course.account.enable_feature!(:horizon_course_setting)
        @course.enroll_student(@student, enrollment_state: "active")
        @course.save!
        # Pass the actual course object as context
        @horizon_convo = conversation(@student, @teacher, body: "Horizon")
      end

      after do
        @course.update!(horizon_course: false)
        @course.account.disable_feature!(:horizon_course_setting)
        @horizon_convo.destroy
      end

      it "excludes horizon conversations by default" do
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        result = type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
        expect(result.flatten).not_to include(@horizon_convo.conversation.conversation_messages.first.body)
      end

      it "excludes horizon conversations if showHorizonConversations is false" do
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        result = type.resolve("conversationsConnection(showHorizonConversations: false) { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
        expect(result.flatten).not_to include(@horizon_convo.conversation.conversation_messages.first.body)
      end

      it "includes horizon conversations when explicitly requested" do
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        result = type.resolve("conversationsConnection(showHorizonConversations: true) { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
        expect(result.flatten).to include(@horizon_convo.conversation.conversation_messages.first.body)
      end
    end

    context "recipient user deleted" do
      def delete_recipient
        # The short issue is CP and CMP are not fk attached to the user, but our code expects an associated user.
        # As a result the below specs give us options to handle when a user is hard deleted without cleanup.
        # The CMP requires that the cmp.workflow_state == deleted;
        # there is no way around this because the loader takes an array of cmps and it would defeat the purpose to check user beforehand.
        # Thus for now we handle this and return null which can be processed.

        conversation(@student, sender: @teacher)

        # delete student
        student_id = @student.id

        # delete enrollments can run in a loop if multiple
        enrollment = @student.enrollments.first
        enrollment_state = enrollment.enrollment_state
        enrollment_state.delete
        enrollment.delete

        # delete stream_item_instances can run in a loop if multiple
        stream_item_instance = @student.stream_item_instances.first
        stream_item_instance.delete

        # delete user_account_associations can run in a loop if multiple
        user_account_association = @student.user_account_associations.first
        user_account_association.delete

        @student.delete

        # deleting the cmp
        # the problem cp:  cp_without_associated_user = ConversationParticipant.where(user_id: student_id).first
        cmp_without_associated_user = ConversationMessageParticipant.where(user_id: student_id).first
        cmp_without_associated_user.workflow_state = "deleted"
        cmp_without_associated_user.save

        student_id
      end

      it "returns empty recipients" do
        delete_recipient
        type = GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @teacher.account, request: ActionDispatch::TestRequest.create)

        recipients_ids = type.resolve("
        conversationsConnection(scope: \"sent\") {
          nodes {
            conversation {
              conversationMessagesConnection {
                nodes {
                  recipients {
                    _id
                  }
                }
              }
            }
          }
        }
        ")
        expect(recipients_ids[0][0].empty?).to be true
      end

      context "ConversationMessageParticipant.workflow_state deleted" do
        it "returns nil for user" do
          student_id = delete_recipient
          type = GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @teacher.account, request: ActionDispatch::TestRequest.create)
          cmps_ids = type.resolve("
            conversationsConnection(scope: \"sent\") {
              nodes {
                conversation {
                  conversationParticipantsConnection {
                    nodes {
                      user {
                        _id
                      }
                    }
                  }
                }
              }
            }
            ")
          expect(cmps_ids[0].include?(@teacher.id.to_s)).to be true
          expect(cmps_ids[0].include?(student_id.to_s)).to be false
        end
      end
    end

    it "has createdAt field for conversationMessagesConnection" do
      Timecop.freeze do
        c = conversation(@student, @teacher)
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        expect(
          type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { createdAt } } } } }")[0][0]
        ).to eq c.conversation.conversation_messages.first.created_at.iso8601
      end
    end

    it "has updatedAt field for conversations and conversationParticipants" do
      Timecop.freeze do
        convo = conversation(@student, @teacher)
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        res_node = type.resolve("conversationsConnection { nodes { updatedAt }}")[0]
        expect(res_node).to eq convo.conversation.conversation_participants.first.updated_at.iso8601
      end
    end

    it "has updatedAt field for conversationParticipantsConnection" do
      Timecop.freeze do
        convo = conversation(@student, @teacher)
        type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
        res_node = type.resolve("conversationsConnection { nodes { conversation { conversationParticipantsConnection { nodes { updatedAt } } } } }")[0][0]
        expect(res_node).to eq convo.conversation.conversation_participants.first.updated_at.iso8601
      end
    end

    it "does not return conversations for other users" do
      conversation(@student, @teacher)
      type = GraphQLTypeTester.new(@teacher, current_user: @student, domain_root_account: @teacher.account, request: ActionDispatch::TestRequest.create)
      expect(
        type.resolve("conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
      ).to be_nil
    end

    it "filters the conversations" do
      conversation(@student, @teacher, { body: "Howdy Partner" })
      conversation(@student, @random_person, { body: "Not in course" })
      conversation(@student, @ta, { body: "Hey Im using SimpleTags tagged_scope_handler." })

      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection(filter: \"course_#{@course.id}\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 2
      expect(result.flatten).to match_array ["Howdy Partner", "Hey Im using SimpleTags tagged_scope_handler."]

      result = type.resolve(
        "conversationsConnection(filter: \"user_#{@ta.id}\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
      expect(result[0][0]).to eq "Hey Im using SimpleTags tagged_scope_handler."

      result = type.resolve(
        "conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 3
      expect(result.flatten).to match_array ["Howdy Partner", "Not in course", "Hey Im using SimpleTags tagged_scope_handler."]

      result = type.resolve(
        "conversationsConnection(filter: [\"user_#{@ta.id}\", \"course_#{@course.id}\"]) { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
      expect(result[0][0]).to eq "Hey Im using SimpleTags tagged_scope_handler."
    end

    it "returns the conversations without conversation participants" do
      conversation(@student, @teacher, { body: "Hello, Mr White" })
      conversation_participant = conversation(@student, @teacher, { body: "Hello??" })

      # Delete the conversation but leave the conversation_participants orphaned
      conversation_participant.conversation.conversation_messages.destroy_all
      conversation_participant.conversation.delete

      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
    end

    it "scopes the conversations" do
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      conversation(@student, @teacher, { body: "You get that thing I sent ya?" })
      conversation(@teacher, @student, { body: "oh yea =)" })
      conversation(@student, @random_person, { body: "Whats up?", starred: true })

      # used for the sent scope
      conversation(@random_person, @teacher, { body: "Help! Please make me non-random!" })
      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection(scope: \"inbox\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.flatten.count).to eq 3
      expect(result.flatten).to match_array ["You get that thing I sent ya?", "oh yea =)", "Whats up?"]
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("inbox.visit.scope.inbox.pages_loaded.react")

      result = type.resolve(
        "conversationsConnection(scope: \"starred\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.count).to eq 1
      expect(result[0][0]).to eq "Whats up?"
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("inbox.visit.scope.starred.pages_loaded.react")

      type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      result = type.resolve(
        "conversationsConnection(scope: \"unread\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }"
      )
      expect(result.flatten.count).to eq 2
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("inbox.visit.scope.unread.pages_loaded.react")

      type = GraphQLTypeTester.new(
        @random_person,
        current_user: @random_person,
        domain_root_account: @random_person.account,
        request: ActionDispatch::TestRequest.create
      )
      result = type.resolve("conversationsConnection(scope: \"sent\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
      expect(result[0][0]).to eq "Help! Please make me non-random!"
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("inbox.visit.scope.sent.pages_loaded.react")

      @conversation.update!(workflow_state: "archived")
      type = GraphQLTypeTester.new(
        @random_person,
        current_user: @random_person,
        domain_root_account: @random_person.account,
        request: ActionDispatch::TestRequest.create
      )
      result = type.resolve("conversationsConnection(scope: \"archived\") { nodes { conversation { conversationMessagesConnection { nodes { body } } } } }")
      expect(result[0][0]).to eq "Help! Please make me non-random!"
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("inbox.visit.scope.archived.pages_loaded.react")
      @conversation.update!(workflow_state: "read")
    end
  end

  context "recipients" do
    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    let(:teacher_type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    let(:ta_type) do
      GraphQLTypeTester.new(
        @ta,
        current_user: @ta,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns nil if the user is not the current user" do
      result = user_type.resolve("recipients { usersConnection { nodes { _id } } }")
      expect(result).to be_nil
    end

    context "when feature is disabled" do
      it "returns known users including students" do
        known_users = @student.address_book.search_users.paginate(per_page: 4)
        result = type.resolve("recipients { usersConnection { nodes { _id } } }")
        expect(result).to match_array(known_users.pluck(:id).map(&:to_s))
      end
    end

    context "when feature is enabled" do
      before { @student.account.root_account.enable_feature!(:restrict_student_access) }

      it "returns known users without students" do
        result = type.resolve("recipients { usersConnection { nodes { _id } } }")
        expect(result).to match_array([@teacher.id.to_s])
      end
    end

    it "returns contexts" do
      result = type.resolve("recipients { contextsConnection { nodes { name } } }")
      expect(result[0]).to eq(@course.name)
    end

    it "returns false for sendMessagesAll if no context is given" do
      result = type.resolve("recipients { sendMessagesAll }")
      expect(result).to be(false)
    end

    it "returns false for sendMessagesAll if not allowed" do
      # Students do not have the sendMessagesAll permission by default
      result = type.resolve("recipients(context: \"course_#{@course.id}_students\") { sendMessagesAll }")
      expect(result).to be(false)
    end

    it "returns true for sendMessagesAll if allowed" do
      @random_person.account.role_overrides.create!(permission: :send_messages_all, role: student_role, enabled: true)

      result = type.resolve("recipients(context: \"course_#{@course.id}_students\") { sendMessagesAll }")
      expect(result).to be(true)
    end

    it "searches users" do
      known_users = @student.address_book.search_users.paginate(per_page: 3)
      User.find(known_users.first.id).update!(name: "Matthew Lemon")
      result = type.resolve('recipients(search: "lemon") { usersConnection { nodes { _id } } }')
      expect(result[0]).to eq(known_users.first.id.to_s)

      result = type.resolve('recipients(search: "morty") { usersConnection { nodes { _id } } }')
      expect(result).to be_empty
    end

    it "searches contexts" do
      result = type.resolve('recipients(search: "unnamed") { contextsConnection { nodes { name } } }')
      expect(result[0]).to eq(@course.name)

      result = type.resolve('recipients(search: "Lemon") { contextsConnection { nodes { name } } }')
      expect(result).to be_empty
    end

    it "filters results based on context" do
      known_users = @student.address_book.search_users(context: "course_#{@course.id}_students").paginate(per_page: 3)
      result = type.resolve("recipients(context: \"course_#{@course.id}_students\") { usersConnection { nodes { _id } } }")
      expect(result).to match_array(known_users.pluck(:id).map(&:to_s))
    end

    context "differentiation tags" do
      before do
        Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
        Account.default.save!
        Account.default.reload
        @collaborative_category = @course.group_categories.create!(name: "Collaborative Category", non_collaborative: false)
        @collaborative_group = @course.groups.create!(name: "Collaborative group", group_category: @collaborative_category)
        @collaborative_group.add_user(@student)

        @non_collaborative_category = @course.group_categories.create!(name: "Non-Collaborative Category", non_collaborative: true)
        @non_collaborative_group = @course.groups.create!(name: "non Collaborative group", group_category: @non_collaborative_category)
        @non_collaborative_group.add_user(@student)
      end

      describe "teacher type" do
        it "returns differentiation tags" do
          result = teacher_type.resolve("recipients(context: \"course_#{@course.id}\") { contextsConnection { nodes { name } } }")
          expect(result).to include("Differentiation Tags")
        end

        it "returns differentiation tag details" do
          result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_differentiation_tags\") { contextsConnection { nodes { name } } }")
          expect(result).to eq(["non Collaborative group"])
        end

        it "returns differentiation tag users" do
          result = teacher_type.resolve("recipients(context: \"differentiation_tag_#{@non_collaborative_group.id}\") { usersConnection { nodes { name } } }")
          expect(result).to eq([@student.name])
        end

        it "returns group tag users" do
          result = teacher_type.resolve("recipients(context: \"group_#{@collaborative_group.id}\") { usersConnection { nodes { name } } }")
          expect(result).to eq([@student.name])
        end

        it "does not return differentiation tags when flag is off" do
          Account.default.settings[:allow_assign_to_differentiation_tags] = { value: false }
          Account.default.save!
          Account.default.reload

          result = teacher_type.resolve("recipients(context: \"course_#{@course.id}\") { contextsConnection { nodes { name } } }")
          expect(result).not_to include("Differentiation Tags")
        end
      end

      describe "student type" do
        it "does not return differentiation tags" do
          result = type.resolve("recipients(context: \"course_#{@course.id}\") { contextsConnection { nodes { name } } }")
          expect(result).not_to include("Differentiation Tags")
        end

        it "does not return differentiation tag details" do
          result = type.resolve("recipients(context: \"course_#{@course.id}_differentiation_tags\") { contextsConnection { nodes { name } } }")
          expect(result).to eq([])
        end

        it "does not return differentiation tag users" do
          result = type.resolve("recipients(context: \"differentiation_tag_#{@non_collaborative_group.id}\") { usersConnection { nodes { name } } }")
          expect(result).to eq([])
        end

        it "does not allow circumventing permissions by calling group" do
          result = type.resolve("recipients(context: \"group_#{@non_collaborative_group.id}\") { usersConnection { nodes { name } } }")
          expect(result).to eq([])
        end
      end

      describe "ta type" do
        it "does not return differentiation tags" do
          result = ta_type.resolve("recipients(context: \"course_#{@course.id}\") { contextsConnection { nodes { name } } }")
          expect(result).not_to include("Differentiation Tags")
        end

        it "does not return differentiation tag details" do
          result = ta_type.resolve("recipients(context: \"course_#{@course.id}_differentiation_tags\") { contextsConnection { nodes { name } } }")
          expect(result).to eq([])
        end

        it "does not return differentiation tag users" do
          result = ta_type.resolve("recipients(context: \"differentiation_tag_#{@non_collaborative_group.id}\") { usersConnection { nodes { name } } }")
          expect(result).to eq([])
        end

        it "does not allow circumventing permissions by calling group" do
          result = ta_type.resolve("recipients(context: \"group_#{@non_collaborative_group.id}\") { usersConnection { nodes { name } } }")
          expect(result).to eq([])
        end
      end
    end
  end

  context "observerEnrollmentsConnection" do
    specs_require_sharding

    let(:teacher_type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    let(:student_type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    before do
      @shard1.activate do
        @student1 = student_in_course(active_all: true).user
        @student2 = student_in_course(active_all: true).user

        @student1_observer = observer_in_course(active_all: true, associated_user_id: @student1).user
        @student2_observer = observer_in_course(active_all: true, associated_user_id: @student2).user
      end

      @shard2.activate do
        @student2_observer2 = User.create
        enrollment = @course.enroll_user(@student2_observer2, "ObserverEnrollment")
        enrollment.associated_user = @student2
        enrollment.workflow_state = "active"
        enrollment.save
      end
    end

    it "returns associatedUser ids" do
      result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_observers\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"course_#{@course.id}\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([[@student1.id.to_s], [@student2.id.to_s], [@student2.id.to_s]])
    end

    it "returns empty associatedUser ids" do
      result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_students\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"course_#{@course.id}\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([[], [], [], []])
    end

    it "returns nil when context is empty" do
      result = teacher_type.resolve("recipients(context: \"course_#{@course.id}_observers\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([nil, nil, nil])
    end

    it "returns nil when not teacher" do
      result = student_type.resolve("recipients(context: \"course_#{@course.id}_observers\") { usersConnection { nodes { observerEnrollmentsConnection(contextCode: \"\") { nodes { associatedUser { _id } } } } } }")
      expect(result).to match_array([nil, nil])
    end
  end

  context "total_recipients" do
    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns total_recipients for given context (excluding current_user)" do
      result = type.resolve("totalRecipients(context: \"course_#{@course.id}\")")
      expect(result).to eq(@course.enrollments.count - 1)
    end
  end

  context "recipients_observers" do
    let(:student_type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    let(:teacher_type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    before do
      student = @student
      @third_student = student_in_course(active_all: true).user
      @fourth_student = student_in_course(active_all: true).user
      @student = student

      observer = observer_in_course(active_all: true, associated_user_id: @student).user
      observer_enrollment_2 = @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
      observer_enrollment_2.update_attribute(:associated_user_id, @other_student.id)

      observer_enrollment_3 = @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active")
      observer_enrollment_3.update_attribute(:associated_user_id, @third_student.id)

      second_observer = observer_in_course(active_all: true, associated_user_id: @fourth_student).user

      @observer = observer
      @second_observer = second_observer
    end

    it "returns nil if the user is not the current user" do
      result = teacher_type.resolve('recipientsObservers(contextCode: "course_1", recipientIds: ["1"]) { nodes { _id } } ')
      expect(result).to be_nil
    end

    it "returns nil if invalid course is given" do
      result = teacher_type.resolve('recipientsObservers(contextCode: "fake_2", recipientIds: ["1"]) { nodes { _id } } ')
      expect(result).to be_nil
    end

    it "returns a users observers as messageable user" do
      recipients = [@student.id.to_s]
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result).to eq [@observer.id.to_s]
    end

    it "does not return observers that are not active" do
      inactive_observer = User.create
      inactive_observer_enrollment = @course.enroll_user(inactive_observer, "ObserverEnrollment", enrollment_state: "completed")
      inactive_observer_enrollment.update_attribute(:associated_user_id, @student.id)
      recipients = [@student.id.to_s]
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result).not_to include(inactive_observer.id.to_s)
    end

    it "does not return duplicate observers if an observer is observing multiple students in the course" do
      recipients = [@student, @other_student, @third_student].map { |u| u.id.to_s }
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result).to eq [@observer.id.to_s]
    end

    it "returns observers for all students in a course if the entire course is a recipient and current user can send observers messages" do
      recipients = ["course_#{@course.id}"]
      result = teacher_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @teacher)
      expect(result.length).to eq 2
      expect(result).to include(@observer.id.to_s, @second_observer.id.to_s)
    end

    it "does not return observers that the current user is unable to message" do
      recipients = ["course_#{@course.id}"]
      result = student_type.resolve("recipientsObservers(contextCode: \"course_#{@course.id}\", recipientIds: #{recipients}) { nodes { _id } } ", current_user: @student)
      expect(result.length).to eq 1
      expect(result).to include(@student.observee_enrollments.first.user.id.to_s)
    end
  end

  context "favorite_courses" do
    before(:once) do
      @course1 = @course
      course_with_user("StudentEnrollment", user: @student, active_all: true)
      @course2 = @course
    end

    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns primary enrollment courses if there are no favorite courses" do
      result = type.resolve("favoriteCoursesConnection { nodes { _id } }")
      expect(result).to match_array([@course1.id.to_s, @course2.id.to_s])
    end

    it "returns favorite courses" do
      @student.favorites.create!(context: @course1)
      result = type.resolve("favoriteCoursesConnection { nodes { _id } }")
      expect(result).to match_array([@course1.id.to_s])
    end

    context "dashboard_card" do
      it "returns the correct dashboard cards if there are no favorite courses" do
        result = type.resolve("favoriteCoursesConnection { nodes { dashboardCard { assetString } } }")
        expect(result).to match_array([@course1.asset_string, @course2.asset_string])
      end

      it "returns the correct dashboard cards if there are favorite courses" do
        @student.favorites.create!(context: @course1)
        result = type.resolve("favoriteCoursesConnection { nodes { dashboardCard { assetString } } }")
        expect(result).to match_array([@course1.asset_string])
      end

      it "caches dashboard card counts" do
        @cur_teacher = course_with_teacher(active_all: true).user
        @published_course = @course
        @unpublished_course = course_factory(active_course: false)
        @unpublished_course.enroll_teacher(@cur_teacher).accept!

        teacher_type = GraphQLTypeTester.new(
          @cur_teacher,
          current_user: @cur_teacher,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create
        )

        enable_cache do
          teacher_type.resolve("favoriteCoursesConnection { nodes { dashboardCard { assetString } } }")
          published_count = Rails.cache.read(["last_known_dashboard_cards_published_count", @cur_teacher.global_id].cache_key)
          unpublished_count = Rails.cache.read(["last_known_dashboard_cards_unpublished_count", @cur_teacher.global_id].cache_key)
          expect(published_count).to eq 1
          expect(unpublished_count).to eq 1

          # Publish the unpublished course
          @unpublished_course.offer!
          teacher_type.resolve("favoriteCoursesConnection { nodes { dashboardCard { assetString } } }")
          published_count = Rails.cache.read(["last_known_dashboard_cards_published_count", @cur_teacher.global_id].cache_key)
          unpublished_count = Rails.cache.read(["last_known_dashboard_cards_unpublished_count", @cur_teacher.global_id].cache_key)
          expect(published_count).to eq 2
          expect(unpublished_count).to eq 0
        end
      end

      it "caches dashboard card counts for k5" do
        k5_account = Account.create!(name: "K5 Elementary")
        toggle_k5_setting(k5_account)
        @cur_teacher = user_factory(active_all: true)
        @k5_course1 = course_factory(course_name: "K5 Course 1", active_all: true, account: k5_account)
        @k5_course1.enroll_teacher(@cur_teacher, enrollment_state: "active")

        teacher_type = GraphQLTypeTester.new(
          @cur_teacher,
          current_user: @cur_teacher,
          domain_root_account: k5_account.root_account,
          request: ActionDispatch::TestRequest.create
        )

        enable_cache do
          teacher_type.resolve("favoriteCoursesConnection { nodes { dashboardCard { assetString } } }")
          k5_count = Rails.cache.read(["last_known_k5_cards_count", @cur_teacher.global_id].cache_key)
          expect(k5_count).to eq 1

          # Create and add a new K5 course
          @k5_course2 = course_factory(course_name: "K5 Course 2", active_all: true, account: k5_account)
          @k5_course2.enroll_teacher(@cur_teacher, enrollment_state: "active")
          teacher_type.resolve("favoriteCoursesConnection { nodes { dashboardCard { assetString } } }")
          k5_count = Rails.cache.read(["last_known_k5_cards_count", @cur_teacher.global_id].cache_key)
          expect(k5_count).to eq 2
        end
      end
    end
  end

  context "favorite_groups" do
    let(:type) do
      GraphQLTypeTester.new(
        @student,
        current_user: @student,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns all groups if there are no favorite groups" do
      group_with_user(user: @student, active_all: true)
      result = type.resolve("favoriteGroupsConnection { nodes { _id } }")
      expect(result).to match_array([@group.id.to_s])
    end

    it "return favorite groups" do
      2.times do
        group_with_user(user: @student, active_all: true)
      end
      @student.favorites.create!(context: @group)
      result = type.resolve("favoriteGroupsConnection { nodes { _id } }")
      expect(result).to match_array([@group.id.to_s])
    end

    it "includes non_collaborative group when asked for by someone with permissions" do
      Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
      Account.default.save!
      Account.default.reload
      allow_any_instance_of(Course).to receive(:grants_any_right?).with(@student, anything, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS).and_return(true)

      @non_collaborative_category = @course.group_categories.create!(name: "Non-Collaborative Groups", non_collaborative: true)
      group_with_user(user: @student, active_all: true)
      favorite_group = @group
      @student.favorites.create!(context: favorite_group)

      hidden_group_membership = group_with_user(user: @student, active_all: true, group_category: @non_collaborative_category, context: @course)
      hidden_group = hidden_group_membership.group
      @student.favorites.create!(context: hidden_group)
      allow(hidden_group).to receive(:grants_any_right?).and_return(true)

      result = type.resolve("favoriteGroupsConnection(includeNonCollaborative: true) { nodes { _id } }")
      expect(result).to match_array([favorite_group.id.to_s, hidden_group.id.to_s])
    end

    it "excludes non_collaborative groups when asked for by someone without permissions" do
      Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
      Account.default.save!
      Account.default.reload
      @non_collaborative_category = @course.group_categories.create!(name: "Non-Collaborative Groups", non_collaborative: true)
      group_with_user(user: @student, active_all: true)
      favorite_group = @group
      @student.favorites.create!(context: favorite_group)

      hidden_group_membership = group_with_user(user: @student, active_all: true, group_category: @non_collaborative_category, context: @course)
      hidden_group = hidden_group_membership.group
      @student.favorites.create!(context: hidden_group)

      result = type.resolve("favoriteGroupsConnection { nodes { _id } }")
      expect(result).to match_array([favorite_group.id.to_s])
    end

    it "excludes non_collaborative groups when asked for by someone without permissions and no favorite groups" do
      Account.default.settings[:allow_assign_to_differentiation_tags] = { value: true }
      Account.default.save!
      Account.default.reload
      @non_collaborative_category = @course.group_categories.create!(name: "Non-Collaborative Groups", non_collaborative: true)

      hidden_group_membership = group_with_user(user: @student, active_all: true, group_category: @non_collaborative_category, context: @course)
      hidden_group = hidden_group_membership.group
      @student.favorites.create!(context: hidden_group)

      result = type.resolve("favoriteGroupsConnection { nodes { _id } }")
      expect(result).to be_empty
    end
  end

  context "CommentBankItemsConnection" do
    before do
      @comment_bank_item = comment_bank_item_model(user: @teacher, context: @course, comment: "great comment!")
    end

    let(:type) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns comment bank items for the queried user" do
      expect(
        type.resolve("commentBankItemsConnection { nodes { _id } }")
      ).to eq [@comment_bank_item.id.to_s]
    end

    describe "cross sharding" do
      specs_require_sharding

      it "returns comments across shards" do
        @shard1.activate do
          account = Account.create!(name: "new shard account")
          @course2 = course_factory(account:)
          @course2.enroll_user(@teacher)
          @comment2 = comment_bank_item_model(user: @teacher, context: @course2, comment: "shard 2 comment")
        end

        expect(
          type.resolve("commentBankItemsConnection { nodes { comment } }").sort
        ).to eq ["great comment!", "shard 2 comment"]
      end
    end

    describe "with the limit argument" do
      before do
        allow(InstStatsd::Statsd).to receive(:distributed_increment)
      end

      it "returns a limited number of results" do
        comment_bank_item_model(user: @teacher, context: @course, comment: "2nd great comment!")
        expect(
          type.resolve("commentBankItemsConnection(limit: 1) { nodes { comment } }").length
        ).to eq 1
      end

      context "with send_metrics_for_comment_bank_items_connection_limit_used ON" do
        before do
          Account.site_admin.enable_feature!(:send_metrics_for_comment_bank_items_connection_limit_used)
        end

        it "reports metrics when limit is used" do
          comment_bank_item_model(user: @teacher, context: @course, comment: "2nd great comment!")
          type.resolve("commentBankItemsConnection(limit: 1) { nodes { comment } }")
          expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
            "graphql.user_type.comment_bank_items_connection.limit_used",
            { tags: { cluster: "test" } }
          )
        end
      end

      context "with send_metrics_for_comment_bank_items_connection_limit_used OFF" do
        before do
          Account.site_admin.disable_feature!(:send_metrics_for_comment_bank_items_connection_limit_used)
        end

        it "does not report metrics when limit is used" do
          comment_bank_item_model(user: @teacher, context: @course, comment: "2nd great comment!")
          type.resolve("commentBankItemsConnection(limit: 1) { nodes { comment } }")
          expect(InstStatsd::Statsd).not_to have_received(:distributed_increment).with(
            "graphql.user_type.comment_bank_items_connection.limit_used",
            anything
          )
        end
      end
    end

    describe "with a search query" do
      before do
        @comment_bank_item2 = comment_bank_item_model(user: @teacher, context: @course, comment: "new comment!")
      end

      it "returns results that match the query" do
        expect(
          type.resolve("commentBankItemsConnection(query: \"new\") { nodes { _id } }").length
        ).to eq 1
      end

      it "strips leading/trailing white space" do
        expect(
          type.resolve("commentBankItemsConnection(query: \"    new   \") { nodes { _id } }").length
        ).to eq 1
      end

      it "does not query results if query.strip is blank" do
        expect(
          type.resolve("commentBankItemsConnection(query: \"  \") { nodes { _id } }").length
        ).to eq 2
      end
    end
  end

  context "courseBuiltInRoles" do
    before do
      @teacher_with_multiple_roles = user_factory(name: "blah")
      @course.enroll_user(@teacher_with_multiple_roles, "TeacherEnrollment")
      @course.enroll_user(@teacher_with_multiple_roles, "TaEnrollment", allow_multiple_enrollments: true)

      @custom_teacher = user_factory(name: "blah")
      role = custom_teacher_role("CustomTeacher", account: @course.account)
      @course.enroll_user(@custom_teacher, "TeacherEnrollment", role:)

      @teacher_with_duplicate_roles = user_factory(name: "blah")
      @course.enroll_user(@teacher_with_duplicate_roles, "TeacherEnrollment")
      @course.enroll_user(@teacher_with_duplicate_roles, "TeacherEnrollment", allow_multiple_enrollments: true)
    end

    let(:user_ta_type) do
      GraphQLTypeTester.new(@ta, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:user_teacher_type) do
      GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:teacher_ta_type) do
      GraphQLTypeTester.new(@teacher_with_multiple_roles, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:teacher_with_duplicate_role_types) do
      GraphQLTypeTester.new(@teacher_with_duplicate_roles, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    let(:custom_teacher_type) do
      GraphQLTypeTester.new(@custom_teacher, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    it "correctly returns default teacher role" do
      expect(
        user_teacher_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to eq ["TeacherEnrollment"]
    end

    it "correctly returns default TA role" do
      expect(
        user_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to eq ["TaEnrollment"]
    end

    it "does not return student role" do
      expect(
        user_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "returns nil when no course id is given" do
      expect(
        user_type.resolve(%|courseRoles(roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "returns nil when course id is null" do
      expect(
        user_type.resolve(%|courseRoles(courseId: null, roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "does not return custom roles based on teacher" do
      expect(
        custom_teacher_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to be_nil
    end

    it "Returns multiple roles when mutiple enrollments exist" do
      expect(
        teacher_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to include("TaEnrollment", "TeacherEnrollment")
    end

    it "does not return duplicate roles when mutiple enrollments exist" do
      expect(
        teacher_with_duplicate_role_types.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment","TeacherEnrollment"])|)
      ).to eq ["TeacherEnrollment"]
    end

    it "returns all roles if no role types are specified" do
      expect(
        teacher_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}")|)
      ).to include("TaEnrollment", "TeacherEnrollment")
    end

    it "returns only the role specified" do
      expect(
        teacher_ta_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TaEnrollment"])|)
      ).to eq ["TaEnrollment"]
    end

    it "returns custom role's base_type if built_in_only is set to false" do
      expect(
        custom_teacher_type.resolve(%|courseRoles(courseId: "#{@course.id}", roleTypes: ["TeacherEnrollment"], builtInOnly: false)|)
      ).to eq ["TeacherEnrollment"]
    end
  end

  describe "course_progression" do
    let(:progress_helper) do
      progress_helper = instance_double(CourseProgress)
      allow(progress_helper).to receive_messages(can_evaluate_progression?: true, normalized_requirement_count: 1)
      progress_helper
    end

    before do
      allow(CourseProgress).to receive(:new).and_return(progress_helper)
    end

    it "returns nil in a non-course context" do
      type = GraphQLTypeTester.new(@student, current_user: @student)

      expect(type.resolve("courseProgression { requirements { total } }")).to be_nil
    end

    it "returns nil when progress cannot be evaluated" do
      type = GraphQLTypeTester.new(@student, current_user: @teacher, course: @course)

      expect(progress_helper).to receive(:can_evaluate_progression?).and_return(false)
      expect(type.resolve("courseProgression { requirements { total } }")).to be_nil
    end

    context "for a user with view_all_grades permission in the course" do
      it "returns progression for another user" do
        type = GraphQLTypeTester.new(@student, current_user: @teacher, course: @course)

        expect(type.resolve("courseProgression { requirements { total } }")).to be_truthy
      end
    end

    context "for a user without view_all_grades permission in the course" do
      it "does not return progression for another user" do
        type = GraphQLTypeTester.new(@student, current_user: @other_student, course: @course)

        expect(type.resolve("courseProgression { requirements { total } }")).to be_nil
      end

      it "returns progression for self" do
        type = GraphQLTypeTester.new(@student, current_user: @student, course: @course)

        expect(type.resolve("courseProgression { requirements { total } }")).to be_truthy
      end
    end
  end

  describe "submission comments" do
    before(:once) do
      course = Course.create! name: "TEST"
      course_2 = Course.create! name: "TEST 2"

      # these 'course_with_user' will  reassign @course
      @teacher = course_with_user("TeacherEnrollment", course:, name: "Mr Teacher", active_all: true).user
      @teacher = course_with_user("TeacherEnrollment", course: course_2, user: @teacher, active_all: true).user
      @student = course_with_user("StudentEnrollment", course:, name: "Mr Student 1", active_all: true).user
      @student_2 = course_with_user("StudentEnrollment", course:, name: "Mr Student 2", active_all: true).user
      @student_2 = course_with_user("StudentEnrollment", course: course_2, user: @student_2, active_all: true).user

      @course = course
      @course_2 = course_2
      assignment = @course.assignments.create!(
        name: "Test Assignment",
        moderated_grading: true,
        grader_count: 10,
        final_grader: @teacher
      )
      @assignment2 = @course.assignments.create!(
        name: "Assignment without Comments",
        moderated_grading: true,
        grader_count: 10,
        final_grader: @teacher
      )
      @assignment3 = @course_2.assignments.create!(
        name: "Assignment without Comments 2",
        moderated_grading: true,
        grader_count: 10,
        final_grader: @teacher
      )

      assignment.grade_student(@student, grade: 1, grader: @teacher, provisional: true)
      @assignment2.grade_student(@student, grade: 1, grader: @teacher, provisional: true)
      @assignment2.grade_student(@student_2, grade: 1, grader: @teacher, provisional: true)
      @assignment3.grade_student(@student_2, grade: 1, grader: @teacher, provisional: true)

      @student_submission_1 = assignment.submissions.find_by(user: @student)

      @sc1 = @student_submission_1.add_comment(author: @student, comment: "First comment")
      @sc2 = @student_submission_1.add_comment(author: @teacher, comment: "Second comment")
      @sc3 = @student_submission_1.add_comment(author: @teacher, comment: "Third comment")
    end

    let(:teacher_type) do
      GraphQLTypeTester.new(@teacher, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
    end

    describe "viewableSubmissionsConnection field" do
      it "only gets submissions with comments" do
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")
        expect(query_result.count).to eq 1
        expect(query_result[0].to_i).to eq @student_submission_1.id
      end

      it "gets submissions with comments in order of last_comment_at DESC" do
        student_submission_2 = @assignment2.submissions.find_by(user: @student)
        student_submission_2.add_comment(author: @student, comment: "Fourth comment")
        student_submission_2.add_comment(author: @teacher, comment: "Fifth comment")

        student_submission_2.update_attribute(:last_comment_at, 1.day.ago)
        @student_submission_1.update_attribute(:last_comment_at, 2.days.ago)

        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")

        expect(query_result.count).to eq 2
        expect(query_result[0].to_i).to eq student_submission_2.id
      end

      it "gets submissions with comments in order of last submission comment if last_comment_at is nil" do
        student_submission_2 = @assignment2.submissions.find_by(user: @student)
        student_submission_2.add_comment(author: @student, comment: "Fourth comment")
        student_submission_2.add_comment(author: @teacher, comment: "Fifth comment")

        student_submission_2.update_attribute(:last_comment_at, nil)
        @student_submission_1.update_attribute(:last_comment_at, nil)

        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")

        expect(query_result.count).to eq 2
        expect(query_result[0].to_i).to eq student_submission_2.id
      end

      it "gets submissions with comments in order of last submission comment over last_comment_at" do
        student_submission_2 = @assignment2.submissions.find_by(user: @student)

        @student_submission_1.submission_comments.last.update_attribute(:created_at, Time.new(2024, 2, 9, 4, 21, 0).utc)
        @student_submission_1.update_attribute(:last_comment_at, nil)

        student_submission_2.add_comment(author: @student, comment: "Fourth comment", created_at: Time.new(2024, 2, 8, 13, 17, 0).utc)
        student_submission_2.add_comment(author: @teacher, comment: "Fifth comment", created_at: Time.new(2024, 2, 10, 5, 11, 0).utc)
        student_submission_2.update_attribute(:last_comment_at, Time.new(2024, 2, 8, 13, 17, 0).utc)

        # Notice: submission 2 is older, but submission 2 has newest submission_comment.
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { _id }  }")

        expect(query_result.count).to eq 2
        expect(query_result[0].to_i).to eq student_submission_2.id
      end

      it "can retrieve submission comments" do
        allow(InstStatsd::Statsd).to receive(:distributed_increment)
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { commentsConnection { nodes { comment }} }  }")
        expect(query_result[0].count).to eq 3
        expect(query_result[0]).to match_array ["First comment", "Second comment", "Third comment"]
        expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("inbox.visit.scope.submission_comments.pages_loaded.react")
      end

      it "can get createdAt" do
        query_result = teacher_type.resolve("viewableSubmissionsConnection { nodes { commentsConnection { nodes { createdAt }} }  }")
        retrieved_values = query_result[0].map { |string_date| Time.zone.parse(string_date) }
        expect(retrieved_values).to all(be_within(1.minute).of(@sc1.created_at))
      end

      it "can get assignment names" do
        expect(teacher_type.resolve("viewableSubmissionsConnection { nodes { assignment { name }  }  }")[0]).to eq @student_submission_1.assignment.name
      end

      it "can get course names" do
        expect(teacher_type.resolve("viewableSubmissionsConnection { nodes { commentsConnection { nodes { course { name } } }  }  }")[0]).to match_array %w[TEST TEST TEST]
      end

      describe "filter" do
        before(:once) do
          # add_comments by user 2 to course 1 and 2
          student_submission_2 = @assignment2.submissions.find_by(user: @student_2)
          @student_submission_3 = @assignment3.submissions.find_by(user: @student_2)

          student_submission_2.add_comment(author: @student_2, comment: "Fourth comment")
          student_submission_2.add_comment(author: @teacher, comment: "Fifth comment")
          @student_submission_3.add_comment(author: @student_2, comment: "sixth comment")
          @student_submission_3.add_comment(author: @teacher, comment: "seventh comment")
        end

        it "submissions by course" do
          query_result = teacher_type.resolve("viewableSubmissionsConnection(filter: [\"course_#{@course_2.id}\"]) { nodes { _id }  }")
          expect(query_result.count).to eq 1
          expect(query_result[0].to_i).to eq @student_submission_3.id
        end

        it "submissions by user" do
          query_result = teacher_type.resolve("viewableSubmissionsConnection(filter: [\"user_#{@student_2.id}\"]) { nodes { _id }  }")
          expect(query_result.count).to eq 2
          expect(query_result[0].to_i).to eq @student_submission_3.id
        end
      end
    end
  end

  context "with a user" do
    before(:once) do
      @user = user_factory
    end

    let(:user_type) do
      GraphQLTypeTester.new(@user, current_user: @user, domain_root_account: @user.account, request: ActionDispatch::TestRequest.create)
    end

    it "returns the user's inbox labels" do
      @user.preferences[:inbox_labels] = ["Test 1", "Test 2"]
      @user.save!

      expect(user_type.resolve("inboxLabels")).to eq @user.inbox_labels
    end

    it "returns an empty user's inbox labels" do
      expect(user_type.resolve("inboxLabels")).to eq []
    end
  end

  context "ActivityStream" do
    it "returns the activity stream summary" do
      @context = @course
      discussion_topic_model
      discussion_topic_model(user: @user)
      announcement_model
      conversation(User.create, @user)
      Notification.create(name: "Assignment Due Date Changed", category: "TestImmediately")
      allow_any_instance_of(Assignment).to receive(:created_at).and_return(4.hours.ago)
      assignment_model(course: @course)
      @assignment.update_attribute(:due_at, 1.week.from_now)

      cur_resolver = GraphQLTypeTester.new(@user, current_user: @user, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
      expect(cur_resolver.resolve("activityStream { summary { type } } ")).to match_array %w[Announcement Conversation DiscussionTopic Message]
      expect(cur_resolver.resolve("activityStream { summary { count } } ")).to match_array [1, 1, 2, 1]
      expect(cur_resolver.resolve("activityStream { summary { unreadCount } } ")).to match_array [1, 0, 1, 0]
      expect(cur_resolver.resolve("activityStream { summary { notificationCategory } } ")).to match_array [nil, nil, nil, "TestImmediately"]
    end
  end

  context "Cross-Shard ActivityStream Summary" do
    specs_require_sharding
    it "returns the activity stream summary with cross-shard items" do
      @student = user_factory(active_all: true)
      @shard1.activate do
        @account = Account.create!
        course_factory(active_all: true, account: @account)
        @course.enroll_student(@student).accept!
        @context = @course
        discussion_topic_model
        discussion_topic_model(user: @user)
        announcement_model
        conversation(User.create, @user)
        Notification.create(name: "Assignment Due Date Changed", category: "TestImmediately")
        allow_any_instance_of(Assignment).to receive(:created_at).and_return(4.hours.ago)
        assignment_model(course: @course)
        @assignment.update_attribute(:due_at, 1.week.from_now)
        @assignment.update_attribute(:due_at, 2.weeks.from_now)
      end
      cur_resolver = GraphQLTypeTester.new(@user, current_user: @user, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
      expect(cur_resolver.resolve("activityStream { summary { type } } ")).to match_array %w[Announcement Conversation DiscussionTopic Message]
      expect(cur_resolver.resolve("activityStream { summary { count } } ")).to match_array [1, 1, 2, 2]
      expect(cur_resolver.resolve("activityStream { summary { unreadCount } } ")).to match_array [1, 0, 1, 0]
      expect(cur_resolver.resolve("activityStream { summary { notificationCategory } } ")).to match_array [nil, nil, nil, "TestImmediately"]
    end

    it "filters the activity stream summary to currently active courses if requested" do
      @student = user_factory(active_all: true)
      @shard1.activate do
        @account = Account.create!
        @course1 = course_factory(active_all: true, account: @account)
        @course1.enroll_student(@student).accept!
        @course2 = course_factory(active_all: true, account: @account)
        course2_enrollment = @course2.enroll_student(@student)
        course2_enrollment.accept!
        @dt1 = discussion_topic_model(context: @course1)
        @dt2 = discussion_topic_model(context: @course2)
        course2_enrollment.destroy!
      end
      cur_resolver = GraphQLTypeTester.new(@user, current_user: @user, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create)
      # without filtering to active courses
      expect(cur_resolver.resolve("activityStream { summary { type } } ")).to match_array ["DiscussionTopic"]
      expect(cur_resolver.resolve("activityStream { summary { count } } ")).to match_array [2]
      expect(cur_resolver.resolve("activityStream { summary { unreadCount } } ")).to match_array [2]
      expect(cur_resolver.resolve("activityStream { summary { notificationCategory } } ")).to match_array [nil]

      # with filtering to active courses
      expect(cur_resolver.resolve("activityStream(onlyActiveCourses: true) { summary { type } } ")).to match_array ["DiscussionTopic"]
      expect(cur_resolver.resolve("activityStream(onlyActiveCourses: true) { summary { count } } ")).to match_array [1]
      expect(cur_resolver.resolve("activityStream(onlyActiveCourses: true) { summary { unreadCount } } ")).to match_array [1]
      expect(cur_resolver.resolve("activityStream(onlyActiveCourses: true) { summary { notificationCategory } } ")).to match_array [nil]
    end
  end

  context "discussion_participants_connection" do
    before do
      @course1 = course_factory(active_all: true)
      @course2 = course_factory(active_all: true)
      @student_user = user_factory(active_all: true)

      # Enroll user in both courses
      @course1.enroll_user(@student_user, "StudentEnrollment", enrollment_state: "active")
      @course2.enroll_user(@student_user, "StudentEnrollment", enrollment_state: "active")

      # Create announcements and discussions
      @announcement1 = @course1.announcements.create!(title: "Course 1 Announcement", message: "Test announcement 1")
      @announcement2 = @course2.announcements.create!(title: "Course 2 Announcement", message: "Test announcement 2")
      @discussion1 = @course1.discussion_topics.create!(title: "Course 1 Discussion", message: "Test discussion 1")
      @discussion2 = @course2.discussion_topics.create!(title: "Course 2 Discussion", message: "Test discussion 2")

      # Get participant records (announcements auto-create them, discussions need manual creation)
      @participant1 = @student_user.discussion_topic_participants.find_by(discussion_topic: @announcement1)
      @participant1.update!(workflow_state: "read") # Update to desired test state

      @participant2 = @student_user.discussion_topic_participants.find_by(discussion_topic: @announcement2)
      # @participant2 is already "unread" from auto-creation

      @participant3 = @student_user.discussion_topic_participants.create!(
        discussion_topic: @discussion1,
        workflow_state: "read"
      )
      @participant4 = @student_user.discussion_topic_participants.create!(
        discussion_topic: @discussion2,
        workflow_state: "unread"
      )

      @user_type_tester = GraphQLTypeTester.new(
        @student_user,
        current_user: @student_user,
        domain_root_account: @course1.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    def resolve_participants_connection(filter: nil, first: nil)
      filter_str = filter ? build_filter_string(filter) : ""
      first_str = first ? %(first: #{first}) : ""
      args = [filter_str, first_str].reject(&:empty?).join(", ")
      query = %(discussionParticipantsConnection#{"(#{args})" unless args.empty?} { nodes { id } })
      @user_type_tester.resolve(query)
    end

    def resolve_participants_with_topics(filter: nil)
      filter_str = filter ? build_filter_string(filter) : ""
      query = %(discussionParticipantsConnection#{"(#{filter_str})" unless filter_str.empty?} {
        nodes {
          discussionTopic {
            title
          }
        }
      })
      @user_type_tester.resolve(query)
    end

    def build_filter_string(filter)
      filter_parts = []
      filter_parts << "isAnnouncement: #{filter[:isAnnouncement]}" if filter.key?(:isAnnouncement)
      filter_parts << "courseId: \"#{filter[:courseId]}\"" if filter.key?(:courseId)
      filter_parts << "readState: \"#{filter[:readState]}\"" if filter.key?(:readState)
      "filter: { #{filter_parts.join(", ")} }"
    end

    it "returns all discussion participants for the user" do
      result = resolve_participants_connection

      expect(result.length).to eq(4)
      # GraphQL returns Global IDs (Base64 encoded), so we just check we get 4 unique IDs
      expect(result.flatten.uniq.length).to eq(4)
    end

    it "filters by announcements only when isAnnouncement is true" do
      result = resolve_participants_with_topics(filter: { isAnnouncement: true })

      expect(result.length).to eq(2)
      titles = result.flatten
      expect(titles).to match_array(["Course 1 Announcement", "Course 2 Announcement"])
    end

    it "filters by discussions only when isAnnouncement is false" do
      result = resolve_participants_with_topics(filter: { isAnnouncement: false })

      expect(result.length).to eq(2)
      titles = result.flatten
      expect(titles).to match_array(["Course 1 Discussion", "Course 2 Discussion"])
    end

    it "filters by course when courseId is provided" do
      result = resolve_participants_with_topics(filter: { courseId: @course1.id })

      expect(result.length).to eq(2)
      titles = result.flatten
      expect(titles).to match_array(["Course 1 Announcement", "Course 1 Discussion"])
    end

    it "respects pagination with first parameter" do
      result = resolve_participants_connection(first: 2)

      expect(result.length).to eq(2)
    end

    it "returns null for non-current user" do
      other_user = user_factory
      other_user_tester = GraphQLTypeTester.new(
        other_user,
        current_user: @student_user,
        domain_root_account: @course1.account.root_account,
        request: ActionDispatch::TestRequest.create
      )

      result = other_user_tester.resolve("discussionParticipantsConnection { nodes { id } }")
      expect(result).to be_nil
    end

    context "with read state filtering" do
      it "filters by read status when readState is 'read'" do
        result = resolve_participants_with_topics(filter: { readState: "read" })

        expect(result.length).to eq(2)
        titles = result.flatten
        expect(titles).to match_array(["Course 1 Announcement", "Course 1 Discussion"])
      end

      it "filters by unread status when readState is 'unread'" do
        result = resolve_participants_with_topics(filter: { readState: "unread" })

        expect(result.length).to eq(2)
        titles = result.flatten
        expect(titles).to match_array(["Course 2 Announcement", "Course 2 Discussion"])
      end

      it "returns all participants when readState is 'all'" do
        result = resolve_participants_with_topics(filter: { readState: "all" })

        expect(result.length).to eq(4)
        titles = result.flatten
        expect(titles).to match_array([
                                        "Course 1 Announcement",
                                        "Course 2 Announcement",
                                        "Course 1 Discussion",
                                        "Course 2 Discussion"
                                      ])
      end

      it "combines readState with isAnnouncement filter" do
        result = resolve_participants_with_topics(filter: { readState: "read", isAnnouncement: true })

        expect(result.length).to eq(1)
        titles = result.flatten
        expect(titles).to eq(["Course 1 Announcement"])
      end
    end

    context "with time-based filtering for announcements" do
      it "excludes locked announcements" do
        @announcement1.update!(lock_at: 1.day.ago)

        result = resolve_participants_with_topics(filter: { isAnnouncement: true })
        titles = result.flatten

        expect(result.length).to eq(1)
        expect(titles).to eq(["Course 2 Announcement"])
      end
    end

    context "with enrollment filtering" do
      it "excludes participants from courses where user has no active enrollment" do
        # Deactivate enrollment in course2
        @course2.enrollments.where(user: @student_user).first.deactivate

        result = resolve_participants_connection

        # Should only return participants from course1
        expect(result.length).to eq(2)
      end

      it "excludes announcements from past courses (section end date in past)" do
        # Create a course with section that ended
        past_course = course_factory(active_all: true)
        past_section = past_course.course_sections.create!(name: "Past Section", end_at: 1.week.ago)
        past_course.enroll_student(@student_user, section: past_section, enrollment_state: "active")

        # Create an announcement in the past course
        past_course.announcements.create!(
          title: "Past Course Announcement",
          message: "This should not appear"
        )

        result = resolve_participants_with_topics(filter: { isAnnouncement: true })
        titles = result.flatten

        # Should only include announcements from current courses
        expect(titles).to match_array(["Course 1 Announcement", "Course 2 Announcement"])
        expect(titles).not_to include("Past Course Announcement")
      end

      it "excludes announcements from courses with conclude_at in past" do
        # Create a course that concluded
        concluded_course = course_factory(active_all: true)
        concluded_course.update!(conclude_at: 1.week.ago)
        concluded_course.enroll_student(@student_user, enrollment_state: "active")

        # Create an announcement in the concluded course
        concluded_course.announcements.create!(
          title: "Concluded Course Announcement",
          message: "This should not appear"
        )

        result = resolve_participants_with_topics(filter: { isAnnouncement: true })
        titles = result.flatten

        # Should only include announcements from current courses
        expect(titles).to match_array(["Course 1 Announcement", "Course 2 Announcement"])
        expect(titles).not_to include("Concluded Course Announcement")
      end

      it "excludes announcements from unpublished courses" do
        # Create an unpublished course
        unpublished_course = course_factory
        unpublished_course.workflow_state = "claimed"
        unpublished_course.save!
        unpublished_course.enroll_student(@student_user, enrollment_state: "active")

        # Create an announcement in the unpublished course
        unpublished_course.announcements.create!(
          title: "Unpublished Course Announcement",
          message: "This should not appear"
        )

        result = resolve_participants_with_topics(filter: { isAnnouncement: true })
        titles = result.flatten

        # Should only include announcements from current courses
        expect(titles).to match_array(["Course 1 Announcement", "Course 2 Announcement"])
        expect(titles).not_to include("Unpublished Course Announcement")
      end
    end
  end

  context "discussionParticipantsConnection with observed user" do
    before(:once) do
      @course1 = course_factory(active_all: true, course_name: "Course 1")
      @course2 = course_factory(active_all: true, course_name: "Course 2")

      @observer = user_factory(name: "Observer")
      @observed_student = user_factory(name: "Observed Student")

      @course1.enroll_student(@observed_student, enrollment_state: "active")
      @course2.enroll_student(@observed_student, enrollment_state: "active")
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_student.id, enrollment_state: "active")
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_student.id, enrollment_state: "active")

      # Create discussions and announcements
      @discussion1 = @course1.discussion_topics.create!(title: "Discussion 1", message: "Test discussion", workflow_state: "active")
      @announcement1 = @course1.announcements.create!(title: "Announcement 1", message: "Test announcement", workflow_state: "active")
      @discussion2 = @course2.discussion_topics.create!(title: "Discussion 2", message: "Another discussion", workflow_state: "active")

      # Create participation records for observed student (announcements auto-create, so use find_or_create)
      @discussion1.discussion_topic_participants.find_or_create_by!(user: @observed_student)
      @announcement1.discussion_topic_participants.find_or_create_by!(user: @observed_student)
      @discussion2.discussion_topic_participants.find_or_create_by!(user: @observed_student)
    end

    let(:observer_user_type) do
      GraphQLTypeTester.new(
        @observer,
        current_user: @observer,
        domain_root_account: @course1.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns discussion participants for observed student" do
      result = observer_user_type.resolve(
        "discussionParticipantsConnection(observedUserId: \"#{@observed_student.id}\") {
          nodes {
            discussionTopic {
              title
            }
          }
        }"
      )

      expect(result.length).to eq(3)
      topic_titles = result.flatten.sort
      expect(topic_titles).to eq(["Announcement 1", "Discussion 1", "Discussion 2"])
    end

    it "returns empty result for invalid observed user id" do
      result = observer_user_type.resolve(
        "discussionParticipantsConnection(observedUserId: \"999999\") {
          nodes {
            discussionTopic { title }
          }
        }"
      )

      expect(result).to be_empty
    end

    it "filters by announcement status" do
      result = observer_user_type.resolve(
        "discussionParticipantsConnection(
          observedUserId: \"#{@observed_student.id}\",
          filter: { isAnnouncement: true }
        ) {
          nodes {
            discussionTopic { title }
          }
        }"
      )

      expect(result.length).to eq(1)
      expect(result.flatten.first).to eq("Announcement 1")
    end

    it "only returns participants from courses observer can access" do
      # Create a course the observer can't see
      other_course = Course.create!(name: "Other Course")
      other_discussion = other_course.discussion_topics.create!(title: "Other Discussion", message: "Hidden")
      other_course.enroll_student(@observed_student, active_all: true)
      other_discussion.discussion_topic_participants.create!(user: @observed_student)

      result = observer_user_type.resolve(
        "discussionParticipantsConnection(observedUserId: \"#{@observed_student.id}\") {
          nodes {
            discussionTopic { title }
          }
        }"
      )

      topic_titles = result.flatten.sort
      expect(topic_titles).to eq(["Announcement 1", "Discussion 1", "Discussion 2"])
      expect(topic_titles).not_to include("Other Discussion")
    end
  end

  context "course_work_submissions_connection" do
    before(:once) do
      @frozen_time = Time.zone.parse("2024-01-15 12:00:00")

      Timecop.freeze(@frozen_time) do
        @assignment = @course.assignments.create!(
          title: "Test Assignment",
          due_at: (@frozen_time + 1.day).end_of_day, # Due tomorrow
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        # Create unsubmitted submission (actionable) - use find_or_create pattern
        @submission = @assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end
      end
    end

    it "returns the connection field" do
      Timecop.freeze(@frozen_time) do
        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { _id } } }")
        expect(result).to be_an(Array)
      end
    end

    it "returns actual submissions data" do
      Timecop.freeze(@frozen_time) do
        expect(@submission).not_to be_nil
        expect(@submission.submitted_at).to be_nil # Should be unsubmitted
        expect(@submission.excused).to be_falsey # Should not be excused
        expect(@assignment.workflow_state).to eq("published")
        expect(@course.workflow_state).to eq("available")

        enrollment = @student.enrollments.where(course: @course).first
        expect(enrollment).not_to be_nil
        expect(enrollment.workflow_state).to eq("active")

        # Test with date range parameters (next 7 days from frozen time)
        start_date = @frozen_time.beginning_of_day
        end_date = (@frozen_time + 7.days).end_of_day

        result = student_user_type.resolve("courseWorkSubmissionsConnection(startDate: \"#{start_date.iso8601}\", endDate: \"#{end_date.iso8601}\") { edges { node { assignment { title } } } }")
        expect(result).not_to be_empty, "Expected to find submissions with date range filter"
        expect(result.first).to eq("Test Assignment")
      end
    end

    it "does not return deleted submissions" do
      Timecop.freeze(@frozen_time) do
        @submission.update!(workflow_state: "deleted")
        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { _id } } }")
        expect(result).to eq([])
      end
    end

    it "does not return submissions for pending enrollments" do
      Timecop.freeze(@frozen_time) do
        enrollment = @student.enrollments.where(course: @course).first
        enrollment.update!(workflow_state: "invited")
        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { _id } } }")
        expect(result).to eq([])
      end
    end

    it "only returns data for current user" do
      Timecop.freeze(@frozen_time) do
        result = user_type.resolve("courseWorkSubmissionsConnection { edges { node { _id } } }")
        expect(result).to eq([])
      end
    end

    it "filters by includeOverdue parameter" do
      Timecop.freeze(@frozen_time) do
        # Create an overdue assignment (due 2 days ago from frozen time)
        overdue_assignment = @course.assignments.create!(
          title: "Overdue Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        overdue_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")
        expect(result).to include("Overdue Assignment")
      end
    end

    it "filters by onlySubmitted parameter" do
      Timecop.freeze(@frozen_time) do
        # Create a submitted assignment (due tomorrow from frozen time)
        submitted_assignment = @course.assignments.create!(
          title: "Submitted Assignment",
          due_at: (@frozen_time + 1.day).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        submitted_submission = submitted_assignment.submissions.find_or_create_by(user: @student)
        submitted_submission.update!(
          submitted_at: @frozen_time - 1.hour,
          workflow_state: "submitted",
          submission_type: "online_text_entry"
        )

        result = student_user_type.resolve("courseWorkSubmissionsConnection(onlySubmitted: true) { edges { node { assignment { title } } } }")
        expect(result).to include("Submitted Assignment")
        expect(result).not_to include("Test Assignment") # Should not include unsubmitted
      end
    end

    it "includes graded submissions in onlySubmitted filter even without submitted_at" do
      Timecop.freeze(@frozen_time) do
        # Create assignment with no submission required (e.g., "on_paper")
        no_submission_assignment = @course.assignments.create!(
          title: "Graded No Submission Assignment",
          due_at: (@frozen_time - 1.day).end_of_day,
          workflow_state: "published",
          submission_types: "none"
        )
        graded_submission = no_submission_assignment.submissions.find_or_create_by(user: @student)
        graded_submission.update!(
          submitted_at: nil, # Never submitted
          workflow_state: "graded",
          grader_id: @teacher.id,
          score: 90
        )

        result = student_user_type.resolve("courseWorkSubmissionsConnection(onlySubmitted: true) { edges { node { assignment { title } } } }")
        expect(result).to include("Graded No Submission Assignment")
      end
    end

    it "includes excused submissions in onlySubmitted filter" do
      Timecop.freeze(@frozen_time) do
        excused_assignment = @course.assignments.create!(
          title: "Excused Assignment",
          due_at: (@frozen_time + 1.day).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        excused_submission = excused_assignment.submissions.find_or_create_by(user: @student)
        excused_submission.update!(
          submitted_at: nil,
          workflow_state: "unsubmitted",
          excused: true
        )

        result = student_user_type.resolve("courseWorkSubmissionsConnection(onlySubmitted: true) { edges { node { assignment { title } } } }")
        expect(result).to include("Excused Assignment")
      end
    end

    it "handles NULL excused values correctly" do
      Timecop.freeze(@frozen_time) do
        # Explicitly set excused to nil to test our NULL handling
        @submission.update_column(:excused, nil)

        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { assignment { title } } } }")
        expect(result).not_to be_empty, "Should include submissions with NULL excused values"
        expect(result.first).to eq("Test Assignment")
      end
    end

    it "excludes assignments with no submission requirements from includeOverdue filter" do
      Timecop.freeze(@frozen_time) do
        no_submission_assignment = @course.assignments.create!(
          title: "No Submission Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "none"
        )
        no_submission_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        regular_overdue_assignment = @course.assignments.create!(
          title: "Regular Overdue Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        regular_overdue_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")

        expect(result).to include("Regular Overdue Assignment")
        expect(result).not_to include("No Submission Assignment")

        no_sub_submission = no_submission_assignment.submissions.find_by(user: @student)
        regular_sub_submission = regular_overdue_assignment.submissions.find_by(user: @student)

        expect(no_sub_submission.missing?).to be false
        expect(regular_sub_submission.missing?).to be true
      end
    end

    it "excludes assignments with not_graded submission types from includeOverdue filter" do
      Timecop.freeze(@frozen_time) do
        not_graded_assignment = @course.assignments.create!(
          title: "Not Graded Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "not_graded"
        )
        not_graded_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")
        expect(result).not_to include("Not Graded Assignment")

        submission = not_graded_assignment.submissions.find_by(user: @student)
        expect(submission.missing?).to be false
      end
    end

    it "excludes assignments with wiki_page submission types from includeOverdue filter" do
      Timecop.freeze(@frozen_time) do
        wiki_assignment = @course.assignments.create!(
          title: "Wiki Page Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "wiki_page"
        )
        wiki_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")
        expect(result).not_to include("Wiki Page Assignment")

        submission = wiki_assignment.submissions.find_by(user: @student)
        expect(submission.missing?).to be false
      end
    end

    it "excludes submitted assignments from includeOverdue filter" do
      Timecop.freeze(@frozen_time) do
        submitted_overdue_assignment = @course.assignments.create!(
          title: "Submitted Overdue Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        submitted_submission = submitted_overdue_assignment.submissions.find_or_create_by(user: @student)
        submitted_submission.update!(
          submitted_at: @frozen_time - 1.day,
          workflow_state: "submitted",
          submission_type: "online_text_entry",
          body: "My submission content"
        )

        unsubmitted_overdue_assignment = @course.assignments.create!(
          title: "Unsubmitted Overdue Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        unsubmitted_overdue_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")

        expect(result).to include("Unsubmitted Overdue Assignment")
        expect(result).not_to include("Submitted Overdue Assignment")

        submitted_sub = submitted_overdue_assignment.submissions.find_by(user: @student)
        unsubmitted_sub = unsubmitted_overdue_assignment.submissions.find_by(user: @student)

        expect(submitted_sub.missing?).to be false
        expect(unsubmitted_sub.missing?).to be true
      end
    end

    it "excludes graded assignments from includeOverdue filter" do
      Timecop.freeze(@frozen_time) do
        graded_overdue_assignment = @course.assignments.create!(
          title: "Graded Overdue Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        graded_submission = graded_overdue_assignment.submissions.find_or_create_by(user: @student)
        graded_submission.update!(
          submitted_at: nil,
          workflow_state: "graded",
          grader_id: @teacher.id,
          score: 85
        )

        result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")
        expect(result).not_to include("Graded Overdue Assignment")

        submission = graded_overdue_assignment.submissions.find_by(user: @student)
        expect(submission.missing?).to be false
      end
    end

    it "excludes assignments from past courses (section end date in past)" do
      Timecop.freeze(@frozen_time) do
        # Create a course with section that ended
        past_course = course_factory(active_all: true)
        past_section = past_course.course_sections.create!(name: "Past Section", end_at: @frozen_time - 1.week)
        past_course.enroll_student(@student, section: past_section, enrollment_state: "active")

        # Create an assignment in the past course
        past_assignment = past_course.assignments.create!(
          title: "Past Course Assignment",
          due_at: (@frozen_time + 1.day).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        past_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { assignment { title } } } }")
        expect(result).not_to include("Past Course Assignment")
        expect(result).to include("Test Assignment") # Should still show current course
      end
    end

    it "excludes assignments from courses with conclude_at in past" do
      Timecop.freeze(@frozen_time) do
        # Create a course that concluded
        concluded_course = course_factory(active_all: true)
        concluded_course.update!(conclude_at: @frozen_time - 1.week)
        concluded_course.enroll_student(@student, enrollment_state: "active")

        # Create an assignment in the concluded course
        concluded_assignment = concluded_course.assignments.create!(
          title: "Concluded Course Assignment",
          due_at: (@frozen_time + 1.day).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        concluded_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { assignment { title } } } }")
        expect(result).not_to include("Concluded Course Assignment")
        expect(result).to include("Test Assignment") # Should still show current course
      end
    end

    it "excludes assignments from unpublished courses" do
      Timecop.freeze(@frozen_time) do
        # Create an unpublished course
        unpublished_course = course_factory
        unpublished_course.workflow_state = "claimed"
        unpublished_course.save!
        unpublished_course.enroll_student(@student, enrollment_state: "active")

        # Create an assignment in the unpublished course
        unpublished_assignment = unpublished_course.assignments.create!(
          title: "Unpublished Course Assignment",
          due_at: (@frozen_time + 1.day).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        unpublished_assignment.submissions.find_or_create_by(user: @student) do |s|
          s.submitted_at = nil
          s.workflow_state = "unsubmitted"
        end

        result = student_user_type.resolve("courseWorkSubmissionsConnection { edges { node { assignment { title } } } }")
        expect(result).not_to include("Unpublished Course Assignment")
        expect(result).to include("Test Assignment") # Should still show current course
      end
    end

    context "graded unsubmitted work filtering" do
      before(:once) do
        @frozen_time = Time.zone.parse("2024-01-15 12:00:00")
      end

      it "excludes graded-unsubmitted work from default filter (onlySubmitted: false)" do
        Timecop.freeze(@frozen_time) do
          graded_unsubmitted_assignment = @course.assignments.create!(
            title: "Graded but Never Submitted",
            due_at: (@frozen_time + 2.days).end_of_day,
            workflow_state: "published",
            submission_types: "online_text_entry"
          )
          graded_submission = graded_unsubmitted_assignment.submissions.find_or_create_by(user: @student)
          graded_submission.update!(
            submitted_at: nil,           # NOT submitted
            workflow_state: "graded",    # But graded
            grader_id: @teacher.id,
            score: 85
          )

          # Query without onlySubmitted (default filter for "due" items)
          start_date = @frozen_time.beginning_of_day
          end_date = (@frozen_time + 7.days).end_of_day

          result = student_user_type.resolve(
            "courseWorkSubmissionsConnection(startDate: \"#{start_date.iso8601}\", endDate: \"#{end_date.iso8601}\") {
              edges { node { assignment { title } } }
            }"
          )

          expect(result).not_to include("Graded but Never Submitted")
        end
      end

      it "includes graded-unsubmitted work in onlySubmitted filter" do
        Timecop.freeze(@frozen_time) do
          graded_unsubmitted_assignment = @course.assignments.create!(
            title: "Graded but Never Submitted",
            due_at: (@frozen_time + 2.days).end_of_day,
            workflow_state: "published",
            submission_types: "online_text_entry"
          )
          graded_submission = graded_unsubmitted_assignment.submissions.find_or_create_by(user: @student)
          graded_submission.update!(
            submitted_at: nil,
            workflow_state: "graded",
            grader_id: @teacher.id,
            score: 85
          )

          result = student_user_type.resolve(
            "courseWorkSubmissionsConnection(onlySubmitted: true) {
              edges { node { assignment { title } } }
            }"
          )

          expect(result).to include("Graded but Never Submitted")
        end
      end

      it "handles edge case: graded workflow_state without score (grade cleared)" do
        Timecop.freeze(@frozen_time) do
          # Edge case: assignment has graded workflow_state but no score (score was cleared)
          graded_no_score_assignment = @course.assignments.create!(
            title: "Graded State Without Score",
            due_at: (@frozen_time + 2.days).end_of_day,
            workflow_state: "published",
            submission_types: "online_text_entry"
          )
          graded_no_score_submission = graded_no_score_assignment.submissions.find_or_create_by(user: @student)
          graded_no_score_submission.update!(
            submitted_at: nil,
            workflow_state: "graded",  # Has graded state
            grader_id: @teacher.id,
            score: nil                 # But no score
          )

          start_date = @frozen_time.beginning_of_day
          end_date = (@frozen_time + 7.days).end_of_day

          result = student_user_type.resolve(
            "courseWorkSubmissionsConnection(startDate: \"#{start_date.iso8601}\", endDate: \"#{end_date.iso8601}\") {
              edges { node { assignment { title } } }
            }"
          )

          expect(result).to include("Graded State Without Score")
        end
      end

      it "handles edge case: score without graded workflow_state (race condition)" do
        Timecop.freeze(@frozen_time) do
          # Edge case: submission has score but workflow_state is not 'graded' (race condition)
          score_no_graded_state_assignment = @course.assignments.create!(
            title: "Score Without Graded State",
            due_at: (@frozen_time + 2.days).end_of_day,
            workflow_state: "published",
            submission_types: "online_text_entry"
          )
          score_no_graded_submission = score_no_graded_state_assignment.submissions.find_or_create_by(user: @student)
          score_no_graded_submission.update!(
            submitted_at: nil,
            workflow_state: "unsubmitted",  # NOT graded state
            score: 75                       # But has score
          )

          start_date = @frozen_time.beginning_of_day
          end_date = (@frozen_time + 7.days).end_of_day

          result = student_user_type.resolve(
            "courseWorkSubmissionsConnection(startDate: \"#{start_date.iso8601}\", endDate: \"#{end_date.iso8601}\") {
              edges { node { assignment { title } } }
            }"
          )

          expect(result).to include("Score Without Graded State")
        end
      end

      it "excludes normal graded work with both score and graded state from default filter" do
        Timecop.freeze(@frozen_time) do
          normal_graded_assignment = @course.assignments.create!(
            title: "Normal Graded Assignment",
            due_at: (@frozen_time + 2.days).end_of_day,
            workflow_state: "published",
            submission_types: "online_text_entry"
          )
          normal_graded_submission = normal_graded_assignment.submissions.find_or_create_by(user: @student)
          normal_graded_submission.update!(
            submitted_at: nil,
            workflow_state: "graded",  # Has graded state
            grader_id: @teacher.id,
            score: 90                  # And has score
          )

          start_date = @frozen_time.beginning_of_day
          end_date = (@frozen_time + 7.days).end_of_day

          result = student_user_type.resolve(
            "courseWorkSubmissionsConnection(startDate: \"#{start_date.iso8601}\", endDate: \"#{end_date.iso8601}\") {
              edges { node { assignment { title } } }
            }"
          )

          expect(result).not_to include("Normal Graded Assignment")
        end
      end

      it "includes truly ungraded work in default filter" do
        Timecop.freeze(@frozen_time) do
          ungraded_assignment = @course.assignments.create!(
            title: "Truly Ungraded Assignment",
            due_at: (@frozen_time + 2.days).end_of_day,
            workflow_state: "published",
            submission_types: "online_text_entry"
          )
          ungraded_submission = ungraded_assignment.submissions.find_or_create_by(user: @student)
          ungraded_submission.update!(
            submitted_at: nil,
            workflow_state: "unsubmitted",
            score: nil
          )

          start_date = @frozen_time.beginning_of_day
          end_date = (@frozen_time + 7.days).end_of_day

          result = student_user_type.resolve(
            "courseWorkSubmissionsConnection(startDate: \"#{start_date.iso8601}\", endDate: \"#{end_date.iso8601}\") {
              edges { node { assignment { title } } }
            }"
          )

          expect(result).to include("Truly Ungraded Assignment")
        end
      end
    end

    it "includes submissions marked as missing by teacher in includeOverdue filter even if graded" do
      Timecop.freeze(@frozen_time) do
        missing_assignment = @course.assignments.create!(
          title: "Teacher Marked Missing Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )

        # Create a submission where:
        # - Student never submitted (submitted_at: nil)
        # - Teacher graded it anyway (score, workflow_state = graded)
        # - Teacher manually marked it as missing via late policy
        submission = missing_assignment.submissions.find_or_create_by(user: @student)
        submission.update!(
          submitted_at: nil,
          workflow_state: "graded",
          submission_type: nil,
          grader_id: @teacher.id,
          score: 0,
          late_policy_status: "missing"
        )

        expect(submission.missing?).to be true
        missing_result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")
        expect(missing_result).to include("Teacher Marked Missing Assignment")

        submitted_result = student_user_type.resolve("courseWorkSubmissionsConnection(onlySubmitted: true) { edges { node { assignment { title } } } }")
        expect(submitted_result).not_to include("Teacher Marked Missing Assignment")
      end
    end

    it "excludes submissions that are calculated as missing (not explicitly marked) from submitted filter" do
      Timecop.freeze(@frozen_time) do
        calculated_missing_assignment = @course.assignments.create!(
          title: "Calculated Missing Assignment",
          due_at: (@frozen_time - 2.days).end_of_day,
          workflow_state: "published",
          submission_types: "online_text_entry"
        )

        # Create a submission that is missing by calculation, not by explicit late_policy_status
        submission = calculated_missing_assignment.submissions.find_or_create_by(user: @student)
        submission.update!(
          submitted_at: nil,
          workflow_state: "unsubmitted",
          submission_type: nil,
          grader_id: nil,
          score: nil,
          late_policy_status: nil
        )

        expect(submission.missing?).to be true

        submitted_result = student_user_type.resolve("courseWorkSubmissionsConnection(onlySubmitted: true) { edges { node { assignment { title } } } }")
        expect(submitted_result).not_to include("Calculated Missing Assignment")

        missing_result = student_user_type.resolve("courseWorkSubmissionsConnection(includeOverdue: true) { edges { node { assignment { title } } } }")
        expect(missing_result).to include("Calculated Missing Assignment")
      end
    end
  end

  context "courseWorkSubmissionsConnection with observed user" do
    before(:once) do
      @course1 = course_factory(active_all: true, course_name: "Course 1")
      @course2 = course_factory(active_all: true, course_name: "Course 2")

      @assignment1 = @course1.assignments.create!(title: "Assignment 1", due_at: 1.day.from_now, workflow_state: "published")
      @assignment2 = @course2.assignments.create!(title: "Assignment 2", due_at: 2.days.from_now, workflow_state: "published")

      @observer = user_factory(name: "Observer")
      @observed_student = user_factory(name: "Observed Student")

      @course1.enroll_student(@observed_student, enrollment_state: "active")
      @course2.enroll_student(@observed_student, enrollment_state: "active")
      @course1.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_student.id, enrollment_state: "active")
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @observed_student.id, enrollment_state: "active")

      @submission1 = @assignment1.submissions.find_by(user: @observed_student)
      @submission2 = @assignment2.submissions.find_by(user: @observed_student)
    end

    let(:observer_user_type) do
      GraphQLTypeTester.new(
        @observer,
        current_user: @observer,
        domain_root_account: @course1.account.root_account,
        request: ActionDispatch::TestRequest.create
      )
    end

    it "returns course work for observed student" do
      result = observer_user_type.resolve(
        "courseWorkSubmissionsConnection(observedUserId: \"#{@observed_student.id}\") {
          edges {
            node {
              assignment {
                name
              }
            }
          }
        }"
      )

      expect(result.length).to eq(2)
      assignment_names = result.sort
      expect(assignment_names).to eq(["Assignment 1", "Assignment 2"])
    end

    it "returns empty result for invalid observed user id" do
      result = observer_user_type.resolve(
        "courseWorkSubmissionsConnection(observedUserId: \"999999\") {
          edges {
            node {
              assignment { name }
            }
          }
        }"
      )

      expect(result).to be_empty
    end

    it "filters by course when specified" do
      result = observer_user_type.resolve(
        "courseWorkSubmissionsConnection(observedUserId: \"#{@observed_student.id}\", courseFilter: \"#{@course1.id}\") {
          edges {
            node {
              assignment {
                name
              }
            }
          }
        }"
      )

      expect(result.length).to eq(1)
      expect(result.first).to eq("Assignment 1")
    end

    it "only returns submissions from courses observer can access" do
      # Create a course the observer can't see
      other_course = course_factory(active_all: true, course_name: "Other Course")
      other_course.assignments.create!(title: "Other Assignment")
      other_course.enroll_student(@observed_student, enrollment_state: "active")

      result = observer_user_type.resolve(
        "courseWorkSubmissionsConnection(observedUserId: \"#{@observed_student.id}\") {
          edges {
            node {
              assignment { name }
            }
          }
        }"
      )

      assignment_names = result.sort
      expect(assignment_names).to eq(["Assignment 1", "Assignment 2"])
      expect(assignment_names).not_to include("Other Assignment")
    end
  end

  describe "peer_review_status field" do
    before(:once) do
      course_with_teacher(active_all: true)
      @assignment = @course.assignments.create!(
        title: "Peer Review Assignment",
        points_possible: 10,
        peer_reviews: true,
        peer_review_count: 2
      )
      @student1 = user_factory(name: "Student One")
      @student2 = user_factory(name: "Student Two")

      @course.enroll_student(@student1, enrollment_state: "active")
      @course.enroll_student(@student2, enrollment_state: "active")

      @course.enable_feature!(:peer_review_allocation_and_grading)

      AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: true
      )

      submission1 = @assignment.submit_homework(@student1, {
                                                  submission_type: "online_text_entry",
                                                  body: "Student 1 submission"
                                                })
      submission2 = @assignment.submit_homework(@student2, {
                                                  submission_type: "online_text_entry",
                                                  body: "Student 2 submission"
                                                })
      AssessmentRequest.create!(
        asset: submission2,
        assessor_asset: submission1,
        user: @student2,
        assessor: @student1,
        workflow_state: "completed"
      )
    end

    it "loads peer review status using the loader" do
      user_type_tester = GraphQLTypeTester.new(
        @student1,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create,
        assignment_id: @assignment.id
      )

      must_review_count = user_type_tester.resolve("peerReviewStatus { mustReviewCount }")
      completed_reviews_count = user_type_tester.resolve("peerReviewStatus { completedReviewsCount }")
      expect(must_review_count).to eq(1)
      expect(completed_reviews_count).to eq(1)
    end

    it "returns nil when assignment_id is not in context" do
      user_type_tester = GraphQLTypeTester.new(
        @student1,
        current_user: @teacher,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      )

      result = user_type_tester.resolve("peerReviewStatus { mustReviewCount }")
      expect(result).to be_nil
    end

    context "with permission and feature checks" do
      it "returns nil when user lacks grade permission" do
        student_type_tester = GraphQLTypeTester.new(
          @student1,
          current_user: @student2,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create,
          assignment_id: @assignment.id
        )

        result = student_type_tester.resolve("peerReviewStatus { mustReviewCount }")
        expect(result).to be_nil
      end

      it "returns nil when feature is not enabled" do
        @assignment.context.disable_feature!(:peer_review_allocation_and_grading)

        user_type_tester = GraphQLTypeTester.new(
          @student1,
          current_user: @teacher,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create,
          assignment_id: @assignment.id
        )

        result = user_type_tester.resolve("peerReviewStatus { mustReviewCount }")
        expect(result).to be_nil
      end

      it "returns nil when peer reviews are not enabled on assignment" do
        @assignment.update!(peer_reviews: false)

        user_type_tester = GraphQLTypeTester.new(
          @student1,
          current_user: @teacher,
          domain_root_account: @course.account.root_account,
          request: ActionDispatch::TestRequest.create,
          assignment_id: @assignment.id
        )
        result = user_type_tester.resolve("peerReviewStatus { mustReviewCount }")
        expect(result).to be_nil
      end
    end
  end

  context "widgetDashboardConfig" do
    it "returns null when no preference is set" do
      expect(student_user_type.resolve("widgetDashboardConfig")).to be_nil
    end

    it "returns the stored configuration as JSON" do
      config = { "columns" => 2, "widgets" => [] }
      @student.set_preference(:widget_dashboard_config, config)
      result = student_user_type.resolve("widgetDashboardConfig")
      expect(JSON.parse(result)).to eq(config)
    end

    it "returns a complete widget configuration" do
      config = {
        "columns" => 2,
        "widgets" => [
          {
            "id" => "course-work-widget",
            "type" => "course_work",
            "position" => { "col" => 1, "row" => 1, "relative" => 1 },
            "title" => "Course work"
          }
        ]
      }
      @student.set_preference(:widget_dashboard_config, config)
      result = student_user_type.resolve("widgetDashboardConfig")
      expect(JSON.parse(result)).to eq(config)
    end
  end
end
