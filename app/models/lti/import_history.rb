# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Model for tracking the import history of LTI-related resources (currently assignments only)
# In case of assignments:
# every time, when an assignment is imported into another assignment, we create a new record in this table
# so all the assignments can be tracked which provided content for the current assignment.
# target_lti_id is the lti id of the assignment where the content was imported to. This denormalization
# is needed to make lookups more efficient.
class Lti::ImportHistory < ApplicationRecord
  extend RootAccountResolver

  belongs_to :root_account, class_name: "Account"
  validates :source_lti_id, presence: true
  validates :target_lti_id, presence: true
  validates :source_lti_id, uniqueness: { scope: :target_lti_id }

  after_commit :clear_history_cache, on: %i[create update destroy]

  def self.import_history_cache_key(lti_id)
    ["lti_activity_id_history", lti_id].cache_key
  end

  # Recursively collects all ancestor source_lti_ids for a given target_lti_id.
  def self.recursive_import_history(target_lti_id, limit: 1000)
    return [] unless target_lti_id

    GuardRail.activate(:secondary) do
      results = transaction do
        connection.statement_timeout = 30 # seconds
        sql = <<-SQL.squish
        WITH RECURSIVE history AS (
          SELECT id, source_lti_id, target_lti_id, created_at
          FROM #{quoted_table_name}
          WHERE target_lti_id = $1
        UNION ALL
          SELECT lih.id, lih.source_lti_id, lih.target_lti_id, lih.created_at
          FROM #{quoted_table_name} lih
          INNER JOIN history h ON lih.target_lti_id = h.source_lti_id
        ) SEARCH BREADTH FIRST BY id SET ordercol
        SELECT source_lti_id
        FROM history
        ORDER BY ordercol, source_lti_id, created_at DESC
        LIMIT $2
        SQL
        binds = [
          ActiveRecord::Relation::QueryAttribute.new(
            "current_lti_id",
            target_lti_id,
            ActiveRecord::Type::String.new
          ),
          ActiveRecord::Relation::QueryAttribute.new(
            "limit",
            limit,
            ActiveRecord::Type::Integer.new
          )
        ]
        connection.exec_query(sql, "LTI Import History", binds)
      end
      results.map { |r| r["source_lti_id"] }
    end
  end

  private

  def clear_history_cache
    Rails.cache.delete(self.class.import_history_cache_key(target_lti_id))
  end
end
