# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Api::V1::BlockEditorTemplate
  include Api::V1::Json

  def block_editor_template_json(block_editor_template, user, session)
    api_json(block_editor_template, user, session).tap do |json|
      json["global_id"] = block_editor_template.global_id
    end
  end

  def block_editor_templates_json(block_editor_templates, user, session)
    block_editor_templates.map { |template| block_editor_template_json(template, user, session) }
  end
end
