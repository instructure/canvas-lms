# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Types
  class RubricType < ApplicationObjectType
    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :criteria, [RubricCriterionType], <<~DESC, null: false
      The different criteria that makes up this rubric
    DESC

    field :free_form_criterion_comments, Boolean, null: false
    def free_form_criterion_comments
      !!object.free_form_criterion_comments
    end

    field :hide_score_total, Boolean, null: false
    def hide_score_total
      !!object.hide_score_total
    end

    field :points_possible, Float, null: true
    field :title, String, null: true
  end
end
