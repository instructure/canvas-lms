# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class BackfillAnonymousModeratedMarkingFields < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def up
    DataFixup::BackfillNulls.delay_if_production(priority: Delayed::LOW_PRIORITY, n_strand: 'long_datafixups').run(
      Assignment,
      {
        graders_anonymous_to_graders: false,
        grader_comments_visible_to_graders: false,
        grader_names_visible_to_final_grader: false,
        grader_count: 0
      }
    )
  end
end
