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
  @outcome_group ||= LearningOutcomeGroup.default_for(@context)
  @outcome = @context.created_learning_outcomes.create!(valid_outcome_attributes.merge(opts))
  @outcome_group.add_item(@outcome)
  @outcome_group.save!
  @outcome.rubric_criterion = valid_outcome_data
  @outcome.save!
  @outcome
end

def valid_outcome_attributes
  {
    :short_description => 'first new outcome',
    :description => '<p>new outcome</p>'
  } 
end

def valid_outcome_data
    {
          :enable => '1',
          :points_possible => 3,
          :mastery_points => 4,
          :description => "Outcome row",
          :ratings => {
             'first_rating' =>
            {
              :points => 3,
              :description => "Rockin"
            },
            'second_rating' =>
            {
              :points => 0,
              :description => "Lame"
            }
          }
   }
end
