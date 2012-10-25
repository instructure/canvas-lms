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
  @context ||= course_model(:reusable => true)
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
