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

module AssessmentRequestHelper

  def submission_author_name_for(assessment_request, prepend = '')
    submission = @submission || assessment_request.submission
    if (assessment_request && can_do(assessment_request, @current_user, :read_assessment_user)) || !assessment_request
      "#{prepend}#{context_user_name(@context, submission.user)}"
    else
      "#{prepend}#{I18n.t(:anonymous_user, 'Anonymous User')}"
    end
  end

end