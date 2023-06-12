# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class ProgressSerializer < Canvas::APISerializer
  root :progress

  attributes :id,
             :context_id,
             :context_type,
             :user_id,
             :tag,
             :completion,
             :workflow_state,
             :created_at,
             :updated_at,
             :message,
             :url

  def_delegators :@controller, :api_v1_progress_url

  def url
    api_v1_progress_url(object)
  end
end
