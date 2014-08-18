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
      pseudonym = attachment.user.sis_pseudonym_for(attachment.context) if attachment.user && attachment.context.respond_to?(:root_account)
      sis_source_id, sis_user_id = "", ""
      if CanvasKaltura::ClientV3.config['kaltura_sis'].present? && CanvasKaltura::ClientV3.config['kaltura_sis'] == "1"
        sis_source_id = %Q[,"sis_source_id":"#{attachment.context.sis_source_id}"] if attachment.context.respond_to?('sis_source_id') && attachment.context.sis_source_id
        sis_user_id = %Q[,"sis_user_id":"#{pseudonym ? pseudonym.sis_user_id : ''}"] if pseudonym
        context_code = %Q[,"context_code":"#{[attachment.context_type, attachment.context_id].join('_').underscore}"]
      end
      files << {
                  :name       => attachment.display_name,
                  :url        => attachment.cacheable_s3_download_url,
                  :media_type => (attachment.content_type || "").match(/\Avideo/) ? 'video' : 'audio',
                  :partner_data  => %Q[{"attachment_id":"#{attachment.id}","context_source":"file_upload","root_account_id":"#{attachment.root_account_id}" #{sis_source_id} #{sis_user_id} #{context_code}}]
               }
    end
    res = client.bulkUploadAdd(files)

    if !res[:ready]
      if wait_for_completion
        bulk_upload_id = res[:id]
        Rails.logger.debug "waiting for bulk upload id: #{bulk_upload_id}"
        started_at = Time.now
        timeout = Setting.get('media_bulk_upload_timeout', 30.minutes.to_s).to_i
        while !res[:ready]
          if Time.now > started_at + timeout
            MediaObject.send_later_enqueue_args(:refresh_media_files, {:run_at => 1.minute.from_now, :priority => Delayed::LOW_PRIORITY}, res[:id], attachments.map(&:id), root_account_id)
            break
          end
          sleep(1.minute.to_i)
          res = client.bulkUploadGet(bulk_upload_id)
        end
      else
        MediaObject.send_later_enqueue_args(:refresh_media_files, {:run_at => 1.minute.from_now, :priority => Delayed::LOW_PRIORITY}, res[:id], attachments.map(&:id), root_account_id)
      end
    end

    if res[:ready]
      build_media_objects(res, root_account_id)
    end
    res
  end
end
