#
# Copyright (C) 2013 Instructure, Inc.
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

module Api::V1::QuizReport
  include Api::V1::Json
  include Api::V1::Progress
  include Api::V1::Attachment

  API_ALLOWED_QUIZ_REPORT_FIELDS = %w{
    id
    quiz_id
    includes_all_versions
    anonymous
    created_at
    updated_at
    report_type
  }

  def quiz_report_json(stats, current_user, session, opts = {})
    api_json(stats, current_user, session, :only => API_ALLOWED_QUIZ_REPORT_FIELDS).tap do |hash|
      if opts[:include]
        if opts[:include].include?('progress_url') && stats.progress && stats.progress.pending?
          hash['progress_url'] = polymorphic_url([:api_v1, stats.progress])
        end
        if opts[:include].include?('file') && stats.csv_attachment
          hash['file'] = attachment_json(stats.csv_attachment, current_user)
        end
      end
    end
  end
end
