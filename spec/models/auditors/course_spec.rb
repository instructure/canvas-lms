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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe Auditors::Course do
  include_examples "cassandra audit logs"

  let(:request_id) { 42 }

  before do
    RequestContextGenerator.stubs( :request_id => request_id )

    @account = Account.default
    @sub_account = Account.create!(:parent_account => @account)
    @sub_sub_account = Account.create!(:parent_account => @sub_account)

    course_with_teacher(course_name: "Course 1", account: @sub_sub_account)

    @course.name = "Course 2"
    @course.start_at = Date.today
    @course.conclude_at = Date.today + 7.days
  end

  context "nominal cases" do
    it "should include event" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      expect(Auditors::Course.for_course(@course).paginate(:per_page => 5)).to include(@event)
    end

    it "should set request_id" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      expect(@event.request_id).to eq request_id.to_s
    end
  end

  context "event source" do
    it "should default event source to :manual" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      expect(@event.event_source).to eq :manual
    end

    it "should log event with api source" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes, source: :api)
      expect(@event.event_source).to eq :api
    end

    it "should log event with sis_batch_id and event source of sis" do
      sis_batch = @account.root_account.sis_batches.create
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes, source: :sis, sis_batch: sis_batch)
      expect(@event.event_source).to eq :sis
      expect(@event.sis_batch_id).to eq sis_batch.id
    end
  end

  context "type specific" do
    it "should log created event" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "created"
      expect(@event.event_data).to eq @course.changes
    end

    it "should log updated event" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "updated"
      expect(@event.event_data).to eq @course.changes
    end

    it "should log concluded event" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "concluded"
      expect(@event.event_data).to eq({})
    end

    it "should log unconcluded event" do
      @event = Auditors::Course.record_unconcluded(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "unconcluded"
      expect(@event.event_data).to eq({})
    end

    it "should log published event" do
      @event = Auditors::Course.record_published(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "published"
      expect(@event.event_data).to eq({})
    end

    it "should log deleted event" do
      @event = Auditors::Course.record_deleted(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "deleted"
      expect(@event.event_data).to eq({})
    end

    it "should log restored event" do
      @event = Auditors::Course.record_restored(@course, @teacher)
      expect(@event.course).to eq @course
      expect(@event.event_type).to eq "restored"
      expect(@event.event_data).to eq({})
    end

    it "should log copied event" do
      @course, @copy_course = @course, course_factory(active_all: true)
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copy_course, @teacher, source: :api)

      expect(@from_event.course).to eq @copy_course
      expect(@from_event.event_type).to eq "copied_from"
      expect(@from_event.event_data).to eq({ :"copied_from" => Shard.global_id_for(@course) })

      expect(@to_event.course).to eq @course
      expect(@to_event.event_type).to eq "copied_to"
      expect(@to_event.event_data).to eq({ :"copied_to" => Shard.global_id_for(@copy_course) })
    end

    it "should log reset event" do
      @course, @new_course = @course, course_factory(active_all: true)
      @from_event, @to_event = Auditors::Course.record_reset(@course, @new_course, @teacher, source: :api)

      expect(@from_event.course).to eq @new_course
      expect(@from_event.event_type).to eq "reset_from"
      expect(@from_event.event_data).to eq({ :"reset_from" => Shard.global_id_for(@course) })

      expect(@to_event.course).to eq @course
      expect(@to_event.event_type).to eq "reset_to"
      expect(@to_event.event_data).to eq({ :"reset_to" => Shard.global_id_for(@new_course) })
    end
 end

  describe "options forwarding" do
    before do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)

      record = Auditors::Course::Record.new(
        'course' => @course,
        'user' => @teacher,
        'event_type' => 'updated',
        'event_data' => @course.changes,
        'event_source' => 'manual',
        'sis_batch_id' => nil,
        'created_at' => 1.day.ago
      )
      @event2 = Auditors::Course::Stream.insert(record)
    end

    it "should recognize :oldest" do
      page = Auditors::Course.for_course(@course, oldest: 12.hours.ago).paginate(:per_page => 2)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "should recognize :newest" do
      page = Auditors::Course.for_course(@course, newest: 12.hours.ago).paginate(:per_page => 2)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end
  end
end
