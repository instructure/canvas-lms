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
#

class Canvadoc < ActiveRecord::Base
  include Canvadocs::Session
  alias_method :session_url, :canvadocs_session_url

  belongs_to :attachment

  has_many :canvadocs_submissions

  def upload(opts = {})
    return if document_id.present?

    url = attachment.public_url(expires_in: 7.days)

    opts.delete(:annotatable) unless Canvadocs.annotations_supported?

    response = Canvas.timeout_protection("canvadocs") {
      canvadocs_api.upload(url, opts)
    }

    if response && response['id']
      self.document_id = response['id']
      self.process_state = response['status']
      self.has_annotations = opts[:annotatable]
      self.save!
    elsif response.nil?
      raise "no response received (request timed out?)"
    else
      raise response.inspect
    end
  end

  def submissions
    self.canvadocs_submissions.
      preload(submission: :assignment).
      map &:submission
  end

  def available?
    !!(document_id && process_state != 'error' && Canvadocs.enabled?)
  end

  def has_annotations?
    Canvadocs.annotations_supported? || has_annotations == true
  end

  def self.jwt_secret
    secret = Canvas::DynamicSettings.find(service: 'canvadoc', default_ttl: 5.minutes)['secret']
    Base64.decode64(secret) if secret
  end

  # NOTE: the Setting.get('canvadoc_mime_types', ...) and the
  # Setting.get('canvadoc_submission_mime_types', ...) will
  # pull from the database first. the second parameter is there
  # as a default in case the settings are not located in the
  # db. this means that for instructure production canvas,
  # we need to update the beta and prod databases with any
  # mime_types we want to add/remove.
  # TODO: find out if opensource users need the second param
  # to the Setting.get(...,...) calls and if not, then remove
  # them entirely from the codebase (since intructure prod
  # does not need them)

  def self.mime_types
    JSON.parse Setting.get('canvadoc_mime_types', %w[
      application/excel
      application/msword
      application/pdf
      application/vnd.ms-excel
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].to_json)
  end

  def self.submission_mime_types
    JSON.parse Setting.get('canvadoc_submission_mime_types', %w[
      application/excel
      application/msword
      application/pdf
      application/vnd.ms-excel
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      image/bmp
      image/jpeg
      image/jpg
      image/png
      image/tif
      image/tiff
    ].to_json)
  end

  def self.canvadocs_api
    raise "Canvadocs isn't enabled" unless Canvadocs.enabled?
    Canvadocs::API.new(token: Canvadocs.config['api_key'],
                       base_url: Canvadocs.config['base_url'])
  end
end
