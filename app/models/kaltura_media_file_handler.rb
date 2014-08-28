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
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class KalturaMediaFileHandler
  def add_media_files(attachments, wait_for_completion)
    return unless CanvasKaltura::ClientV3.config
    attachments = Array(attachments)
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    files = []
    root_account_id = attachments.map{|a| a.root_account_id }.compact.first
    attachments.select{|a| !a.media_object }.each do |attachment|
      files << {
                  :name       => attachment.display_name,
                  :url        => attachment.cacheable_s3_download_url,
                  :media_type => (attachment.content_type || "").match(/\Avideo/) ? 'video' : 'audio',
                  :partner_data  => build_partner_data(attachment)
               }
    end
    res = client.bulkUploadAdd(files)

    handle_bulk_upload_response(res, client, wait_for_completion, attachments, root_account_id)
  end

  private

  def build_partner_data(attachment)
    partner_data = {}

    if send_sis_data_to_kaltura?
      if attachment.user && attachment.context.respond_to?(:root_account)
        pseudonym = attachment.user.sis_pseudonym_for(attachment.context)
        if pseudonym
          partner_data[:sis_user_id] = pseudonym.sis_user_id
        end
      end
      if attachment.context.respond_to?(:sis_source_id) && attachment.context.sis_source_id
        partner_data[:sis_source_id] = attachment.context.sis_source_id
      end
      partner_data[:context_code] = [attachment.context_type, attachment.context_id].join("_").underscore
    end

    partner_data.merge({
      attachment_id: attachment.id.to_s,
      context_source: "file_upload",
      root_account_id: Shard.global_id_for(attachment.root_account_id).to_s,
    }).to_json
  end

  def handle_bulk_upload_response(res, client, wait_for_completion, attachments, root_account_id)
    if !res[:ready]
      if wait_for_completion
        bulk_upload_id = res[:id]
        Rails.logger.debug "waiting for bulk upload id: #{bulk_upload_id}"
        started_at = Time.now
        timeout = Setting.get('media_bulk_upload_timeout', 30.minutes.to_s).to_i
        while !res[:ready]
          if Time.now > started_at + timeout
            refresh_later(res[:id], attachments, root_account_id)
            break
          end
          sleep(1.minute.to_i)
          res = client.bulkUploadGet(bulk_upload_id)
        end
      else
        refresh_later(res[:id], attachments, root_account_id)
      end
    end

    if res[:ready]
      MediaObject.build_media_objects(res, root_account_id)
    end

    res
  end

  def refresh_later(bulk_upload_id, attachments, root_account_id)
    MediaObject.send_later_enqueue_args(:refresh_media_files, {:run_at => 1.minute.from_now, :priority => Delayed::LOW_PRIORITY}, bulk_upload_id, attachments.map(&:id), root_account_id)
  end

  def send_sis_data_to_kaltura?
    CanvasKaltura::ClientV3.config['kaltura_sis'] == "1"
  end
end
