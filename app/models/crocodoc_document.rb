# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require "crocodoc"

class CrocodocDocument < ActiveRecord::Base
  include Canvadocs::Session

  belongs_to :attachment

  has_many :canvadocs_submissions

  MIME_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/excel
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  def upload
    return if uuid.present?

    url = attachment.public_url(expires_in: 1.day)

    begin
      response = Canvas.timeout_protection("crocodoc_upload", raise_on_timeout: true) do
        crocodoc_api.upload(url)
      end
    rescue Canvas::TimeoutCutoff
      raise Canvas::Crocodoc::CutoffError, "not uploading due to timeout protection"
    rescue Timeout::Error
      raise Canvas::Crocodoc::TimeoutError, "not uploading due to timeout error"
    end

    if response && response["uuid"]
      update uuid: response["uuid"], process_state: "QUEUED"
    elsif response.nil?
      raise "no response received"
    else
      raise response.inspect
    end
  end

  def should_migrate_to_canvadocs?
    account_context = attachment.context.try(:account) || attachment.context.try(:root_account)
    account_context.present? && account_context.migrate_to_canvadocs?
  end

  def canvadocs_can_annotate?(user)
    user != nil
  end
  private :canvadocs_can_annotate?

  def document_id
    uuid
  end
  private :document_id

  def canvadoc_options
    {
      migrate_crocodoc: true
    }
  end
  private :canvadoc_options

  def session_url(opts = {})
    return canvadocs_session_url opts.merge(canvadoc_options) if should_migrate_to_canvadocs?

    defaults = {
      annotations: true,
      downloadable: true,
    }.with_indifferent_access

    opts = defaults.merge(opts)

    annotations_on = opts.delete(:annotations)

    user = opts.delete(:user)
    if user
      opts[:user] = user.crocodoc_user
    end

    crocodoc_ids = opts[:moderated_grading_allow_list]&.pluck("crocodoc_id")
    opts.merge! permissions_for_user(user, crocodoc_ids)

    unless annotations_on
      opts[:filter] = "none"
      opts[:editable] = false
    end

    Canvas.timeout_protection("crocodoc_session", raise_on_timeout: true) do
      response = crocodoc_api.session(uuid, opts)
      session = response["session"]
      crocodoc_api.view(session)
    end
  end

  def permissions_for_user(user, allow_list = nil)
    opts = {
      filter: "none",
      admin: false,
      editable: false,
    }

    if user.blank?
      return opts
    else
      opts[:editable] = true
      opts[:filter] = user.crocodoc_id!
    end

    if submissions.any? { |s| s.grants_right? user, :read_grade }
      opts[:filter] = "all"

      if submissions.any? { |s| s.grants_right? user, :grade }
        opts[:admin] = true
      end
    end

    if submissions.map(&:assignment).any? { |a| a.peer_reviews? && a.anonymous_peer_reviews? }
      opts[:editable] = false
      opts[:filter] = "none"
    end

    apply_allow_list(user, opts, allow_list) if allow_list

    opts
  end

  def submissions
    canvadocs_submissions
      .preload(submission: :assignment)
      .map(&:submission)
  end

  def apply_allow_list(user, opts, allow_list)
    allowed_users = case opts[:filter]
                    when "all"
                      allow_list
                    when "none"
                      []
                    else
                      opts[:filter].to_s.split(",").map(&:to_i) & allow_list
                    end

    unless allowed_users.include?(user.crocodoc_id!)
      opts[:admin] = false
      opts[:editable] = false
    end

    opts[:filter] = if allowed_users.empty?
                      "none"
                    else
                      allowed_users.join(",")
                    end
  end

  def available?
    !!(uuid && process_state != "ERROR" && Canvas::Crocodoc.config)
  end

  def crocodoc_api
    raise "Crocodoc isn't configured" unless Canvas::Crocodoc.config

    @api ||= CrocodocDocument.crocodoc_api
  end
  private :crocodoc_api

  def self.crocodoc_api
    Crocodoc::API.new(token: Canvas::Crocodoc.config["api_key"])
  end

  def self.update_process_states
    bs = Setting.get("crocodoc_status_check_batch_size", "45").to_i
    GuardRail.activate(:secondary) do
      CrocodocDocument.where(process_state: %w[QUEUED PROCESSING]).find_in_batches do |docs|
        GuardRail.activate(:primary) do
          statuses = []
          docs.each_slice(bs) do |sub_docs|
            Canvas.timeout_protection("crocodoc_status") do
              statuses.concat CrocodocDocument.crocodoc_api.status(sub_docs.map(&:uuid))
            end
          end

          bulk_updates = {}
          error_uuids = []
          statuses.each do |status|
            bulk_updates[status["status"]] ||= []
            bulk_updates[status["status"]] << status["uuid"]
            next unless status["status"] == "ERROR"

            error = status["error"] || "No explanation given"
            error_uuids << status["uuid"]
            Canvas::Errors.capture "crocodoc", message: error
          end

          bulk_updates.each do |status, uuids|
            CrocodocDocument
              .where(uuid: uuids)
              .update_all(process_state: status)
          end

          if error_uuids.present?
            error_docs = CrocodocDocument.where(uuid: error_uuids)
            attachment_ids = error_docs.pluck(:attachment_id)
            if Canvadocs.enabled?
              Attachment.delay(n_strand: "canvadocs").submit_to_canvadocs(attachment_ids)
            end
          end
        end
      end
    end
  end
end
