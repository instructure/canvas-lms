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

module Factories
  def planner_note_model(opts={})
    user = opts[:user] || @user || user_model
    attrs = { user_id: user.id }.merge(opts)
    @planner_note = PlannerNote.create!(valid_planner_note_attributes.merge(attrs))
  end

  def valid_planner_note_attributes
    {
      :title => 'note title',
      :details => 'note details',
      :workflow_state => 'active',
      :todo_date => Time.zone.today,
      :course => nil
    }
  end
end
