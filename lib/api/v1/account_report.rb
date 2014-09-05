#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

module Api::V1::AccountReport
  include Api::V1::Json
  include Api::V1::Attachment

  def account_reports_json(reports, user, session)
    reports.map do |f|
      account_report_json(f, user, session)
    end
  end

  def account_report_json(report, user, session)
    json = api_json(report, user, session,
                    :only => %w(id progress parameters)
    )
    json[:status] = report.workflow_state
    json[:report] = report.report_type
    json[:file_url] = (report.attachment.nil? ? nil : "https://#{HostUrl.context_host(report.account.root_account)}/accounts/#{report.account_id}/files/#{report.attachment.id}/download")
    if report.attachment
      json[:attachment] = attachment_json(report.attachment, user)
    end
    json
  end
end