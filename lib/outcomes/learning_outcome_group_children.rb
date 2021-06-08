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

    SHORT_DESCRIPTION = "coalesce(learning_outcomes.short_description, '')"

    # E'<[^>]+>' -> removes html tags
    # E'&\\w+;'  -> removes html entities
    DESCRIPTION = "regexp_replace(regexp_replace(coalesce(learning_outcomes.description, ''), E'<[^>]+>', '', 'gi'), E'&\\w+;', ' ', 'gi')"

    def initialize(context = nil)
      @context = context
    end

    def total_subgroups(learning_outcome_group_id)
      return 0 unless improved_outcomes_management?

      children_ids(learning_outcome_group_id).length
    end

    def total_outcomes(learning_outcome_group_id, args={})
      return 0 unless improved_outcomes_management?

      if args == {}
        cache_key = total_outcomes_cache_key(learning_outcome_group_id)
        Rails.cache.fetch(cache_key) do
          total_outcomes_for(learning_outcome_group_id, args)
        end
      else
        total_outcomes_for(learning_outcome_group_id, args)
      end
    end

    def suboutcomes_by_group_id(learning_outcome_group_id, args={})
      return ContentTag.none unless improved_outcomes_management?

      learning_outcome_groups_ids = children_ids(learning_outcome_group_id) << learning_outcome_group_id
      relation = ContentTag.active.learning_outcome_links.
        where(associated_asset_id: learning_outcome_groups_ids).
        joins(:learning_outcome_content).
        joins("INNER JOIN #{LearningOutcomeGroup.quoted_table_name} AS logs
              ON logs.id = content_tags.associated_asset_id")

      if args[:search_query]
        relation = add_search_query(relation, args[:search_query])
        add_search_order(relation, args[:search_query])
      else
        relation.order(
          LearningOutcomeGroup.best_unicode_collation_key('logs.title'),
          LearningOutcome.best_unicode_collation_key('short_description')
        )
      end
    end

    def clear_descendants_cache
      return unless improved_outcomes_management?

      Rails.cache.delete(descendants_cache_key)
      clear_total_outcomes_cache
    end

    def clear_total_outcomes_cache
      Rails.cache.delete(context_timestamp_cache_key) if improved_outcomes_management?
    end

    private

    def total_outcomes_for(learning_outcome_group_id, args={})
      learning_outcome_groups_ids = children_ids(learning_outcome_group_id) << learning_outcome_group_id

      relation = ContentTag.active.learning_outcome_links.
        where(associated_asset_id: learning_outcome_groups_ids).
        joins(:learning_outcome_content)

      if args[:search_query]
        relation = add_search_query(relation, args[:search_query])
      end

      relation.select(:content_id).distinct.count
    end

    def add_search_query(relation, search_query)
      search_query_tokens = search_query.split(' ')

      short_description_query = ContentTag.sanitize_sql_array(["#{SHORT_DESCRIPTION} ~* ANY(array[?])", search_query_tokens])
      description_query = ContentTag.sanitize_sql_array(["#{DESCRIPTION} ~* ANY(array[?])", search_query_tokens])

      relation.where("#{short_description_query} OR #{description_query}")
    end

    def add_search_order(relation, search_query)
      select_query = ContentTag.sanitize_sql_array([<<-SQL, search_query, search_query])
        "content_tags".*,
        GREATEST(public.word_similarity(#{SHORT_DESCRIPTION}, ?), public.word_similarity(#{DESCRIPTION}, ?)) as sim
      SQL

      relation.select(select_query).order(
        "sim DESC",
        LearningOutcomeGroup.best_unicode_collation_key('logs.title'),
        LearningOutcome.best_unicode_collation_key('short_description')
      )
    end

    def children_ids(learning_outcome_group_id)
      parent = data.find { |d| d['parent_id'] == learning_outcome_group_id }
      parent&.dig('descendant_ids')&.tr('{}', '')&.split(',') || []
    end

    def data
      Rails.cache.fetch(descendants_cache_key) do
        LearningOutcomeGroup.connection.execute(learning_outcome_group_descendants_query).as_json
      end
    end

    def learning_outcome_group_descendants_query
      <<-SQL
        WITH RECURSIVE levels AS (
          SELECT id, learning_outcome_group_id AS parent_id
            FROM (#{LearningOutcomeGroup.active.where(context: context).to_sql}) AS data
          UNION ALL
          SELECT child.id AS id, parent.parent_id AS parent_id
            FROM #{LearningOutcomeGroup.quoted_table_name} child
            INNER JOIN levels parent ON parent.id = child.learning_outcome_group_id
            WHERE child.workflow_state <> 'deleted'
        )
        SELECT parent_id, array_agg(id) AS descendant_ids FROM levels WHERE parent_id IS NOT NULL GROUP BY parent_id
      SQL
    end

    def context_timestamp_cache
      Rails.cache.fetch(context_timestamp_cache_key) do
        (Time.zone.now.to_f * 1000).to_i
      end
    end

    def descendants_cache_key
      ['learning_outcome_group_descendants', context_asset_string].cache_key
    end

    def total_outcomes_cache_key(learning_outcome_group_id = nil)
      ['learning_outcome_group_total_outcomes',
       context_asset_string,
       context_timestamp_cache,
       learning_outcome_group_id].cache_key
    end

    def context_timestamp_cache_key
      ['learning_outcome_group_context_timestamp', context_asset_string].cache_key
    end

    def context_asset_string
      (context || LearningOutcomeGroup.global_root_outcome_group).global_asset_string
    end

    def improved_outcomes_management?
      @improved_outcomes_management ||= begin
        return context.root_account.feature_enabled?(:improved_outcomes_management) if context

        LoadAccount.default_domain_root_account.feature_enabled?(:improved_outcomes_management)
      end
    end
  end
end
