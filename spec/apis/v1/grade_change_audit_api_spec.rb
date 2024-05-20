# frozen_string_literal: true

#
# Copyright (C) 2013 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe "GradeChangeAudit API", type: :request do
  before do
    @request_id = SecureRandom.uuid
    allow(RequestContextGenerator).to receive_messages(request_id: @request_id)

    @domain_root_account = Account.default
    @viewing_user = user_with_pseudonym(account: @domain_root_account)
    @account_user = @viewing_user.account_users.create(account: @domain_root_account)

    course_with_teacher(account: @domain_root_account, user: user_with_pseudonym(account: @domain_root_account))
    student_in_course(user: user_with_pseudonym(account: @domain_root_account))

    @assignment = @course.assignments.create!(title: "Assignment", points_possible: 10)
    @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
    @event = Auditors::GradeChange.record(submission: @submission)
  end

  def fetch_for_context(context, options = {})
    type = context.class.to_s.downcase unless (type = options.delete(:type))
    user = options.delete(:user) || @viewing_user
    id = Shard.global_id_for(context).to_s

    arguments = { controller: :grade_change_audit_api, action: "for_#{type}", "#{type}_id": id, format: :json }
    query_string = []

    if (per_page = options.delete(:per_page))
      arguments[:per_page] = per_page.to_s
      query_string << "per_page=#{arguments[:per_page]}"
    end

    if (start_time = options.delete(:start_time))
      arguments[:start_time] = start_time.iso8601
      query_string << "start_time=#{arguments[:start_time]}"
    end

    if (end_time = options.delete(:end_time))
      arguments[:end_time] = end_time.iso8601
      query_string << "end_time=#{arguments[:end_time]}"
    end

    if (account = options.delete(:account))
      arguments[:account_id] = Shard.global_id_for(account).to_s
      query_string << "account_id=#{arguments[:account_id]}"
    end
    arguments[:include] = options.delete(:include) if options.key?(:include)

    path = "/api/v1/audit/grade_change/#{type.pluralize}/#{id}"
    path += "?" + query_string.join("&") if query_string.present?
    api_call_as_user(user, :get, path, arguments, {}, {}, options.slice(:expected_status))
  end

  def fetch_for_course_and_other_contexts(contexts, options = {})
    expected_contexts = %i[course assignment grader student].freeze
    sorted_contexts = contexts.select { |key, _| expected_contexts.include?(key) }
                              .sort_by { |key, _| expected_contexts.index(key) }

    arguments = sorted_contexts.to_h { |key, value| [:"#{key}_id", value.id] }
    arguments.merge!({
                       controller: :grade_change_audit_api,
                       action: :for_course_and_other_parameters,
                       format: :json
                     })

    query_string = []

    per_page = options.delete(:per_page)
    if per_page
      arguments[:per_page] = per_page.to_s
      query_string << "per_page=#{arguments[:per_page]}"
    end

    start_time = options.delete(:start_time)
    if start_time
      arguments[:start_time] = start_time.iso8601
      query_string << "start_time=#{arguments[:start_time]}"
    end

    end_time = options.delete(:end_time)
    if end_time
      arguments[:end_time] = end_time.iso8601
      query_string << "end_time=#{arguments[:end_time]}"
    end

    account = options.delete(:account)
    if account
      arguments[:account_id] = Shard.global_id_for(account).to_s
      query_string << "account_id=#{arguments[:account_id]}"
    end

    user = options[:user] || @viewing_user

    path_args = sorted_contexts.map { |key, value| "#{key.to_s.pluralize}/#{value.id}" }.join("/")

    path = "/api/v1/audit/grade_change/#{path_args}"
    path += "?" + query_string.join("&") if query_string.present?
    api_call_as_user(user, :get, path, arguments, {}, {}, options.slice(:expected_status))
  end

  def events_for_context(context, options = {})
    json = options.delete(:json)
    json ||= fetch_for_context(context, options)
    json["events"].map { |e| [e["id"], e["event_type"]] }
  end

  def expect_event_for_context(context, event, options = {})
    json = fetch_for_context(context, options)
    events = events_for_context(context, options.merge(json:))
    expect(events).to include([event.id, event.event_type])
    json
  end

  def events_for_course_and_contexts(contexts, options)
    json = options.delete(:json)
    json ||= fetch_for_course_and_other_contexts(contexts, options)
    json["events"].map { |e| [e["id"], e["event_type"]] }
  end

  def expect_event_for_course_and_contexts(contexts, event, options = {})
    json = fetch_for_course_and_other_contexts(contexts, options)
    events = events_for_course_and_contexts(contexts, options.merge(json:))
    expect(events).to include([event.id, event.event_type])
    json
  end

  def forbid_event_for_context(context, event, options = {})
    json = options.delete(:json)
    json ||= fetch_for_context(context, options)
    expect(json["events"].map { |e| [e["id"], e["event_type"]] })
      .not_to include([event.id, event.event_type])
    json
  end

  def forbid_event_for_course_and_contexts(contexts, event, options = {})
    json = options.delete(:json)
    json ||= fetch_for_course_and_contexts(contexts, options)
    expect(json["events"].map { |e| [e["id"], e["event_type"]] })
      .not_to include([event.id, event.event_type])
    json
  end

  def test_course_and_contexts(student: @student)
    # course assignment
    contexts = { course: @course, assignment: @assignment }
    yield(contexts)
    # course assignment grader
    contexts[:grader] = @teacher
    yield(contexts)
    # course assignment grader student
    contexts[:student] = student
    yield(contexts)
    # course assignment student
    contexts.delete(:grader)
    yield(contexts)
    # course student
    contexts.delete(:assignment)
    yield(contexts)
    # course grader
    contexts = { course: @course, grader: @teacher }
    yield(contexts)
    # course grader student
    contexts[:student] = student
    yield(contexts)
  end

  context "nominal cases" do
    it "includes events at context endpoint" do
      expect_event_for_context(@assignment, @event)
      expect_event_for_context(@course, @event)
      expect_event_for_context(@student, @event, type: "student")
      expect_event_for_context(@teacher, @event, type: "grader")

      test_course_and_contexts do |contexts|
        expect_event_for_course_and_contexts(contexts, @event)
      end
    end
  end

  context "section visibility" do
    before do
      new_section = @course.course_sections.create!
      @ta = User.create
      @course.enroll_user(@ta, "TaEnrollment", limit_privileges_to_course_section: true, section: new_section)
      @student_in_new_section = User.create!
      @course.enroll_user(@student_in_new_section, "StudentEnrollment", enrollment_state: "active", section: new_section)
      submission = @assignment.grade_student(@student_in_new_section, grade: 8, grader: @teacher).first
      @event_visible_to_ta = Auditors::GradeChange.record(submission:)
    end

    context "course" do
      it "returns grade change events for students within the current user's section visibility" do
        events = events_for_context(@course, user: @ta)
        expect(events).to include([@event_visible_to_ta.id, @event_visible_to_ta.event_type])
      end

      it "returns grade change events for rejected enrollments" do
        @course.student_enrollments.find_by(user_id: @student_in_new_section).update!(workflow_state: "rejected")
        events = events_for_context(@course, user: @ta)
        expect(events).to include([@event_visible_to_ta.id, @event_visible_to_ta.event_type])
      end

      it "returns grade change events for deleted enrollments" do
        @course.student_enrollments.find_by(user_id: @student_in_new_section).destroy
        events = events_for_context(@course, user: @ta)
        expect(events).to include([@event_visible_to_ta.id, @event_visible_to_ta.event_type])
      end

      it "does not return grade change events for students outside of the current user's section visibility" do
        events = events_for_context(@course, user: @ta)
        expect(events).not_to include([@event.id, @event.event_type])
      end
    end

    context "course + other context" do
      it "returns grade change events for students within the current user's section visibility" do
        test_course_and_contexts(student: @student_in_new_section) do |contexts|
          events = events_for_course_and_contexts(contexts, user: @ta)
          expect(events).to include([@event_visible_to_ta.id, @event_visible_to_ta.event_type])
        end
      end

      it "does not return grade change events for students outside of the current user's section visibility" do
        test_course_and_contexts do |contexts|
          events = events_for_course_and_contexts(contexts, user: @ta)
          expect(events).not_to include([@event.id, @event.event_type])
        end
      end
    end
  end

  describe "arguments" do
    before do
      record = Auditors::GradeChange::Record.new(
        "created_at" => 1.day.ago,
        "submission" => @submission
      )
      @event2 = Auditors::GradeChange::Stream.insert(record)
    end

    it "recognizes :start_time" do
      json = expect_event_for_context(@assignment, @event, start_time: 12.hours.ago)

      forbid_event_for_context(@assignment, @event2, start_time: 12.hours.ago, json:)

      json = expect_event_for_context(@course, @event, start_time: 12.hours.ago)
      forbid_event_for_context(@course, @event2, start_time: 12.hours.ago, json:)

      json = expect_event_for_context(@student, @event, type: "student", start_time: 12.hours.ago)
      forbid_event_for_context(@student, @event2, type: "student", start_time: 12.hours.ago, json:)

      json = expect_event_for_context(@teacher, @event, type: "grader", start_time: 12.hours.ago)
      forbid_event_for_context(@teacher, @event2, type: "grader", start_time: 12.hours.ago, json:)

      test_course_and_contexts do |contexts|
        json = expect_event_for_course_and_contexts(contexts, @event, start_time: 12.hours.ago)
        forbid_event_for_course_and_contexts(contexts, @event2, start_time: 12.hours.ago, json:)
      end
    end

    it "recognizes :end_time" do
      json = expect_event_for_context(@assignment, @event2, end_time: 12.hours.ago)
      forbid_event_for_context(@assignment, @event, end_time: 12.hours.ago, json:)

      json = forbid_event_for_context(@student, @event, type: "student", end_time: 12.hours.ago)
      expect_event_for_context(@student, @event2, type: "student", end_time: 12.hours.ago, json:)

      json = expect_event_for_context(@course, @event2, end_time: 12.hours.ago)
      forbid_event_for_context(@course, @event, end_time: 12.hours.ago, json:)

      json = expect_event_for_context(@teacher, @event2, type: "grader", end_time: 12.hours.ago)
      forbid_event_for_context(@teacher, @event, type: "grader", end_time: 12.hours.ago, json:)

      test_course_and_contexts do |contexts|
        json = expect_event_for_course_and_contexts(contexts, @event2, end_time: 12.hours.ago)
        forbid_event_for_course_and_contexts(contexts, @event, end_time: 12.hours.ago, json:)
      end
    end

    it "includes a grade_current key when passed 'current_grade' in the include param" do
      events = fetch_for_context(@assignment, include: ["current_grade"])["events"]
      expect(events.first).to have_key "grade_current"
    end

    it "does not include a grade_current key when 'current_grade' is not in the include param" do
      events = fetch_for_context(@assignment, include: [])["events"]
      expect(events.first).not_to have_key "grade_current"
    end

    it "does not include a grade_current key in the absence of an include param" do
      events = fetch_for_context(@assignment)["events"]
      expect(events.first).not_to have_key "grade_current"
    end
  end

  context "deleted entities" do
    it "404s for inactive assignments" do
      @assignment.destroy
      fetch_for_context(@assignment, expected_status: 404)
    end

    it "allows inactive assignments when used with a course" do
      @assignment.destroy
      fetcher = lambda do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 200)
      end
      contexts = { course: @course, assignment: @assignment }
      fetcher.call(contexts)
      contexts[:grader] = @teacher
      fetcher.call(contexts)
      contexts[:student] = @student
      fetcher.call(contexts)
      contexts.delete(:grader)
      fetcher.call(contexts)
    end

    it "allows inactive courses" do
      @course.destroy
      fetch_for_context(@course, expected_status: 200)
      test_course_and_contexts do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 200)
      end
    end

    it "404s for inactive students" do
      @student.destroy
      fetch_for_context(@student, expected_status: 404, type: "student")
    end

    it "allows inactive students when used with a course" do
      @student.destroy
      fetcher = lambda do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 200)
      end
      contexts = { course: @course, assignment: @assignment, grader: @teacher, student: @student }
      fetcher.call(contexts)
      contexts.delete(:grader)
      fetcher.call(contexts)
      contexts.delete(:assignment)
      fetcher.call(contexts)
      contexts = { course: @course, student: @student }
      fetcher.call(contexts)
    end

    it "404s for inactive grader" do
      @teacher.destroy
      fetch_for_context(@teacher, expected_status: 404, type: "grader")
    end

    it "allows inactive graders when used with a course" do
      @teacher.destroy
      fetcher = lambda do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 200)
      end
      contexts = { course: @course, assignment: @assignment, grader: @teacher, student: @student }
      fetcher.call(contexts)
      contexts.delete(:student)
      fetcher.call(contexts)
      contexts.delete(:assignment)
      fetcher.call(contexts)
      contexts[:student] = @student
      fetcher.call(contexts)
    end
  end

  describe "courses not found" do
    context "for_course" do
      let(:nonexistent_course) { -1 }
      let(:params) do
        {
          assignment_id: @assignment.id,
          course_id: nonexistent_course,
          controller: :grade_change_audit_api,
          action: :for_course,
          format: :json
        }
      end
      let(:path) { "/api/v1/audit/grade_change/courses/#{nonexistent_course}" }

      it "returns a 404 when admin" do
        api_call_as_user(@viewing_user, :get, path, params, {}, {}, expected_status: 404)
      end

      it "returns a 401 when teacher" do
        api_call_as_user(@teacher, :get, path, params, {}, {}, expected_status: 401)
      end

      it "returns a 401 when not a teacher nor admin" do
        user = user_model
        api_call_as_user(user, :get, path, params, {}, {}, expected_status: 401)
      end
    end

    context "for_course_and_other_parameters" do
      let(:nonexistent_course) { -1 }
      let(:params) do
        {
          assignment_id: @assignment.id,
          course_id: nonexistent_course,
          controller: :grade_change_audit_api,
          action: :for_course_and_other_parameters,
          format: :json
        }
      end
      let(:path) { "/api/v1/audit/grade_change/courses/#{nonexistent_course}/assignments/#{@assignment.id}" }

      it "returns a 404 when admin" do
        api_call_as_user(@viewing_user, :get, path, params, {}, {}, expected_status: 404)
      end

      it "returns a 401 when teacher" do
        api_call_as_user(@teacher, :get, path, params, {}, {}, expected_status: 401)
      end

      it "returns a 401 when not teacher nor admin" do
        user = user_model
        api_call_as_user(user, :get, path, params, {}, {}, expected_status: 401)
      end
    end
  end

  describe "permissions" do
    it "does not authorize the endpoints with no permissions" do
      @user, @viewing_user = @user, user_model

      fetch_for_context(@course, expected_status: 401)
      fetch_for_context(@assignment, expected_status: 401)
      fetch_for_context(@student, expected_status: 401, type: "student")
      fetch_for_context(@teacher, expected_status: 401, type: "grader")
      test_course_and_contexts do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 401)
      end
    end

    it "does not authorize the endpoints with :view_all_grades, :view_grade_changes and :manage_grades revoked" do
      RoleOverride.manage_role_override(@account_user.account,
                                        @account_user.role,
                                        :view_grade_changes.to_s,
                                        override: false)
      RoleOverride.manage_role_override(@account_user.account,
                                        @account_user.role,
                                        :manage_grades.to_s,
                                        override: false)
      RoleOverride.manage_role_override(@account_user.account,
                                        @account_user.role,
                                        :view_all_grades.to_s,
                                        override: false)

      fetch_for_context(@course, expected_status: 401)
      fetch_for_context(@assignment, expected_status: 401)
      fetch_for_context(@student, expected_status: 401, type: "student")
      fetch_for_context(@teacher, expected_status: 401, type: "grader")
      test_course_and_contexts do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 401)
      end
    end

    it "does not allow other account models" do
      new_root_account = Account.create!(name: "New Account")
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(new_root_account)
      @viewing_user = user_with_pseudonym(account: new_root_account)

      fetch_for_context(@course, expected_status: 401)
      fetch_for_context(@assignment, expected_status: 401)
      fetch_for_context(@student, expected_status: 401, type: "student")
      fetch_for_context(@teacher, expected_status: 401, type: "grader")
      test_course_and_contexts do |contexts|
        fetch_for_course_and_other_contexts(contexts, expected_status: 401)
      end
    end

    context "for teachers" do
      it "returns a 401 on for_assignment" do
        fetch_for_context(@assignment, expected_status: 401, user: @teacher)
      end

      it "returns a 401 on for_student" do
        fetch_for_context(@student, expected_status: 401, type: "student", user: @teacher)
      end

      it "returns a 401 on for_grader" do
        fetch_for_context(@teacher, expected_status: 401, type: "grader", user: @teacher)
      end

      it "returns a 200 on for_course" do
        fetch_for_context(@course, expected_status: 200, user: @teacher)
      end

      it "returns a 200 on for_course for a concluded course" do
        @course.complete!
        fetch_for_context(@course, expected_status: 200, user: @teacher)
      end

      it "returns a 200 on for_course_and_other_parameters" do
        test_course_and_contexts do |context|
          fetch_for_course_and_other_contexts(context, expected_status: 200, user: @teacher)
        end
      end

      it "returns a 401 on for_course when not teacher in that course" do
        other_teacher = User.create!
        Course.create!.enroll_teacher(other_teacher).accept!
        fetch_for_context(@course, expected_status: 401, user: other_teacher)
      end

      it "returns a 401 on for_course_and_other_parameters when not teacher in that course" do
        other_teacher = User.create!
        Course.create!.enroll_teacher(other_teacher).accept!
        test_course_and_contexts do |context|
          fetch_for_course_and_other_contexts(context, expected_status: 401, user: other_teacher)
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      before do
        @new_root_account = @shard2.activate { Account.create!(name: "New Account") }
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(@new_root_account)
        allow(@new_root_account).to receive(:grants_right?).and_return(true)
        @viewing_user = user_with_pseudonym(account: @new_root_account)
      end

      it "404s if nothing matches the type" do
        fetch_for_context(@student, expected_status: 404, type: "student")
        fetch_for_context(@teacher, expected_status: 404, type: "grader")
      end

      it "works for teachers" do
        course_with_teacher(account: @new_root_account, user: @teacher)
        fetch_for_context(@teacher, expected_status: 200, type: "grader")
      end

      it "works for students" do
        course_with_student(account: @new_root_account, user: @student)
        fetch_for_context(@student, expected_status: 200, type: "student")
      end
    end
  end

  describe "pagination" do
    before do
      Auditors::GradeChange.record(submission: @submission)
      Auditors::GradeChange.record(submission: @submission)
      @json = fetch_for_context(@student, per_page: 2, type: "student")
    end

    it "only returns one page of results" do
      expect(@json["events"].size).to eq 2
    end

    it "has pagination headers" do
      expect(response.headers["Link"]).to match(/rel="next"/)
    end
  end
end
