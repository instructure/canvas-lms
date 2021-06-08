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
class AdjustGradeChangeTablesForOverrideGrades < CanvasPartman::Migration
  include MigrationHelpers::AddColumnAndFk

  disable_ddl_transaction!
  tag :postdeploy
  self.base_class = Auditors::ActiveRecord::GradeChangeRecord

  GRADE_CHANGE_BASE_TABLE = :auditor_grade_change_records
  COLUMNS = %i[assignment_id submission_id submission_version_number].freeze

  def self.up
    COLUMNS.each { |column| change_column_null(GRADE_CHANGE_BASE_TABLE, column, true) }

    add_column_and_fk GRADE_CHANGE_BASE_TABLE, :grading_period_id, :grading_periods, if_not_exists: true

    # The new column propagates to the partitioned tables, but the foreign key
    # constraint does not, so add it manually
    with_each_partition do |partition|
      unless connection.foreign_key_exists?(partition, column: :grading_period_id)
        foreign_key = connection.send(:foreign_key_name, partition, column: :grading_period_id)
        execute("ALTER TABLE #{connection.quote_table_name(partition)} ADD CONSTRAINT #{foreign_key} FOREIGN KEY (grading_period_id) REFERENCES #{connection.quote_table_name('grading_periods')} (id)")
      end
    end
  end

  def self.down
    remove_records_with_null_values

    remove_column GRADE_CHANGE_BASE_TABLE, :grading_period_id
    COLUMNS.each { |column| change_column_null(GRADE_CHANGE_BASE_TABLE, column, false) }
  end

  def self.remove_records_with_null_values
    null_record_scope = base_class.where("assignment_id IS NULL OR submission_id IS NULL")
    null_record_scope.order(created_at: :asc).find_ids_in_batches(batch_size: 10_000) do |ids|
      base_class.where(id: ids).delete_all
    end
  end
end
