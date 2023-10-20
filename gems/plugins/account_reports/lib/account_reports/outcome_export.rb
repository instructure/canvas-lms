# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module AccountReports
  class OutcomeExport
    include ReportHelper
    include Outcomes::OutcomeFriendlyDescriptionResolver

    def initialize(account_report)
      @account_report = account_report
      include_deleted_objects
    end

    NO_SCORE_HEADERS = %w[vendor_guid object_type title description friendly_description display_name parent_guids workflow_state].freeze
    OUTCOME_EXPORT_SCALAR_HEADERS = %w[vendor_guid object_type title description friendly_description display_name calculation_method calculation_int parent_guids workflow_state mastery_points].freeze
    OUTCOME_EXPORT_HEADERS = (OUTCOME_EXPORT_SCALAR_HEADERS + ["ratings"]).freeze

    def outcome_export
      enable_i18n_features = true
      if @account_report.account.root_account.feature_enabled?(:account_level_mastery_scales)
        write_report NO_SCORE_HEADERS, enable_i18n_features do |csv|
          export_outcome_groups(csv, NO_SCORE_HEADERS)
          export_outcomes(csv, NO_SCORE_HEADERS, false)
        end
      else
        write_report OUTCOME_EXPORT_HEADERS, enable_i18n_features do |csv|
          export_outcome_groups(csv, OUTCOME_EXPORT_SCALAR_HEADERS)
          export_outcomes(csv, OUTCOME_EXPORT_SCALAR_HEADERS, true)
        end
      end
    end

    private

    def vendor_guid_field(table, prefix: "canvas_outcome_group")
      "COALESCE(
        #{table}.vendor_guid,
        CONCAT('#{prefix}:', #{table}.id)
      )"
    end

    def outcome_group_scope
      LearningOutcomeGroup.connection.execute(<<~SQL.squish)
        WITH RECURSIVE outcome_tree AS (
          SELECT
            root_group.id,
            root_group.learning_outcome_group_id,
            root_group.workflow_state,
            #{vendor_guid_field("root_group")} AS vendor_guid,
            CAST('' AS bpchar) AS parent_guid,
            root_group.description,
            root_group.title,
            0 AS generation
          FROM #{LearningOutcomeGroup.quoted_table_name} root_group
          WHERE root_group.learning_outcome_group_id IS NULL
            AND root_group.context_id = '#{account.id}'
            AND root_group.context_type = 'Account'
            AND root_group.workflow_state <> 'deleted'
          UNION ALL
          SELECT
            child_group.id,
            child_group.learning_outcome_group_id,
            child_group.workflow_state,
            #{vendor_guid_field("child_group")} AS vendor_guid,
            ot.vendor_guid AS parent_guid,
            child_group.description,
            child_group.title,
            ot.generation + 1 as generation
          FROM #{LearningOutcomeGroup.quoted_table_name} child_group
            JOIN outcome_tree ot ON child_group.learning_outcome_group_id = ot.id
          WHERE child_group.workflow_state <> 'deleted'
        )
        SELECT *,
          CASE WHEN generation = 1 THEN NULL
               ELSE parent_guid
               END AS parent_guids
          FROM outcome_tree
          WHERE generation > 0
          ORDER BY generation ASC
      SQL
    end

    def export_outcome_groups(csv, headers)
      outcome_group_scope.each do |row|
        row["object_type"] = "group"
        csv << headers.map { |h| row[h] }
      end
    end

    def simple_outcome_scope
      ContentTag.active.where(
        context: account,
        tag_type: "learning_outcome_association"
      ).joins(:learning_outcome_content).preload(:learning_outcome_content)
    end

    def outcome_scope
      simple_outcome_scope.joins(<<~SQL.squish)
        JOIN #{LearningOutcomeGroup.quoted_table_name} learning_outcome_groups
        ON learning_outcome_groups.id = content_tags.associated_asset_id
      SQL
                          .where("learning_outcomes.workflow_state <> 'deleted'")
                          .order("learning_outcomes.id")
                          .group("learning_outcomes.id")
                          .group("content_tags.content_id")
                          .select(<<~SQL.squish)
                            content_tags.content_id,
                            learning_outcomes.*,
                            #{vendor_guid_field("learning_outcomes", prefix: "canvas_outcome")} AS vendor_guid,
                            learning_outcomes.short_description AS title,
                            STRING_AGG(
                              CASE WHEN learning_outcome_groups.learning_outcome_group_id IS NULL THEN NULL
                                   ELSE #{vendor_guid_field("learning_outcome_groups")}
                                   END,
                              ' ' ORDER BY learning_outcome_groups.id
                            ) AS parent_guids
                          SQL
    end

    def export_outcomes(csv, headers, include_ratings)
      I18n.with_locale(account.default_locale) do
        outcomes = outcome_scope
        friendly_descriptions = resolve_friendly_descriptions(account, nil, outcomes.map(&:id)).to_h { |description| [description.learning_outcome_id, description.description] }
        outcomes.find_each do |row|
          outcome_model = row.learning_outcome_content
          outcome = row.attributes.dup
          outcome["object_type"] = "outcome"
          criterion = outcome_model.rubric_criterion
          outcome["mastery_points"] = I18n.n(criterion[:mastery_points])
          outcome["friendly_description"] = friendly_descriptions[row.id]
          csv_row = headers.map { |h| outcome[h] }
          ratings = criterion[:ratings]
          if ratings.present? && include_ratings
            csv_row += ratings.flat_map do |r|
              r.values_at(:points, :description).tap do |p|
                p[0] = I18n.n(p[0]) if p[0]
              end
            end
          end
          csv << csv_row
        end
      end
    end
  end
end
