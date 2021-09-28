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

module Filters::Polling
  protected

  def require_course
    id = params.has_key?(:course_id) ? params[:course_id] : params[:id]
    unless @course = Course.find(id)
      raise ActiveRecord::RecordNotFound.new('Course not found')
    end

    @course
  end

  def require_poll
    id = params.has_key?(:poll_id) ? params[:poll_id] : params[:id]

    unless @poll = Polling::Poll.find(id)
      raise ActiveRecord::RecordNotFound.new('Poll not found')
    end

    @poll
  end

  def require_poll_session
    id = params[:poll_session_id]

    unless @poll_session = @poll.poll_sessions.find(id)
      raise ActiveRecord::RecordNotFound.new('Poll session not found')
    end

    @poll_session
  end
end
