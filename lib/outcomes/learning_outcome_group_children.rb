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
    include OutcomesFeaturesHelper
    include OutcomesServiceAlignmentsHelper
    attr_reader :context

    SHORT_DESCRIPTION = "coalesce(learning_outcomes.short_description, '')"

    # E'<[^>]+>' -> removes html tags
    # E'&\\w+;'  -> removes html entities
    DESCRIPTION = "regexp_replace(regexp_replace(coalesce(learning_outcomes.description, ''), E'<[^>]+>', '', 'gi'), E'&\\w+;', ' ', 'gi')"
    MAP_CANVAS_POSTGRES_LOCALES = {
      "ar" => "arabic", # العربية
      "ca" => "spanish", # Català
      "da" => "danish", # Dansk
      "da-x-k12" => "danish", # Dansk GR/GY
      "de" => "german", # Deutsch
      "en-AU" => "english", # English (Australia)
      "en-CA" => "english", # English (Canada)
      "en-GB" => "english", # English (United Kingdom)
      "en" => "english", # English (US)
      "es" => "spanish", # Español
      "fr" => "french", # Français
      "fr-CA" => "french", # Français (Canada)
      "it" => "italian", # Italiano
      "hu" => "hungarian", # Magyar
      "nl" => "dutch", # Nederlands
      "nb" => "norwegian", # Norsk (Bokmål)
      "nb-x-k12" => "norwegian", # Norsk (Bokmål) GS/VGS
      "pt" => "portuguese", # Português
      "pt-BR" => "portuguese", # Português do Brasil
      "ru" => "russian", # pу́сский
      "fi" => "finnish", # Suomi
      "sv" => "swedish", # Svenska
      "sv-x-k12" => "swedish", # Svenska GR/GY
      "tr" => "turkish" # Türkçe
    }.freeze

    def initialize(context = nil)
      @context = context
    end

    def total_outcomes(learning_outcome_group_id, args = {})
      if args == {} && improved_outcomes_management?
        cache_key = total_outcomes_cache_key(learning_outcome_group_id)
        Rails.cache.fetch(cache_key) do
          total_outcomes_for(learning_outcome_group_id, args)
        end
      else
        total_outcomes_for(learning_outcome_group_id, args)
      end
    end

    def not_imported_outcomes(learning_outcome_group_id, args = {})
      if group_exists?(args[:target_group_id])
        target_group = LearningOutcomeGroup.find_by(id: args[:target_group_id])
        source_group_outcome_ids = outcome_links(learning_outcome_group_id).distinct.pluck(:content_id)
        target_group_outcome_ids = outcome_links(target_group.id).distinct.pluck(:content_id)
        (source_group_outcome_ids - (source_group_outcome_ids & target_group_outcome_ids)).size
      end
    end

    def suboutcomes_by_group_id(learning_outcome_group_id, args = {})
      relation = outcome_links(learning_outcome_group_id)
      relation = filter_outcomes(relation, args[:filter])
      relation = relation.joins(:learning_outcome_content)
                         .joins("INNER JOIN #{LearningOutcomeGroup.quoted_table_name} AS logs
              ON logs.id = content_tags.associated_asset_id")

      if args[:search_query]
        relation = add_search_query(relation, args[:search_query])
        add_search_order(relation, args[:search_query])
      else
        relation.order(
          LearningOutcomeGroup.best_unicode_collation_key("logs.title"),
          LearningOutcome.best_unicode_collation_key("short_description")
        )
      end
    end

    def clear_total_outcomes_cache
      Rails.cache.delete(context_timestamp_cache_key) if improved_outcomes_management?
    end

    def self.supported_languages
      # cache this in the class since this won't change so much
      @supported_languages ||= ContentTag.connection.execute(
        "SELECT cfgname FROM pg_ts_config"
      ).to_a.pluck("cfgname")
    end

    private

    def outcome_links(learning_outcome_group_id)
      group_ids = children_ids_with_self(learning_outcome_group_id)
      relation = ContentTag.active.learning_outcome_links.where(associated_asset_id: group_ids)
      # Exclude tags for which the aligned outcome is deleted
      valid_outcome_ids = relation
                          .select("content_tags.content_id")
                          .joins("LEFT OUTER JOIN #{LearningOutcome.quoted_table_name} AS outcomes ON content_tags.content_id = outcomes.id")
                          .where("outcomes.workflow_state<>'deleted'")
      relation.where(content_id: valid_outcome_ids)
    end

    def filter_outcomes(relation, filter)
      if %w[WITH_ALIGNMENTS NO_ALIGNMENTS].include?(filter) && improved_outcomes_management_enabled?(@context)
        outcomes_with_alignments_in_context = ContentTag
                                              .not_deleted
                                              .where(
                                                tag_type: "learning_outcome",
                                                content_type: %w[Rubric Assignment AssessmentQuestionBank],
                                                context: @context
                                              )
                                              .map(&:learning_outcome_id)
                                              .uniq

        if outcome_alignment_summary_with_new_quizzes_enabled?(@context)
          outcomes_with_alignments_in_os = get_active_os_alignments(@context)

          if outcomes_with_alignments_in_os
            outcomes_with_alignments_in_context
              .concat(outcomes_with_alignments_in_os.keys.map(&:to_i))
              .uniq
          end
        end

        return relation.where(content_id: outcomes_with_alignments_in_context) if filter == "WITH_ALIGNMENTS"
        return relation.where.not(content_id: outcomes_with_alignments_in_context) if filter == "NO_ALIGNMENTS"
      end

      relation
    end

    def total_outcomes_for(learning_outcome_group_id, args = {})
      relation = outcome_links(learning_outcome_group_id)
      relation = filter_outcomes(relation, args[:filter])

      if args[:search_query]
        relation = relation.joins(:learning_outcome_content)
        relation = add_search_query(relation, args[:search_query])
      end

      relation.count
    end

    def add_search_query(relation, search_query)
      # Tried to check if the lang is supported in the same query
      # using a CASE WHEN but it wont work because it'll
      # parse to_tsvector with the not supported lang, and it'll throw an error

      sql = if self.class.supported_languages.include?(lang)
              ContentTag.sanitize_sql_array([<<~SQL.squish, lang, search_query])
                SELECT unnest(tsvector_to_array(to_tsvector(?, ?))) as token
              SQL
            else
              ContentTag.sanitize_sql_array([<<~SQL.squish, search_query])
                SELECT unnest(tsvector_to_array(to_tsvector(?))) as token
              SQL
            end

      search_query_tokens = ContentTag.connection.execute(sql).to_a.pluck("token").uniq

      short_description_query = ContentTag.sanitize_sql_array(["#{SHORT_DESCRIPTION} ~* ANY(array[?])",
                                                               search_query_tokens])
      description_query = ContentTag.sanitize_sql_array(["#{DESCRIPTION} ~* ANY(array[?])", search_query_tokens])

      relation.where("#{short_description_query} OR #{description_query}")
    end

    def add_search_order(relation, search_query)
      select_query = ContentTag.sanitize_sql_array([<<~SQL.squish, search_query, search_query])
        "content_tags".*,
        GREATEST(public.word_similarity(?, #{SHORT_DESCRIPTION}), public.word_similarity(?, #{DESCRIPTION})) as sim
      SQL

      relation.select(select_query).order(
        "sim DESC",
        LearningOutcomeGroup.best_unicode_collation_key("logs.title"),
        LearningOutcome.best_unicode_collation_key("short_description")
      )
    end

    def children_ids_with_self(learning_outcome_group_id)
      sql = <<~SQL.squish
        WITH RECURSIVE levels AS (
          SELECT id, id AS parent_id
            FROM (#{LearningOutcomeGroup.active.where(id: learning_outcome_group_id).to_sql}) AS data
          UNION ALL
          SELECT child.id AS id, parent.parent_id AS parent_id
            FROM #{LearningOutcomeGroup.quoted_table_name} child
            INNER JOIN levels parent ON parent.id = child.learning_outcome_group_id
            WHERE child.workflow_state <> 'deleted'
        )
        SELECT id FROM levels
      SQL

      LearningOutcomeGroup.connection.execute(sql).as_json.pluck("id")
    end

    def context_timestamp_cache
      Rails.cache.fetch(context_timestamp_cache_key) do
        (Time.zone.now.to_f * 1000).to_i
      end
    end

    def total_outcomes_cache_key(learning_outcome_group_id = nil)
      ["learning_outcome_group_total_outcomes",
       context_asset_string,
       context_timestamp_cache,
       learning_outcome_group_id].cache_key
    end

    def context_timestamp_cache_key
      ["learning_outcome_group_context_timestamp", context_asset_string].cache_key
    end

    def context_asset_string
      @context_asset_string ||= (context || LearningOutcomeGroup.global_root_outcome_group).global_asset_string
    end

    def improved_outcomes_management?
      @improved_outcomes_management ||= if context
                                          context.root_account.feature_enabled?(:improved_outcomes_management)
                                        else
                                          LoadAccount.default_domain_root_account.feature_enabled?(:improved_outcomes_management)
                                        end
    end

    def group_exists?(learning_outcome_group_id)
      LearningOutcomeGroup.find_by(id: learning_outcome_group_id) != nil
    end

    def lang
      # lang can be nil, so we check with instance_variable_defined? method
      unless instance_variable_defined?(:@lang)
        account = context&.root_account || LoadAccount.default_domain_root_account
        @lang = MAP_CANVAS_POSTGRES_LOCALES[account.default_locale || "en"]
      end

      @lang
    end
  end
end
