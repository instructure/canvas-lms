#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'cassandra_spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/data_fixup/fix_audit_log_uuid_indexes')

describe DataFixup::FixAuditLogUuidIndexes do

  include_examples "cassandra audit logs"

  subject do
    DataFixup::FixAuditLogUuidIndexes
  end

  before do
    @database ||= Canvas::Cassandra::DatabaseBuilder.from_config(:auditors)
    allow_any_instance_of(DataFixup::FixAuditLogUuidIndexes::Migration).to receive(:database).and_return(@database)

    @stream_tables = {}
    DataFixup::FixAuditLogUuidIndexes::Migration::INDEXES.each do |index|
      @stream_tables[index.event_stream.table] ||= []
      @stream_tables[index.event_stream.table] << index.table
    end

    # We don't know what data might be missing from previous tests
    # generating events so we need to truncate the tables before
    # we test the fixup.
    @stream_tables.each do |stream_table, index_tables|
      @database.execute("TRUNCATE #{stream_table}")

      index_tables.each do |table|
        @database.execute("TRUNCATE #{table}")
      end
    end

    # Truncate the mapping and last batch tables.
    @database.execute("TRUNCATE #{DataFixup::FixAuditLogUuidIndexes::MAPPING_TABLE}")
    @database.execute("TRUNCATE #{DataFixup::FixAuditLogUuidIndexes::LAST_BATCH_TABLE}")

    allow_any_instance_of(DataFixup::FixAuditLogUuidIndexes::IndexCleaner).to receive(:end_time).and_return(Time.now + 1.month)
    allow(SecureRandom).to receive(:uuid).and_wrap_original do |original|
      next @event_id if @event_id
      original.call
    end
  end

  def check_event_stream(event_id, stream_table, expected_total)
    # Check the stream table and make sure the right record count exits.
    # Along with the right count of corrupted events.
    corrupted_total = 0
    rows = @database.execute("SELECT id, event_type FROM #{stream_table}")
    expect(rows.count).to eq expected_total
    rows.fetch do |row|
      row = row.to_hash
      corrupted_total += 1 if row['event_type'] == 'corrupted'
    end
    expect(corrupted_total).to eq expected_total - 1

    # Check each Index table and make sure there is only one
    # with the specified event_id remaining.  Others should
    # have been changed to a new id.  Also check that the count
    # matches the total records.
    @stream_tables[stream_table].each do |index_table|
      count = 0
      rows = @database.execute("SELECT id FROM #{index_table}")
      expect(rows.count).to eq expected_total
      rows.fetch do |row|
        row = row.to_hash
        count += 1 if row['id'] == event_id
      end
      expect(count).to eq 1
    end
  end

  def corrupt_grade_changes
    event_id = CanvasSlug.generate

    (1..4).each do |i|
      time = Time.zone.now - i.days
      course = create_course
      teacher, student = create_users(2, return_type: :record)
      create_enrollment course, teacher, enrollment_type: "TeacherEnrollment"
      create_enrollment course, student

      Timecop.freeze(time) do
        @assignment = course.assignments.create!(:title => 'Assignment', :points_possible => 10)
      end
      @event_id = event_id
      Timecop.freeze(time + 1.hour) do
        @submission = @assignment.grade_student(student, grade: i, grader: teacher).first
      end
      @event_id = nil
    end

    # Lets simulate a deleted submission
    @submission.delete

    { event_id: event_id, count: 4 }
  end

  def corrupt_course_changes
    @event_id = CanvasSlug.generate
    courses = []

    (1..3).each do |i|
      time = Time.zone.now - i.days
      course = create_course
      teacher = create_users(1, return_type: :record)[0]
      create_enrollment course, teacher, enrollment_type: "TeacherEnrollment"
      courses << course

      Timecop.freeze(time) do
        Auditors::Course.record_created(course, teacher, { name: course.name }, source: :manual)
      end
    end

    event_id, @event_id = @event_id, nil

    { event_id: event_id, count: 3, courses: courses }
  end

  def corrupt_authentications
    @event_id = CanvasSlug.generate

    (1..3).each do |i|
      time = Time.now - i.days

      Timecop.freeze(time) do
        site_admin_user(user: user_with_pseudonym(account: Account.site_admin))
        Auditors::Authentication.record(@pseudonym, 'login')
      end
    end

    event_id, @event_id = @event_id, nil

    { event_id: event_id, count: 3 }
  end

  it "fixes the corrupted data" do
    skip("CCI-336")
    # Create bad data
    stream_checks = {}
    stream_checks['grade_changes'] = corrupt_grade_changes
    stream_checks['courses'] = corrupt_course_changes
    stream_checks['authentications'] = corrupt_authentications

    # Run Fix
    DataFixup::FixAuditLogUuidIndexes::Migration.run

    # Make sure the data is fixed
    stream_checks.each do |stream_table, checks|
      check_event_stream(checks[:event_id], stream_table, checks[:count])
    end
  end

  it "saves the last batch" do
    corrupt_course_changes
    index = Auditors::Course::Stream.course_index

    migration = DataFixup::FixAuditLogUuidIndexes::Migration.new
    allow(migration).to receive(:batch_size).and_return(1)
    migration.fix_index(index)

    last_batch = migration.get_last_batch(index)
    expect(last_batch.size).to eq 3
    expect(last_batch).not_to eq ['', '', 0]

    expect(migration).to receive(:update_index_batch).never
    migration.fix_index(index)
  end

  it "fixes index rows as they are queried for different keys" do
    check = corrupt_course_changes

    check[:courses].each do |course|
      expect(Auditors::Course.for_course(course).paginate(per_page: 5).size).to eq 1
    end

    check_event_stream(check[:event_id], 'courses', check[:count])
  end

  it "fixes index rows as they are queried for events that have multiple indexes" do
    users = []
    pseudonyms = []
    @event_id = CanvasSlug.generate
    (1..3).each do |i|
      time = Time.now - i.days

      Timecop.freeze(time) do
        user_with_pseudonym(account: Account.site_admin)
        site_admin_user(user: @user)
        users << @user
        pseudonyms << @pseudonym
        Auditors::Authentication.record(@pseudonym, 'login')
        Timecop.freeze(time + 10.minutes) do
          Auditors::Authentication.record(@pseudonym, 'logout')
        end
      end
    end
    @event_id = nil

    users.each do |user|
      expect(Auditors::Authentication.for_user(user).paginate(per_page: 5).size).to eq 2
    end

    pseudonyms.each do |pseudonym|
      expect(Auditors::Authentication.for_pseudonym(pseudonym).paginate(per_page: 5).size).to eq 2
    end
  end

  it "should return records within the default bucket range" do
    user_with_pseudonym(account: Account.site_admin)

    event = Auditors::Authentication.record(@pseudonym, 'login')
    first_event_at = event.created_at.to_i
    record = Auditors::Authentication::Record.generate(@pseudonym, event.event_type)
    record.attributes['id'] = event.id
    record.attributes['created_at'] = Time.now + 100.days
    Auditors::Authentication::Stream.insert(record)

    events = Auditors::Authentication.for_user(@user).paginate(per_page: 5)
    expect(events.size).to eq 1

    expect(events.first.attributes['created_at'].to_i).to eq first_event_at
  end

  it "should skip records after the bug fix was released" do
    # Create bad data
    stream_checks = {}
    stream_checks['grade_changes'] = corrupt_grade_changes
    stream_checks['courses'] = corrupt_course_changes
    stream_checks['authentications'] = corrupt_authentications

    allow_any_instance_of(DataFixup::FixAuditLogUuidIndexes::IndexCleaner).to receive(:end_time).and_return(Time.now - 1.month)

    expect_any_instance_of(DataFixup::FixAuditLogUuidIndexes::IndexCleaner).to receive(:create_tombstone).never
    expect_any_instance_of(DataFixup::FixAuditLogUuidIndexes::IndexCleaner).to receive(:create_index_entry).never
    expect_any_instance_of(DataFixup::FixAuditLogUuidIndexes::IndexCleaner).to receive(:delete_index_entry).never

    # Run Fix
    DataFixup::FixAuditLogUuidIndexes::Migration.run
  end
end
