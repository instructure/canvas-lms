#
# Copyright (C) 2011 - present Instructure, Inc.
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

class Ignore < ActiveRecord::Base
  belongs_to :user
  belongs_to :asset, polymorphic: [:assignment, :assessment_request, :quiz => 'Quizzes::Quiz']

  validates_presence_of :user_id, :asset_id, :asset_type, :purpose
  validates_inclusion_of :permanent, :in => [false, true]

  def self.cleanup
    Shackles.activate(:slave) do
      Ignore.select(:id).
        joins("LEFT JOIN #{Assignment.quoted_table_name} AS a ON a.id = ignores.asset_id AND 'Assignment' = ignores.asset_type
          LEFT JOIN #{Quizzes::Quiz.quoted_table_name} AS q ON q.id = ignores.asset_id AND 'Quizzes::Quiz' = ignores.asset_type
          LEFT JOIN #{AssessmentRequest.quoted_table_name} AS ar ON ar.id = ignores.asset_id AND 'AssessmentRequest' = ignores.asset_type
          LEFT JOIN #{Submission.quoted_table_name} AS s ON ar.asset_id = s.id AND ar.asset_type = 'Submission'
          LEFT JOIN #{Assignment.quoted_table_name} AS ara ON ara.id = s.assignment_id").
        where("(a.id IS NULL AND q.id IS NULL AND ar.id IS NULL)
          OR (a.workflow_state = 'deleted' AND a.updated_at < :deletion_time)
          OR (q.workflow_state = 'deleted' AND q.updated_at < :deletion_time)
          OR (ar.workflow_state = 'deleted' AND ar.updated_at < :deletion_time)
          OR (NOT EXISTS (
            WITH enrollments AS (
              SELECT id, completed_at
              FROM #{Enrollment.quoted_table_name}
              WHERE enrollments.user_id = ignores.user_id
                AND (enrollments.course_id = a.context_id
                 OR enrollments.course_id = q.context_id
                 OR enrollments.course_id = ara.context_id)
                AND (enrollments.workflow_state <> 'deleted'
                 OR enrollments.updated_at > :deletion_time)
            )
            SELECT 1 FROM enrollments WHERE enrollments.completed_at IS NULL
            UNION
            SELECT 1 FROM enrollments WHERE enrollments.completed_at > :conclude_time))",
          {deletion_time: 1.month.ago, conclude_time: 6.months.ago}).find_in_batches do |batch|
        Shackles.activate(:master) do
          Ignore.where(id: batch).delete_all
        end
      end
    end
  end
end
