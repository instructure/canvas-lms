# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class EstimatedDuration < ActiveRecord::Base
  belongs_to :context,
             polymorphic: [:assignment,
                           :attachment,
                           :content_tag,
                           :discussion_topic,
                           :wiki_page,
                           { quiz: "Quizzes::Quiz",
                             external_tool: "ContextExternalTool" }],
             separate_columns: true,
             inverse_of: :estimated_duration,
             optional: false

  before_create :set_root_account_id

  def overridable
    assignment || quiz || content_tag || discussion_topic || wiki_page || attachment || external_tool
  end

  def set_root_account_id
    self.root_account_id = overridable&.root_account_id unless root_account_id
  end

  def minutes=(minutes)
    self.duration = "PT#{minutes}M"
  end
end
