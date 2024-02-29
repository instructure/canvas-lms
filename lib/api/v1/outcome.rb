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

module Api::V1::Outcome
  include Api::V1::Json

  # style can be :full or :abbrev; anything unrecognized defaults to :full.
  # abbreviated includes only id, title, url, subgroups_url, outcomes_url, and can_edit. full expands on
  # that by adding import_url, parent_outcome_group (if any),
  # context id and type, and description.
  def outcomes_json(outcomes, user, session, opts = {})
    outcome_ids = outcomes.map(&:id)
    opts[:assessed_outcomes] = LearningOutcomeResult.active.distinct.where(learning_outcome_id: outcome_ids).pluck(:learning_outcome_id)
    outcomes.map { |o| outcome_json(o, user, session, opts) }
  end

  def mastery_scale_opts(context)
    return {} unless (context.is_a?(Course) || context.is_a?(Account)) && mastery_scales_flag_enabled(context)

    @mastery_scale_opts ||= {}
    @mastery_scale_opts[context.asset_string] ||= begin
      method = context.resolved_outcome_calculation_method
      mastery_scale = context.resolved_outcome_proficiency
      {
        calculation_method: method&.calculation_method,
        calculation_int: method&.calculation_int,
        points_possible: mastery_scale&.points_possible,
        mastery_points: mastery_scale&.mastery_points,
        ratings: mastery_scale&.ratings_hash
      }
    end
  end

  def mastery_scales_flag_enabled(context)
    context&.root_account&.feature_enabled?(:account_level_mastery_scales) || @domain_root_account&.feature_enabled?(:account_level_mastery_scales)
  end

  # style can be :full or :abbrev; anything unrecognized defaults to :full.
  # abbreviated includes only id, title, context id and type, url, and
  # can_edit. full expands on that by adding description and criterion values
  # (if any).
  def outcome_json(outcome, user, session, opts = {})
    can_edit = lambda do
      if outcome.context_id
        outcome.context.grants_right?(user, session, :manage_outcomes)
      else
        Account.site_admin.grants_right?(user, session, :manage_global_outcomes)
      end
    end

    json_attributes = %w[id context_type context_id vendor_guid display_name]
    api_json(outcome, user, session, only: json_attributes, methods: [:title]).tap do |hash|
      hash["url"] = api_v1_outcome_path id: outcome.id
      hash["can_edit"] = can_edit.call
      hash["has_updateable_rubrics"] = outcome.updateable_rubrics?
      unless opts[:outcome_style] == :abbrev
        hash["description"] = outcome.description
        hash["friendly_description"] = opts.dig(:friendly_descriptions, outcome.id.to_s)
        context = opts[:context]
        mastery_scale_opts = mastery_scale_opts(context)
        if mastery_scale_opts.any?
          hash.merge!(mastery_scale_opts)
        elsif !mastery_scales_flag_enabled(context)
          hash["points_possible"] = outcome.rubric_criterion[:points_possible]
          hash["mastery_points"] = outcome.rubric_criterion[:mastery_points]
          hash["ratings"] = outcome.rubric_criterion[:ratings]&.clone
          if defined?(params) && params[:add_defaults] == "true"
            # add mastery level and color defaults to rubric_criterion
            outcome.find_or_set_rating_defaults(hash["ratings"], hash["mastery_points"])
          end
          # existing outcomes that have a nil calculation method should be handled as highest
          hash["calculation_method"] = outcome.calculation_method || "highest"
          if %w[decaying_average n_mastery standard_decaying_average weighted_average].include? outcome.calculation_method
            hash["calculation_int"] = outcome.calculation_int
          end
        end
        if opts[:rating_percents]
          hash["ratings"]&.each_with_index do |rating, i|
            rating[:percent] = opts[:rating_percents][i] if i < opts[:rating_percents].length
          end
        end
        hash["assessed"] = if opts[:assessed_outcomes] && outcome.context_type != "Account"
                             opts[:assessed_outcomes].include?(outcome.id)
                           else
                             outcome.assessed?
                           end
      end
    end
  end

  # style can be :full or :abbrev; anything unrecognized defaults to :full.
  # abbreviated includes only id, title, url, subgroups_url, outcomes_url, and can_edit. full expands on
  # that by adding import_url, parent_outcome_group (if any),
  # context id and type, and description.
  def outcome_group_json(outcome_group, user, session, style = :full)
    path_context = outcome_group.context || :global
    api_json(outcome_group, user, session, only: %w[id title vendor_guid]).tap do |hash|
      hash["url"] = polymorphic_path [:api_v1, path_context, :outcome_group], id: outcome_group.id
      hash["subgroups_url"] = polymorphic_path [:api_v1, path_context, :outcome_group_subgroups], id: outcome_group.id
      hash["outcomes_url"] = polymorphic_path [:api_v1, path_context, :outcome_group_outcomes], id: outcome_group.id
      hash["can_edit"] = if outcome_group.context_id
                           outcome_group.context.grants_right?(user, session, :manage_outcomes)
                         else
                           Account.site_admin.grants_right?(user, session, :manage_global_outcomes)
                         end

      unless style == :abbrev
        hash["import_url"] = polymorphic_path [:api_v1, path_context, :outcome_group_import], id: outcome_group.id
        if outcome_group.learning_outcome_group_id
          hash["parent_outcome_group"] = outcome_group_json(outcome_group.parent_outcome_group, user, session, :abbrev)
        end
        hash["context_id"] = outcome_group.context_id
        hash["context_type"] = outcome_group.context_type
        hash["description"] = outcome_group.description
      end
    end
  end

  def outcome_links_json(outcome_links, user, session, opts = {})
    return [] if outcome_links.empty?

    #
    # Assumption:  All of the outcome links have the same context.
    #
    opts[:assessed_outcomes] = LearningOutcomeResult.active.distinct.where(
      context_type: outcome_links.first.context_type,
      context_id: outcome_links.map(&:context_id),
      learning_outcome_id: outcome_links.map(&:content_id)
    ).pluck(:learning_outcome_id)

    outcome_links.map { |ol| outcome_link_json(ol, user, session, opts) }
  end

  def outcome_link_json(outcome_link, user, session, opts = {})
    opts[:outcome_style] ||= :abbrev
    opts[:outcome_group_style] ||= :abbrev
    api_json(outcome_link, user, session, only: %w[context_type context_id]).tap do |hash|
      hash["url"] = polymorphic_path [:api_v1, outcome_link.context || :global, :outcome_link],
                                     id: outcome_link.associated_asset_id,
                                     outcome_id: outcome_link.content_id
      hash["outcome_group"] = outcome_group_json(
        outcome_link.associated_asset,
        user,
        session,
        opts[:outcome_group_style]
      )
      # use learning_outcome_content vs. content in case
      # learning_outcome_content has been preloaded (e.g. by
      # ContentTag.order_by_outcome_title)
      hash["outcome"] = outcome_json(
        outcome_link.learning_outcome_content,
        user,
        session,
        opts.slice(:outcome_style, :assessed_outcomes, :context, :friendly_descriptions)
      )

      unless outcome_link.deleted?
        can_manage = if outcome_link.context
                       outcome_link.context.grants_right?(user, session, :manage_outcomes)
                     else
                       Account.site_admin.grants_right?(user, session, :manage_global_outcomes)
                     end
        hash["can_unlink"] = can_manage && outcome_link.can_destroy?
      end

      hash["assessed"] = if opts[:assessed_outcomes]
                           opts[:assessed_outcomes].include?(outcome_link.learning_outcome_content.id)
                         else
                           outcome_link.learning_outcome_content.assessed?(outcome_link[:context_id])
                         end
    end
  end
end
