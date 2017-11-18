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

require 'spec_helper'

describe DataFixup::InitNewGradeHistoryAuditLogIndexes do
  def insert_cql(use_grader: false)
    %{
      INSERT INTO grade_changes (id, created_at, context_id, assignment_id,
                                 #{'grader_id, ' if use_grader} student_id)
             VALUES (?, ?, ?, ?, #{'?,' if use_grader} ?) USING TTL ?
    }
  end

  def search_table_cql(table_name)
    "SELECT id FROM #{table_name}"
  end

  NO_GRADER_REQUIRED_TABLES = %w(
    grade_changes_by_course_assignment
    grade_changes_by_course_assignment_student
    grade_changes_by_course_student
  ).freeze

  GRADER_REQUIRED_TABLES = %w(
    grade_changes_by_course_assignment_grader
    grade_change_by_course_assignment_grader_student
    grade_changes_by_course_grader
    grade_changes_by_course_grader_student
  ).freeze

  INDEX_TABLES = (NO_GRADER_REQUIRED_TABLES + GRADER_REQUIRED_TABLES).freeze

  before(:each) do
    @database = Canvas::Cassandra::DatabaseBuilder.from_config(:auditors)
    skip("requires cassandra auditors") unless @database

    @values = [
      [
        '08d87bfc-a679-4f5d-9315-470a5fc7d7d0',
        2.months.ago,
        10000000000018,
        10000000000116,
        10000000000001,
        10000000000006,
        1.year
      ],
      [
        'fc85afda-538e-4fcb-a7fb-45697c551b71',
        1.month.ago,
        10000000000028,
        10000000000144,
        10000000000003,
        1.year
      ]
    ]

    @values.each do |v|
      @database.execute(insert_cql(use_grader: v.size > 6), *v)
    end
  end

  it 'creates all the new indexes for records with grader ids' do
    DataFixup::InitNewGradeHistoryAuditLogIndexes.run

    INDEX_TABLES.each do |table_name|
      cql = search_table_cql(table_name)
      ids = []
      @database.execute(cql).fetch do |row|
        ids << row['id']
      end

      expect(ids).to include(@values.first.first)
    end
  end

  it 'creates the expected subset of indexes for records without grader ids' do
    DataFixup::InitNewGradeHistoryAuditLogIndexes.run

    INDEX_TABLES.each do |table_name|
      cql = search_table_cql(table_name)
      ids = []
      @database.execute(cql).fetch do |row|
        ids << row['id']
      end

      if GRADER_REQUIRED_TABLES.include?(table_name)
        expect(ids).not_to include(@values.second.first)
      else
        expect(ids).to include(@values.second.first)
      end
    end
  end
end
