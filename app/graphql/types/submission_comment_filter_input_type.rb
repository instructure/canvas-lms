# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Types
  class SubmissionCommentFilterInputType < Types::BaseInputObject
    graphql_name "SubmissionCommentFilterInput"

    argument :all_comments, Boolean, <<~MD, required: false, default_value: false
      If all of the comments, regardless of the submission attempt, should be returned.
      If this is true, the for_attempt argument will be ignored.
    MD

    argument :for_attempt, Integer, <<~MD, required: false, default_value: nil
      What submission attempt the comments should be returned for. If not specified,
      it will return the comments for the current submission or submission history.
    MD

    argument :peer_review, Boolean, <<~MD, required: false, default_value: false
      Whether the current user is completing a peer review and should only see
      comments authored by themselves.
    MD
  end
end
