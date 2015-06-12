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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe "GradeChangeAudit API", type: :request do
  context "not configured" do
    before do
      Canvas::Cassandra::DatabaseBuilder.stubs(:configured?).with('auditors').returns(false)
      user_with_pseudonym(account: Account.default)
      @user.account_users.create(account: Account.default)
    end

    it "should 404" do
      raw_api_call(:get, "/api/v1/audit/grade_change/students/#{@user.id}", controller: 'grade_change_audit_api', action: "for_student", student_id: @user.id.to_s, format: 'json')
      assert_status(404)
    end
  end

  context "configured" do
    include_examples "cassandra audit logs"

    before do
      @request_id = SecureRandom.uuid
      RequestContextGenerator.stubs( :request_id => @request_id )

      @domain_root_account = Account.default
      @viewing_user = user_with_pseudonym(account: @domain_root_account)
      @account_user = @viewing_user.account_users.create(:account => @domain_root_account)

      course_with_teacher(account: @domain_root_account, user: user_with_pseudonym(account: @domain_root_account))
      student_in_course(user: user_with_pseudonym(account: @domain_root_account))

      @assignment = @course.assignments.create!(:title => 'Assignment', :points_possible => 10)
      @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
      @event = Auditors::GradeChange.record(@submission)
    end

    def fetch_for_context(context, options={})
      type = context.class.to_s.downcase unless type = options.delete(:type)
      id = Shard.global_id_for(context).to_s

      arguments = { controller: 'grade_change_audit_api', action: "for_#{type}", :"#{type}_id" => id, format: 'json' }
      query_string = []

      if per_page = options.delete(:per_page)
        arguments[:per_page] = per_page.to_s
        query_string << "per_page=#{arguments[:per_page]}"
      end

      if start_time = options.delete(:start_time)
        arguments[:start_time] = start_time.iso8601
        query_string << "start_time=#{arguments[:start_time]}"
      end

      if end_time = options.delete(:end_time)
        arguments[:end_time] = end_time.iso8601
        query_string << "end_time=#{arguments[:end_time]}"
      end

      if account = options.delete(:account)
        arguments[:account_id] = Shard.global_id_for(account).to_s
        query_string << "account_id=#{arguments[:account_id]}"
      end

      path = "/api/v1/audit/grade_change/#{type.pluralize}/#{id}"
      path += "?" + query_string.join('&') if query_string.present?
      api_call_as_user(@viewing_user, :get, path, arguments, {}, {}, options.slice(:expected_status))
    end

    def expect_event_for_context(context, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_context(context, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
                    .to include([event.id, event.event_type])
      json
    end

    def forbid_event_for_context(context, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_context(context, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
                    .not_to include([event.id, event.event_type])
      json
    end

    context "nominal cases" do
      it "should include events at context endpoint" do
        expect_event_for_context(@assignment, @event)
        expect_event_for_context(@course, @event)
        expect_event_for_context(@student, @event, type: "student")
        expect_event_for_context(@teacher, @event, type: "grader")
      end
    end

    describe "arguments" do
      before do
        record = Auditors::GradeChange::Record.new(
          'created_at' => 1.day.ago,
          'submission' => @submission,
        )
        @event2 = Auditors::GradeChange::Stream.insert(record)
      end

      it "should recognize :start_time" do
        json = expect_event_for_context(@assignment, @event, start_time: 12.hours.ago)
        forbid_event_for_context(@assignment, @event2, start_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@course, @event, start_time: 12.hours.ago)
        forbid_event_for_context(@course, @event2, start_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@student, @event, type: "student", start_time: 12.hours.ago)
        forbid_event_for_context(@student, @event2, type: "student", start_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@teacher, @event, type: "grader", start_time: 12.hours.ago)
        forbid_event_for_context(@teacher, @event2, type: "grader", start_time: 12.hours.ago, json: json)
      end

      it "should recognize :end_time" do
        json = expect_event_for_context(@assignment, @event2, end_time: 12.hours.ago)
        forbid_event_for_context(@assignment, @event, end_time: 12.hours.ago, json: json)

        json = forbid_event_for_context(@student, @event, type: "student", end_time: 12.hours.ago)
        expect_event_for_context(@student, @event2, type: "student", end_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@course, @event2, end_time: 12.hours.ago)
        forbid_event_for_context(@course, @event, end_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@teacher, @event2, type: "grader", end_time: 12.hours.ago)
        forbid_event_for_context(@teacher, @event, type: "grader", end_time: 12.hours.ago, json: json)
      end
    end

    context "deleted entities" do
      it "should 404 for inactive assignments" do
        @assignment.destroy
        fetch_for_context(@assignment, expected_status: 404)
      end

      it "should 404 for inactive courses" do
        @course.destroy
        fetch_for_context(@course, expected_status: 404)
      end

      it "should 404 for inactive students" do
        @student.destroy
        fetch_for_context(@student, expected_status: 404, type: "student")
      end

      it "should 404 for inactive grader" do
        @teacher.destroy
        fetch_for_context(@teacher, expected_status: 404, type: "grader")
      end
    end

    describe "permissions" do
      it "should not authorize the endpoints with no permissions" do
        @user, @viewing_user = @user, user_model

        fetch_for_context(@course, expected_status: 401)
        fetch_for_context(@assignment, expected_status: 401)
        fetch_for_context(@student, expected_status: 401, type: "student")
        fetch_for_context(@teacher, expected_status: 401, type: "grader")
      end

      it "should not authorize the endpoints with revoking the :view_grade_changes permission" do
        RoleOverride.manage_role_override(@account_user.account, @account_user.role, :view_grade_changes.to_s, :override => false)

        fetch_for_context(@course, expected_status: 401)
        fetch_for_context(@assignment, expected_status: 401)
        fetch_for_context(@student, expected_status: 401, type: "student")
        fetch_for_context(@teacher, expected_status: 401, type: "grader")
      end

      it "should not allow other account models" do
        new_root_account = Account.create!(name: 'New Account')
        LoadAccount.stubs(:default_domain_root_account).returns(new_root_account)
        @viewing_user = user_with_pseudonym(account: new_root_account)

        fetch_for_context(@course, expected_status: 404)
        fetch_for_context(@assignment, expected_status: 404)
        fetch_for_context(@student, expected_status: 404, type: "student")
        fetch_for_context(@teacher, expected_status: 404, type: "grader")
      end

      context "sharding" do
        specs_require_sharding

        before do
          @new_root_account = @shard2.activate{ Account.create!(name: 'New Account') }
          LoadAccount.stubs(:default_domain_root_account).returns(@new_root_account)
          @new_root_account.stubs(:grants_right?).returns(true)
          @viewing_user = user_with_pseudonym(account: @new_root_account)
        end

        it "should foo" do
          fetch_for_context(@student, expected_status: 404, type: "student")
          fetch_for_context(@teacher, expected_status: 404, type: "grader")
        end

        it "should foo" do
          course_with_teacher(account: @new_root_account, user: @teacher)
          fetch_for_context(@teacher, expected_status: 200, type: "grader")
        end

        it "should foo" do
          course_with_student(account: @new_root_account, user: @student)
          fetch_for_context(@student, expected_status: 200, type: "student")
        end
      end
    end

    describe "pagination" do
      before do
        Auditors::GradeChange.record(@submission)
        Auditors::GradeChange.record(@submission)
        @json = fetch_for_context(@student, per_page: 2, type: "student")
      end

      it "should only return one page of results" do
        expect(@json['events'].size).to eq 2
      end

      it "should have pagination headers" do
        expect(response.headers['Link']).to match(/rel="next"/)
      end
    end
  end
end
