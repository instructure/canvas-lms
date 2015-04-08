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

require 'crocodoc'

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

    url = attachment.authenticated_s3_url(:expires => 1.day)

    response = Canvas.timeout_protection("crocodoc") {
      crocodoc_api.upload(url)
    }

    if response && response['uuid']
      update_attributes :uuid => response['uuid'], :process_state => 'QUEUED'
    elsif response.nil?
      raise "no response received (request timed out?)"
    else
      raise response.inspect
    end
  end

  def session_url(opts = {})
    defaults = {
      :annotations => true,
      :downloadable => true,
    }.with_indifferent_access

    opts = defaults.merge(opts)

    annotations_on = opts.delete(:annotations)

    user = opts.delete(:user)
    if user
      opts[:user] = user.crocodoc_user
    end

    opts.merge! permissions_for_user(user)

    unless annotations_on
      opts[:filter] = 'none'
      opts[:editable] = false
    end

    Canvas.timeout_protection("crocodoc", raise_on_timeout: true) do
      response = crocodoc_api.session(uuid, opts)
      session = response['session']
      crocodoc_api.view(session)
    end
  end

  def permissions_for_user(user)
    opts = {
      :filter => 'none',
      :admin => false,
      :editable => false,
    }

    if user.blank?
      return opts
    else
      opts[:editable] = true
      opts[:filter] = user.crocodoc_id!
    end

    submissions = attachment.attachment_associations.
      where(:context_type => 'Submission').
      includes(:context).
      map(&:context)

    return opts unless submissions

    if submissions.any? { |s| s.grants_right? user, :read_grade }
      opts[:filter] = 'all'

      if submissions.any? { |s| s.grants_right? user, :grade }
        opts[:admin] = true
      end
    end

    opts
  end

  def available?
    !!(uuid && process_state != 'ERROR' && Canvas::Crocodoc.config)
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
    bs = Setting.get('crocodoc_status_check_batch_size', '45').to_i
    Shackles.activate(:slave) do
      CrocodocDocument.where(:process_state => %w(QUEUED PROCESSING)).find_in_batches do |docs|
        Shackles.activate(:master) do
          statuses = []
          docs.each_slice(bs) do |sub_docs|
            statuses.concat CrocodocDocument.crocodoc_api.status(sub_docs.map(&:uuid))
          end

          bulk_updates = {}
          error_uuids = []
          statuses.each do |status|
            uuid, state = status['uuid'], status['status']
            bulk_updates[status['status']] ||= []
            bulk_updates[status['status']] << status['uuid']
            if status['status'] == 'ERROR'
              error = status['error'] || 'No explanation given'
              error_uuids << status['uuid']
              ErrorReport.log_error 'crocodoc', :message => error
            end
          end

          bulk_updates.each do |status, uuids|
            CrocodocDocument.
                where(:uuid => uuids).
                update_all(:process_state => status)
          end

          if error_uuids.present?
            error_docs = CrocodocDocument.where(:uuid => error_uuids)
            attachment_ids = error_docs.pluck(:attachment_id)
            if Canvadocs.enabled?
              Attachment.send_later_enqueue_args :submit_to_canvadocs,
                {:n_strand => "canvadocs", :max_attempts => 1},
                attachment_ids
            end
          end
        end
      end
    end
  end
end
