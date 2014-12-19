#
# Copyright (C) 2014 Instructure, Inc.
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
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Canvadoc < ActiveRecord::Base
  attr_accessible :document_id, :process_state

  belongs_to :attachment

  def upload
    return if document_id.present?

    url = attachment.authenticated_s3_url(:expires => 1.day)

    response = Canvas.timeout_protection("canvadocs") {
      canvadocs_api.upload(url)
    }

    if response && response['id']
      update_attributes document_id: response['id'], process_state: response['status']
    elsif response.nil?
      raise "no response received (request timed out?)"
    else
      raise response.inspect
    end
  end

  def session_url
    Canvas.timeout_protection("canvadocs", raise_on_timeout: true) do
      session = canvadocs_api.session(document_id)
      canvadocs_api.view(session["id"])
    end
  end

  def available?
    !!(document_id && process_state != 'error' && Canvadocs.enabled?)
  end

  def self.mime_types
    JSON.parse Setting.get('canvadoc_mime_types', %w[
      application/excel
      application/msword
      application/pdf
      application/vnd.ms-excel
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].to_json)
  end

  def canvadocs_api
    raise "Canvadocs isn't enabled" unless Canvadocs.enabled?
    Canvadocs::API.new(token: Canvadocs.config['api_key'],
                       base_url: Canvadocs.config['base_url'])
  end
  private :canvadocs_api
end
