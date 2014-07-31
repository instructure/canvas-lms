#
# Copyright (C) 2014 Instructure, Inc.
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
    DataFixup::FixAuditLogUuidIndexes::Migration.any_instance.stubs(:database).returns(@database)

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
  end

  def check_event_stream(event_id, stream_table, expected_total)
    # Check the stream table and make sure the right record count exits.
    # Along with the right count of corrupted events.
    corrupted_total = 0
    rows = @database.execute("SELECT id, event_type FROM #{stream_table}")
    rows.count.should == expected_total
    rows.fetch do |row|
      row = row.to_hash
      corrupted_total += 1 if row['event_type'] == 'corrupted'
    end
    corrupted_total.should == expected_total - 1

    # Check each Index table and make sure there is only one
    # with the specified event_id remaining.  Others should
    # have been changed to a new id.  Also check that the count
    # matches the total records.
    @stream_tables[stream_table].each do |index_table|
      count = 0
      rows = @database.execute("SELECT id FROM #{index_table}")
      rows.count.should == expected_total
      rows.fetch do |row|
        row = row.to_hash
        count += 1 if row['id'] == event_id
      end
      count.should == 1
    end
  end

  def corrupt_grade_changes
    event_id = CanvasSlug.generate
    CanvasUUID.stubs(:generate).returns(event_id)

    (1..4).each do |i|
      time = Time.now - i.days

      Timecop.freeze(time) do
        course_with_teacher
        student_in_course
        @assignment = @course.assignments.create!(:title => 'Assignment', :points_possible => 10)
      end

      Timecop.freeze(time + 1.hour) do
        @submission = @assignment.grade_student(@student, grade: i, grader: @teacher).first
      end
    end

    # Lets simulate a deleted submission
    @submission.delete

    CanvasUUID.unstub(:generate)

    { event_id: event_id, count: 4 }
  end

  def corrupt_course_changes
    event_id = CanvasSlug.generate
    CanvasUUID.stubs(:generate).returns(event_id)

    (1..3).each do |i|
      time = Time.now - i.days

      Timecop.freeze(time) do
        course_with_teacher
        Auditors::Course.record_created(@course, @teacher, source: :manual)
      end
    end

    CanvasUUID.unstub(:generate)

    { event_id: event_id, count: 3 }
  end

  def corrupt_authentications
    event_id = CanvasSlug.generate
    CanvasUUID.stubs(:generate).returns(event_id)

    (1..3).each do |i|
      time = Time.now - i.days

      Timecop.freeze(time) do
        site_admin_user(user: user_with_pseudonym(account: Account.site_admin))
        Auditors::Authentication.record(@pseudonym, 'login')
      end
    end

    CanvasUUID.unstub(:generate)

    { event_id: event_id, count: 3 }
  end

  it "fixes the corrupted data" do
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
    migration.stubs(:batch_size).returns(1)
    migration.fix_index(index)

    last_batch = migration.get_last_batch(index)
    last_batch.size.should == 3
    last_batch.should_not == ['', '', 0]

    migration.expects(:update_index_batch).never
    migration.fix_index(index)
  end
end
