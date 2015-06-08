#
# Copyright (C) 2012 Instructure, Inc.
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
    opts[:assessed_outcomes] = LearningOutcomeResult.uniq.where(learning_outcome_id: outcome_ids).pluck(:learning_outcome_id)
    outcomes.map { |o| outcome_json(o, user, session, opts) }
  end

  # style can be :full or :abbrev; anything unrecognized defaults to :full.
  # abbreviated includes only id, title, context id and type, url, and
  # can_edit. full expands on that by adding description and criterion values
  # (if any).
  def outcome_json(outcome, user, session, opts = {})
    can_edit = lambda do
      outcome.context_id ?
          outcome.context.grants_right?(user, session, :manage_outcomes) :
          Account.site_admin.grants_right?(user, session, :manage_global_outcomes)
    end

    json_attributes = %w(id context_type context_id vendor_guid display_name)
    api_json(outcome, user, session, :only => json_attributes, :methods => [:title]).tap do |hash|
      hash['url'] = api_v1_outcome_path :id => outcome.id
      hash['can_edit'] = can_edit.call
      unless opts[:outcome_style] == :abbrev
        hash['description'] = outcome.description

        # existing outcomes that have a nil calculation method should be handled as highest
        hash['calculation_method'] = outcome.calculation_method || 'highest'

        if ["decaying_average", "n_mastery"].include? outcome.calculation_method
          hash['calculation_int'] = outcome.calculation_int
        end

        if criterion = outcome.data && outcome.data[:rubric_criterion]
          hash['points_possible'] = criterion[:points_possible]
          hash['mastery_points'] = criterion[:mastery_points]
          hash['ratings'] = criterion[:ratings]
        end

        if opts[:assessed_outcomes]
          hash['assessed'] = opts[:assessed_outcomes].include?(outcome.id)
        else
          hash['assessed'] = outcome.assessed?
        end
      end
    end
  end

  # style can be :full or :abbrev; anything unrecognized defaults to :full.
  # abbreviated includes only id, title, url, subgroups_url, outcomes_url, and can_edit. full expands on
  # that by adding import_url, parent_outcome_group (if any),
  # context id and type, and description.
  def outcome_group_json(outcome_group, user, session, style=:full)
    path_context = outcome_group.context || :global
    api_json(outcome_group, user, session, :only => %w(id title vendor_guid)).tap do |hash|
      hash['url'] = polymorphic_path [:api_v1, path_context, :outcome_group], :id => outcome_group.id
      hash['subgroups_url'] = polymorphic_path [:api_v1, path_context, :outcome_group_subgroups], :id => outcome_group.id
      hash['outcomes_url'] = polymorphic_path [:api_v1, path_context, :outcome_group_outcomes], :id => outcome_group.id
      hash['can_edit'] = outcome_group.context_id ?
        outcome_group.context.grants_right?(user, session, :manage_outcomes) :
        Account.site_admin.grants_right?(user, session, :manage_global_outcomes)

      unless style == :abbrev
        hash['import_url'] = polymorphic_path [:api_v1, path_context, :outcome_group_import], :id => outcome_group.id
        if outcome_group.learning_outcome_group_id
          hash['parent_outcome_group'] = outcome_group_json(outcome_group.parent_outcome_group, user, session, :abbrev)
        end
        hash['context_id'] = outcome_group.context_id
        hash['context_type'] = outcome_group.context_type
        hash['description'] = outcome_group.description
      end
    end
  end

  def outcome_links_json(outcome_links, user, session, opts={})
    return [] if outcome_links.empty?

    #
    # Assumption:  All of the outcome links have the same context.
    #
    opts[:assessed_outcomes] = LearningOutcomeResult.uniq.where(
      context_type: outcome_links.first.context_type,
      context_id: outcome_links.map(&:context_id),
      learning_outcome_id: outcome_links.map(&:content_id)
    ).pluck(:learning_outcome_id)

    outcome_links.map{ |ol| outcome_link_json(ol, user, session, opts) }
  end

  def outcome_link_json(outcome_link, user, session, opts={})
    opts[:outcome_style] ||= :abbrev
    opts[:outcome_group_style] ||= :abbrev
    api_json(outcome_link, user, session, :only => %w(context_type context_id)).tap do |hash|
      hash['url'] = polymorphic_path [:api_v1, outcome_link.context || :global, :outcome_link],
        :id => outcome_link.associated_asset_id,
        :outcome_id => outcome_link.content_id
      hash['outcome_group'] = outcome_group_json(
        outcome_link.associated_asset,
        user,
        session,
        opts[:outcome_group_style]
      )
      # use learning_outcome_content vs. content in case
      # learning_outcome_content has been preloaded (e.g. by
      # ContentTag.order_by_outcome_title)
      hash['outcome'] = outcome_json(
        outcome_link.learning_outcome_content,
        user,
        session,
        opts.slice(:outcome_style, :assessed_outcomes)
      )

      if opts[:assessed_outcomes]
        hash['assessed'] = opts[:assessed_outcomes].include?(outcome_link.learning_outcome_content.id)
      else
        hash['assessed'] = outcome_link.learning_outcome_content.assessed?(outcome_link[:context_id])
      end
    end
  end
end
