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
  DRAFTABLE_SUBMISSION_TYPES = %w[
    media_recording
    online_text_entry
    online_upload
    online_url
  ].freeze

  class DraftableSubmissionType < BaseEnum
    graphql_name 'DraftableSubmissionType'
    description 'Types of submissions that can have a submission draft'

    DRAFTABLE_SUBMISSION_TYPES.each { |draftable_type|
      value(draftable_type)
    }
  end
end