# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
class AddAuditorTables < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    create_table :auditor_authentication_records do |t|
      t.string :uuid, null: false
      t.bigint :account_id, null: false
      t.string :event_type, null: false
      t.bigint :pseudonym_id, null: false
      t.string :request_id, null: false
      t.bigint :user_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :auditor_authentication_records, :uuid
    add_index :auditor_authentication_records, :pseudonym_id
    add_index :auditor_authentication_records, :user_id
    add_index :auditor_authentication_records, :account_id
    add_foreign_key :auditor_authentication_records, :accounts
    add_foreign_key :auditor_authentication_records, :pseudonyms
    add_foreign_key :auditor_authentication_records, :users

    create_table :auditor_course_records do |t|
      t.string :uuid, null: false
      t.bigint :account_id, null: false
      t.bigint :course_id, null: false
      t.text :data
      t.string :event_source, null: false
      t.string :event_type, null: false
      t.string :request_id, null: false
      t.bigint :sis_batch_id
      t.bigint :user_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :auditor_course_records, :uuid
    add_index :auditor_course_records, :course_id
    add_index :auditor_course_records, :account_id
    add_foreign_key :auditor_course_records, :accounts
    add_foreign_key :auditor_course_records, :courses
    add_foreign_key :auditor_course_records, :users

    create_table :auditor_grade_change_records do |t|
      t.string :uuid, null: false
      t.bigint :account_id, null: false
      t.bigint :root_account_id, null: false
      t.bigint :assignment_id, null: false
      t.bigint :context_id, null: false
      t.string :context_type, null: false
      t.string :event_type, null: false
      t.boolean :excused_after, null: false
      t.boolean :excused_before, null: false
      t.string :grade_after
      t.string :grade_before
      t.boolean :graded_anonymously
      t.bigint :grader_id
      t.float :points_possible_after
      t.float :points_possible_before
      t.string :request_id, null: false
      t.float :score_after
      t.float :score_before
      t.bigint :student_id, null: false
      t.bigint :submission_id, null: false
      t.integer :submission_version_number, null: false
      t.datetime :created_at, null: false
    end
    add_index :auditor_grade_change_records, :uuid
    add_index :auditor_grade_change_records, :assignment_id
    # next index covers cassandra previous indices by course_id, course_id -> assignment_id,
    # course_id -> assignment_id -> grader_id -> student_id,
    # course_id -> assignment_id -> student_id
    # (the claim is that those subsets are small enough filtering the results from the simpler index is fine)
    add_index :auditor_grade_change_records, [:context_type, :context_id, :assignment_id], name: "index_auditor_grades_by_course_and_assignment"
    add_index :auditor_grade_change_records, [:root_account_id, :grader_id], name: "index_auditor_grades_by_account_and_grader"
    add_index :auditor_grade_change_records, [:root_account_id, :student_id], name: "index_auditor_grades_by_account_and_student"
    # next index overs cassandra previous indices by course_id -> grader_id,
    # and course_id -> grader_id -> student_id (same theory as above)
    add_index :auditor_grade_change_records, [:context_type, :context_id, :grader_id], name: "index_auditor_grades_by_course_and_grader"
    add_index :auditor_grade_change_records, [:context_type, :context_id, :student_id], name: "index_auditor_grades_by_course_and_student"
    add_foreign_key :auditor_grade_change_records, :accounts
    add_foreign_key :auditor_grade_change_records, :accounts, column: :root_account_id
    add_foreign_key :auditor_grade_change_records, :assignments
    add_foreign_key :auditor_grade_change_records, :users, column: :grader_id
    add_foreign_key :auditor_grade_change_records, :users, column: :student_id
    add_foreign_key :auditor_grade_change_records, :submissions
  end

  def down
    drop_table :auditor_authentication_records
    drop_table :auditor_course_records
    drop_table :auditor_grade_change_records
  end
end
