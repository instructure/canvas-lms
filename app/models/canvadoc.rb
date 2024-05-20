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
#

class Canvadoc < ActiveRecord::Base
  class UploadTimeout < StandardError; end

  include Canvadocs::Session
  alias_method :session_url, :canvadocs_session_url

  belongs_to :attachment

  has_many :canvadocs_submissions

  def upload(opts = {})
    return if document_id.present?

    # Internal because canvadocs does not directly serve this URL to users but only
    # uses it for its internal conversion and then serves the converted result
    url = attachment.public_url(expires_in: 7.days, internal: true)

    opts.delete(:annotatable) unless Canvadocs.annotations_supported?

    response = Canvas.timeout_protection("canvadocs") do
      canvadocs_api.upload(url, opts)
    end

    if response && response["id"]
      self.document_id = response["id"]
      self.process_state = response["status"]
      self.has_annotations = opts[:annotatable]
      save!
    elsif response.nil?
      raise UploadTimeout, "no response received (request timed out?)"
    else
      raise response.inspect
    end
  end

  def submissions
    canvadocs_submissions
      .preload(submission: :assignment)
      .map(&:submission)
  end

  def document_id
    if ApplicationController.test_cluster?
      # since PDF documents created in production DocViewer environments are not available in
      # DocViewer beta environments, this treats as nil any document_id from any canvadoc record
      # that was last updated before the last test cluster data refresh.  Put another way, we
      # pretend here that any document_ids that came from prod data as part of the last data
      # refresh are nil.  Nilling a document_id will cause canvas to request a new document
      # conversion (and save the resulting document_id) if/when the document is next interacted
      # with by a user on this test cluster.  This will create the document on the configured
      # DocViewer test cluster for this region.
      region = ApplicationController.region
      if (refresh_timestamp = Setting.get("last_data_refresh_time_#{region}", nil)) && updated_at < Time.parse(refresh_timestamp)
        nil
      else
        self[:document_id]
      end
    else
      self[:document_id]
    end
  end

  def available?
    !!(document_id && process_state != "error" && Canvadocs.enabled?)
  end

  def has_annotations?
    Canvadocs.annotations_supported? || has_annotations == true
  end

  def self.jwt_secret
    secret = DynamicSettings.find(service: "canvadoc", default_ttl: 5.minutes)["secret"]
    Base64.decode64(secret) if secret
  end

  IWORK_MIME_TYPES = %w[
    application/vnd.apple.pages
    application/vnd.apple.keynote
    application/vnd.apple.numbers
    application/x-iwork-keynote-sffkey
    application/x-iwork-pages-sffpages
    application/x-iwork-numbers-sffnumbers
  ].freeze

  DEFAULT_MIME_TYPES = %w[
    application/excel
    application/msword
    application/pdf
    application/postscript
    application/rtf
    application/mspowerpoint
    application/vnd.ms-excel
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.template
    application/vnd.openxmlformats-officedocument.presentationml.slideshow
    application/vnd.openxmlformats-officedocument.presentationml.template
    application/vnd.openxmlformats-officedocument.wordprocessingml.template
    application/vnd.oasis.opendocument.graphics
    application/vnd.oasis.opendocument.formula
    application/vnd.oasis.opendocument.presentation
    application/vnd.oasis.opendocument.spreadsheet
    application/vnd.oasis.opendocument.text
    application/vnd.sun.xml.writer
    application/vnd.sun.xml.impress
    application/vnd.sun.xml.calc
    text/rtf
    text/plain
  ].freeze

  DEFAULT_SUBMISSION_MIME_TYPES = %w[
    application/excel
    application/msword
    application/pdf
    application/postscript
    application/rtf
    application/mspowerpoint
    application/vnd.ms-excel
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.template
    application/vnd.openxmlformats-officedocument.presentationml.slideshow
    application/vnd.openxmlformats-officedocument.presentationml.template
    application/vnd.openxmlformats-officedocument.wordprocessingml.template
    application/vnd.oasis.opendocument.graphics
    application/vnd.oasis.opendocument.formula
    application/vnd.oasis.opendocument.presentation
    application/vnd.oasis.opendocument.spreadsheet
    application/vnd.oasis.opendocument.text
    application/vnd.sun.xml.writer
    application/vnd.sun.xml.impress
    application/vnd.sun.xml.calc
    image/bmp
    image/jpeg
    image/jpg
    image/png
    image/tif
    image/tiff
    text/rtf
    text/plain
  ].freeze

  def self.mime_types
    if Account.current_domain_root_account&.feature_enabled?(:docviewer_enable_iwork_files)
      DEFAULT_MIME_TYPES + IWORK_MIME_TYPES
    else
      DEFAULT_MIME_TYPES
    end
  end

  def self.submission_mime_types
    if Account.current_domain_root_account&.feature_enabled?(:docviewer_enable_iwork_files)
      DEFAULT_SUBMISSION_MIME_TYPES + IWORK_MIME_TYPES
    else
      DEFAULT_SUBMISSION_MIME_TYPES
    end
  end

  def self.canvadocs_api
    raise "Canvadocs isn't enabled" unless Canvadocs.enabled?

    Canvadocs::API.new(token: Canvadocs.config["api_key"],
                       base_url: Canvadocs.config["base_url"])
  end
end
