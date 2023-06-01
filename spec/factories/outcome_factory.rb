# frozen_string_literal: true

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

module Factories
  def outcome_model(opts = {})
    global = opts.delete(:global)
    if global
      outcome_group = opts.delete(:outcome_group) || LearningOutcomeGroup.find_or_create_root(nil, true)
      @outcome = LearningOutcome.new(valid_outcome_attributes.merge(opts))
    else
      context = opts.delete(:context) || @context || course_model(reusable: true)
      outcome_context = opts.delete(:outcome_context) || context
      outcome_group = opts.delete(:outcome_group) || context.root_outcome_group
      @outcome = outcome_context.created_learning_outcomes.build(valid_outcome_attributes.merge(opts))
    end
    @outcome.rubric_criterion = valid_outcome_data
    @outcome.save!
    outcome_group.add_outcome(@outcome)
    outcome_group.save!
    @outcome
  end

  def valid_outcome_attributes
    {
      title: "first new outcome",
      description: "<p>new outcome</p>"
    }
  end

  def valid_outcome_data
    {
      mastery_points: 3,
      ratings: [
        { points: 3, description: "Rockin" },
        { points: 0, description: "Lame" }
      ]
    }
  end

  def outcome_group_model(opts = {})
    context = opts[:context] || @context
    @parent_outcome_group =
      if opts[:outcome_group_id]
        LearningOutcomeGroup.for_context(context).active.find(opts.delete(:outcome_group_id))
      else
        context.root_outcome_group
      end
    @outcome_group = @parent_outcome_group.child_outcome_groups.build(valid_outcome_group_attributes.merge(opts))
    @outcome_group.save!
    @outcome_group
  end

  def valid_outcome_group_attributes
    {
      title: "new outcome group",
      description: "<p>outcome group description</p>"
    }
  end

  def outcome_with_rubric(opts = {})
    context = opts[:context] || opts[:course] || @course
    @outcome_group ||= context.root_outcome_group
    @outcome = opts[:outcome] || outcome_model(context:,
                                               outcome_context: opts[:outcome_context] || context,
                                               title: "new outcome",
                                               description: "<p>This is <b>awesome</b>.</p>",
                                               calculation_method: "highest")
    [opts[:outcome_context], context].compact.uniq.each do |ctxt|
      root = ctxt.root_outcome_group
      root.add_outcome(@outcome)
      root.save!
    end

    rubric_params = {
      title: opts[:title] || "My Rubric",
      hide_score_total: false,
      criteria: {
        "0" => {
          points: 3,
          mastery_points: opts[:mastery_points] || 0,
          description: "Outcome row",
          long_description: @outcome.description,
          ratings: {
            "0" => {
              points: 3,
              description: "Rockin'",
            },
            "1" => {
              points: 0,
              description: "Lame",
            }
          },
          learning_outcome_id: @outcome.id
        },
        "1" => {
          points: 5,
          description: "no outcome row",
          long_description: "non outcome criterion",
          ratings: {
            "0" => {
              points: 5,
              description: "Amazing",
            },
            "1" => {
              points: 3,
              description: "not too bad",
            },
            "2" => {
              points: 0,
              description: "no bueno",
            }
          }
        }
      }
    }

    @rubric = context.rubrics.build
    @rubric.update_criteria(rubric_params)
  end

  def outcome_with_individual_ratings(opts = {})
    context = opts[:context] || opts[:course] || @course
    @outcome_group ||= context.root_outcome_group
    @outcome = opts[:outcome] || outcome_model(context:,
                                               outcome_context: opts[:outcome_context] || context,
                                               title: "new outcome",
                                               description: "<p>This is <b>awesome</b>.</p>",
                                               calculation_method: "n_mastery",
                                               calculation_int: 3,
                                               rubric_criterion: {
                                                 mastery_points: 3,
                                                 points_possible: 5,
                                                 ratings: [
                                                   { description: "Rating Criteria 1", points: 5 },
                                                   { description: "Rating Criteria 2", points: 3 },
                                                   { description: "Rating Criteria 3", points: 2 }
                                                 ]
                                               })
    [opts[:outcome_context], context].compact.uniq.each do |ctxt|
      root = ctxt.root_outcome_group
      root.add_outcome(@outcome)
      root.save!
    end
  end

  def make_group_structure(group_attrs, context, parent_group = nil)
    outcomes = group_attrs.delete(:outcomes) || 0
    groups = group_attrs.delete(:groups)

    create_group_attrs = {
      context:,
      **group_attrs
    }

    create_group_attrs[:outcome_group_id] = parent_group&.id if parent_group&.id

    group = outcome_group_model(create_group_attrs)

    outcomes.times.each do |c|
      outcome_model(
        title: "#{c} #{group_attrs[:title]} outcome",
        outcome_group: group,
        context:
      )
    end

    groups&.each do |child|
      make_group_structure(child, context, group)
    end
  end
end
