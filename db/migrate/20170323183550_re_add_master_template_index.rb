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

class ReAddMasterTemplateIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_index :master_courses_master_templates,
              :course_id,
              unique: true,
              where: "full_course AND workflow_state <> 'deleted'",
              name: "index_master_templates_unique_on_course_and_full"
  end
end
