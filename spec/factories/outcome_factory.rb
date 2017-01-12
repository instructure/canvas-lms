#
# Copyright (C) 2011 Instructure, Inc.
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

def outcome_model(opts={})
  @context ||= opts.delete(:context) || course_model(:reusable => true)
  @outcome_group ||= @context.root_outcome_group
  @outcome = @context.created_learning_outcomes.build(valid_outcome_attributes.merge(opts))
  @outcome.rubric_criterion = valid_outcome_data
  @outcome.save!
  @outcome_group.add_outcome(@outcome)
  @outcome_group.save!
  @outcome
end

def valid_outcome_attributes
  {
    :title => 'first new outcome',
    :description => '<p>new outcome</p>'
  }
end

def valid_outcome_data
  {
    :mastery_points => 3,
    :ratings => [
      { :points => 3, :description => "Rockin" },
      { :points => 0, :description => "Lame" }
    ]
  }
end

def outcome_group_model(opts={})
  context = opts[:context] || @context
  @parent_outcome_group =
    if opts[:outcome_group_id]
      LearningOutcomeGroup.for_context(context).active.find(opts[:outcome_group_id])
    else
      context.root_outcome_group
    end
  @outcome_group = @parent_outcome_group.child_outcome_groups.build(valid_outcome_group_attributes.merge(opts))
  @outcome_group.save!
  @outcome_group
end

def valid_outcome_group_attributes
  {
    :title => 'new outcome group',
    :description => '<p>outcome group description</p>'
  }
end

def outcome_with_rubric(opts={})
  @outcome_group ||= @course.root_outcome_group
  @outcome = @course.created_learning_outcomes.create!(
    :description => '<p>This is <b>awesome</b>.</p>',
    :short_description => 'new outcome',
    :calculation_method => 'highest'
  )
  @outcome_group.add_outcome(@outcome)
  @outcome_group.save!

  rubric_params = {
      :title => opts[:title] || 'My Rubric',
      :hide_score_total => false,
      :criteria => {
          "0" => {
              :points => 3,
              :mastery_points => opts[:mastery_points] || 0,
              :description => "Outcome row",
              :long_description => @outcome.description,
              :ratings => {
                  "0" => {
                      :points => 3,
                      :description => "Rockin'",
                  },
                  "1" => {
                      :points => 0,
                      :description => "Lame",
                  }
              },
              :learning_outcome_id => @outcome.id
          },
          "1" => {
              :points => 5,
              :description => "no outcome row",
              :long_description => 'non outcome criterion',
              :ratings => {
                  "0" => {
                      :points => 5,
                      :description => "Amazing",
                  },
                  "1" => {
                      :points => 3,
                      :description => "not too bad",
                  },
                  "2" => {
                      :points => 0,
                      :description => "no bueno",
                  }
              }
          }
      }
  }

  @rubric = @course.rubrics.build
  @rubric.update_criteria(rubric_params)
  @rubric.reload
end
