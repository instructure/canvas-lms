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

describe "CourseAudit API", type: :request do
  before do
    @request_id = SecureRandom.uuid
    allow(RequestContextGenerator).to receive_messages(request_id: @request_id)

    @domain_root_account = Account.default
    @viewing_user = user_with_pseudonym(account: @domain_root_account)
    @account_user = @viewing_user.account_users.create(account: @domain_root_account)

    course_with_teacher(account: @domain_root_account)

    @course.name = "Course 1"
    @course.start_at = Date.today
    @course.conclude_at = @course.start_at + 7.days

    @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
  end

  def fetch_for_context(context, id: nil, **options)
    type = context.class.to_s.downcase unless (type = options.delete(:type))
    id ||= context.id.to_s

    arguments = { controller: "course_audit_api", action: "for_#{type}", "#{type}_id": id, format: "json" }
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

    path = "/api/v1/audit/course/#{type.pluralize}/#{id}"
    path += "?" + query_string.join("&") if query_string.present?
    api_call_as_user(@viewing_user, :get, path, arguments, {}, {}, options.slice(:expected_status))
  end

  def expect_event_for_context(context, event, **options)
    json = options.delete(:json)
    json ||= fetch_for_context(context, **options)
    expect(json["events"].map { |e| [e["id"], e["event_type"]] })
      .to include([event.id, event.event_type])
    json
  end

  def forbid_event_for_context(context, event, **options)
    json = options.delete(:json)
    json ||= fetch_for_context(context, **options)
    expect(json["events"].map { |e| [e["id"], e["event_type"]] })
      .not_to include([event.id, event.event_type])
    json
  end

  context "nominal cases" do
    it "includes events at context endpoint" do
      expect_event_for_context(@course, @event)
      expect_event_for_context(@domain_root_account, @event)

      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      expect_event_for_context(@course, @event)
      expect_event_for_context(@domain_root_account, @event)

      @event = Auditors::Course.record_concluded(@course, @teacher)
      expect_event_for_context(@course, @event)
      expect_event_for_context(@domain_root_account, @event)
    end
  end

  describe "arguments" do
    before do
      record = Auditors::Course::Record.new(
        "course" => @course,
        "user" => @teacher,
        "event_type" => "updated",
        "event_data" => @course.changes,
        "event_source" => "manual",
        "created_at" => 1.day.ago
      )
      @event2 = Auditors::Course::Stream.insert(record)
    end

    it "recognizes :start_time" do
      json = expect_event_for_context(@course, @event, start_time: 12.hours.ago)
      forbid_event_for_context(@course, @event2, start_time: 12.hours.ago, json:)
    end

    it "recognizes :end_time" do
      json = forbid_event_for_context(@course, @event, end_time: 12.hours.ago)
      expect_event_for_context(@course, @event2, end_time: 12.hours.ago, json:)
    end

    it "supports using sis_id" do
      @course.update!(sis_source_id: "my_sis_id")
      expect_event_for_context(@course, @event, id: "sis_course_id:my_sis_id")
    end
  end

  context "deleted entities" do
    it "200s for inactive courses" do
      @course.destroy
      fetch_for_context(@course, expected_status: 200)
    end
  end

  describe "permissions" do
    it "does not authorize the endpoints with no permissions" do
      @user, @viewing_user = @user, user_model

      fetch_for_context(@course, expected_status: 401)
      fetch_for_context(@domain_root_account, expected_status: 401)
    end

    it "does not authorize the endpoints with revoking the :view_course_changes permission" do
      RoleOverride.manage_role_override(@account_user.account, @account_user.role, :view_course_changes.to_s, override: false)

      fetch_for_context(@course, expected_status: 401)
      fetch_for_context(@domain_root_account, expected_status: 401)
    end

    it "does not allow other account models" do
      new_root_account = Account.create!(name: "New Account")
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(new_root_account)
      @viewing_user = user_with_pseudonym(account: new_root_account)

      fetch_for_context(@course, expected_status: 404)
    end
  end

  describe "pagination" do
    before do
      Auditors::Course.record_updated(@course, @teacher, @course.changes)
      Auditors::Course.record_updated(@course, @teacher, @course.changes)
      @json = fetch_for_context(@course, per_page: 2)
    end

    it "only returns one page of results" do
      expect(@json["events"].size).to eq 2
    end

    it "has pagination headers" do
      expect(response.headers["Link"]).to match(/rel="next"/)
    end
  end
end
