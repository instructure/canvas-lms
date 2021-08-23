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

module Polling
  class PollSerializer < Canvas::APISerializer
    root :poll

    attributes :id, :question, :description, :total_results, :created_at, :user_id

    has_many :poll_choices, embed: :ids

    def_delegators :@controller, :api_v1_poll_choices_url
    def_delegators :object, :total_results

    def poll_choices_url
      api_v1_poll_choices_url(object)
    end

    def filter(keys)
      if object.grants_right?(current_user, session, :update)
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    private

    def teacher_keys
      [:total_results, :user_id]
    end

    def student_keys
      [:id, :question, :description, :created_at]
    end
  end
end
