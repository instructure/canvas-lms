# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Outcomes
  class LearningOutcomeGroupChildren
    attr_reader :context

    def initialize(context = nil)
      @context = context
    end

    def total_subgroups(learning_outcome_group_id)
      children_ids(learning_outcome_group_id).length
    end

    def total_outcomes(learning_outcome_group_id)
      ids = children_ids(learning_outcome_group_id) << learning_outcome_group_id

      ContentTag.active.learning_outcome_links.
        where(associated_asset_id: ids).
        joins(:learning_outcome_content).
        select(:content_id).
        distinct.
        count
    end

    private

    def children_ids(learning_outcome_group_id)
      parent = data.find { |d| d['parent_id'] == learning_outcome_group_id }
      parent&.dig('descendant_ids')&.tr('{}', '')&.split(',') || []
    end

    def data
      @data ||= begin
        LearningOutcomeGroup.connection.execute(<<-SQL).as_json
          WITH RECURSIVE levels AS (
            SELECT id, learning_outcome_group_id AS parent_id
              FROM (#{LearningOutcomeGroup.active.where(context: @context).to_sql}) AS data
            UNION ALL
            SELECT child.id AS id, parent.parent_id AS parent_id
              FROM #{LearningOutcomeGroup.quoted_table_name} child
              INNER JOIN levels parent ON parent.id = child.learning_outcome_group_id
              WHERE child.workflow_state <> 'deleted'
          )
          SELECT parent_id, array_agg(id) AS descendant_ids FROM levels WHERE parent_id IS NOT NULL GROUP BY parent_id
        SQL
      end
    end
  end
end
