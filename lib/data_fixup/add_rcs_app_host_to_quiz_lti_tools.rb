# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::AddRcsAppHostToQuizLtiTools
  RCS_HOST_FIELD = { "canvas_rcs_host" => "$com.instructure.RCS.app_host" }.freeze

  def self.run
    ContextExternalTool.quiz_lti.find_each do |quiz_lti_tool|
      quiz_lti_tool.custom_fields = {} if quiz_lti_tool.custom_fields.nil?
      next if quiz_lti_tool.custom_fields.key?(:canvas_rcs_host)

      quiz_lti_tool.custom_fields = quiz_lti_tool.custom_fields.merge(RCS_HOST_FIELD)
      quiz_lti_tool.save
    end
  end
end
