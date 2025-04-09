# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Factories
  def content_export_model(opts = {})
    user = opts.delete(:user) || @user || user_model
    course = opts.delete(:course) || @course || course_model(reusable: true)

    opts[:context] ||= course
    opts[:user] = user
    opts[:workflow_state] ||= "exported"
    opts[:progress] ||= 100.0
    opts[:export_type] ||= "common_cartridge"

    ContentExport.create!(opts)
  end
end
