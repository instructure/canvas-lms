# frozen_string_literal: true

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

class CassandraAddAdditionalGradeChangeIndexesForGradebookHistory < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.indexes
    %w(
      grade_changes_by_course_assignment
      grade_changes_by_course_assignment_grader
      grade_change_by_course_assignment_grader_student
      grade_changes_by_course_assignment_student
      grade_changes_by_course_grader
      grade_changes_by_course_grader_student
      grade_changes_by_course_student
    )
  end

  def self.up
    compression_params = if cassandra.db.use_cql3?
      "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }"
    else
      "WITH compression_parameters:sstable_compression='DeflateCompressor'"
    end

    indexes.each do |index_name|
      cassandra.execute %{
        CREATE TABLE #{index_name} (
          key text,
          ordered_id text,
          id text,
          PRIMARY KEY (key, ordered_id)
        ) #{compression_params}}
    end
  end

  def self.down
    indexes.each do |index_name|
      cassandra.execute %{DROP TABLE #{index_name};}
    end
  end
end
