# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../../cassandra_spec_helper"

describe Auditors::Course do
  let(:request_id) { 42 }

  before do
    allow(RequestContextGenerator).to receive_messages(request_id:)

    @account = Account.default
    @sub_account = Account.create!(parent_account: @account)
    @sub_sub_account = Account.create!(parent_account: @sub_account)

    course_with_teacher(course_name: "Course 1", account: @sub_sub_account)

    @course.name = "Course 2"
    @course.start_at = Time.zone.today
    @course.conclude_at = Time.zone.today + 7.days
  end

  context "nominal cases" do
    it "includes event" do
      @raw_event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      @event = Auditors::ActiveRecord::CourseRecord.where(uuid: @raw_event.id).first
      expect(Auditors::Course.for_course(@course).paginate(per_page: 5)).to include(@event)
      expect(Auditors::Course.for_account(@course.account).paginate(per_page: 5)).to include(@event)
    end

    it "sets request_id" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      expect(@event.request_id).to eq request_id.to_s
    end

    it "truncates super long changes" do
      @course.syllabus_body = "ohnoes" * 10_000
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      expect(@event.attributes["data"].length < 3_000).to be_truthy
    end
  end

  context "event source" do
    it "defaults event source to :manual" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      expect(@event.event_source).to eq :manual
    end

    it "logs event with api source" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes, source: :api)
      expect(@event.event_source).to eq :api
    end

    it "logs event with sis_batch_id and event source of sis" do
      sis_batch = @account.root_account.sis_batches.create
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes, source: :sis, sis_batch:)
      expect(@event.event_source).to eq :sis
      expect(@event.sis_batch_id).to eq sis_batch.global_id
    end
  end

  context "type specific" do
    it "logs created event" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "created"
      expect(@event.event_data).to eq @course.changes
    end

    it "logs updated event" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "updated"
      expect(@event.event_data).to eq @course.changes
    end

    it "logs concluded event" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "concluded"
      expect(@event.event_data).to eq({})
    end

    it "logs unconcluded event" do
      @event = Auditors::Course.record_unconcluded(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "unconcluded"
      expect(@event.event_data).to eq({})
    end

    it "logs published event" do
      @event = Auditors::Course.record_published(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "published"
      expect(@event.event_data).to eq({})
    end

    it "logs deleted event" do
      @event = Auditors::Course.record_deleted(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "deleted"
      expect(@event.event_data).to eq({})
    end

    it "logs restored event" do
      @event = Auditors::Course.record_restored(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "restored"
      expect(@event.event_data).to eq({})
    end

    it "logs copied event" do
      @course, @copy_course = @course, course_factory(active_all: true)
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copy_course, @teacher, source: :api)

      expect(@from_event.course).to eq @copy_course
      expect(@from_event.event_type).to eq "copied_from"
      expect(@from_event.event_data[:copied_from]).to eq(Shard.global_id_for(@course))

      expect(@to_event.course).to eq @course
      expect(@to_event.event_type).to eq "copied_to"
      expect(@to_event.event_data[:copied_to]).to eq(Shard.global_id_for(@copy_course))
    end

    it "logs reset event" do
      @course, @new_course = @course, course_factory(active_all: true)
      @from_event, @to_event = Auditors::Course.record_reset(@course, @new_course, @teacher, source: :api)

      expect(@from_event.course).to eq @new_course
      expect(@from_event.event_type).to eq "reset_from"
      expect(@from_event.event_data[:reset_from]).to eq(Shard.global_id_for(@course))

      expect(@to_event.course).to eq @course
      expect(@to_event.event_type).to eq "reset_to"
      expect(@to_event.event_data[:reset_to]).to eq(Shard.global_id_for(@new_course))
    end
  end

  describe "options forwarding" do
    before do
      @raw_event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      @event = Auditors::ActiveRecord::CourseRecord.where(uuid: @raw_event.id).first

      record = Auditors::Course::Record.new(
        "course" => @course,
        "user" => @teacher,
        "event_type" => "updated",
        "event_data" => @course.changes,
        "event_source" => "manual",
        "sis_batch_id" => nil,
        "created_at" => 1.day.ago
      )
      @raw_event2 = Auditors::Course::Stream.insert(record)
      @event2 = Auditors::ActiveRecord::CourseRecord.where(uuid: @raw_event2.id).first
    end

    it "recognizes :oldest" do
      page = Auditors::Course.for_course(@course, oldest: 12.hours.ago).paginate(per_page: 2)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)

      acct_page = Auditors::Course.for_account(@course.account, oldest: 12.hours.ago).paginate(per_page: 2)
      expect(acct_page).to include(@event)
      expect(acct_page).not_to include(@event2)
    end

    it "recognizes :newest" do
      page = Auditors::Course.for_course(@course, newest: 12.hours.ago).paginate(per_page: 2)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)

      acct_page = Auditors::Course.for_account(@course.account, newest: 12.hours.ago).paginate(per_page: 2)
      expect(acct_page).to include(@event2)
      expect(acct_page).not_to include(@event)
    end
  end
end
