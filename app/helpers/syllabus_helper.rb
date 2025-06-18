# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
module SyllabusHelper
  def syllabus_user_content
    syllabus_body = @context.syllabus_body || return
    user = nil
    is_public = true
    if @context.grants_right?(@current_user, session, :read)
      user = @current_user
      is_public = false
    end
    location = if @context.root_account.feature_enabled?(:disable_file_verifiers_in_public_syllabus)
                 "course_syllabus_#{@context.id}"
               end

    user_content(syllabus_body, context: @context, user:, is_public:, location:)
  end
end
