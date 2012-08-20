#
# Copyright (C) 2012 Instructure, Inc.
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

class CrocodocDocument < ActiveRecord::Base
  attr_accessible :uuid, :process_state, :attachment_id

  belongs_to :attachment
  has_many :crocodoc_annotations

  MIME_TYPES = %w(
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/excel
    application/vnd.ms-excel
  )

  def upload
    return if uuid.present?

    url = attachment.authenticated_s3_url(:expires_in => 1.day)

    response = Canvas.timeout_protection("crocodoc") {
      crocodoc_api.upload(url)
    }

    if response['uuid']
      update_attributes :uuid => response['uuid'], :process_state => 'QUEUED'
    else
      raise response.inspect
    end
  end

  def session_url(opts = {})
    defaults = {
      :editable => true,
      :downloadable => true,
    }.with_indifferent_access

    opts = defaults.merge(opts)

    user = opts.delete(:user)
    if user
      opts[:user] = user.crocodoc_user
    else
      opts[:editable] = false
    end

    Canvas.timeout_protection("crocodoc") do
      response = crocodoc_api.session(uuid, opts)
      session = response['session']
      crocodoc_api.view(session)
    end
  end

  def available?
    uuid && process_state != 'ERROR' && Canvas::Crocodoc.config
  end

  def crocodoc_api
    raise "Crocodoc isn't configured" unless Canvas::Crocodoc.config
    @api ||= CrocodocDocument.crocodoc_api
  end
  private :crocodoc_api

  def self.crocodoc_api
    Crocodoc::API.new(:token => Canvas::Crocodoc.config['api_key'])
  end

  def self.update_process_states
    docs = CrocodocDocument.where(:process_state => %w(QUEUED PROCESSING))
    statuses = CrocodocDocument.crocodoc_api.status(docs.map(&:uuid))
    statuses.each do |status|
      uuid, state = status['uuid'], status['status']
      CrocodocDocument.update_all(
        {:process_state => status['status']},
        {:uuid => status['uuid']}
      )
      if status['error']
        ErrorReport.log_error 'crocodoc', :message => status['error']
      end
    end
  end
end
