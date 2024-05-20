# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
module FilesHelper
  def load_media_object
    if params[:attachment_id].present?
      @attachment = Attachment.find_by(id: params[:attachment_id])
      @attachment = @attachment.context.attachments.find(params[:attachment_id]) if @attachment&.deleted?
      return render_unauthorized_action if @attachment&.deleted?
      return render_unauthorized_action unless @attachment&.media_entry_id

      # Look on active shard
      @media_object = MediaObject.by_media_id(@attachment&.media_entry_id).take
      # Look on attachment's shard
      @media_object ||= @attachment&.media_object_by_media_id
      # Look on attachment's root account and user shards
      @media_object ||= Shard.shard_for(@attachment.root_account).activate { MediaObject.by_media_id(@attachment.media_entry_id).take }
      @media_object ||= Shard.shard_for(@attachment.user).activate { MediaObject.by_media_id(@attachment.media_entry_id).take }
      @media_object.current_attachment = @attachment unless @media_object.nil?
      @media_id = @media_object&.id
    elsif params[:media_object_id].present?
      @media_id = params[:media_object_id]
      @media_object = MediaObject.by_media_id(@media_id).take
    end
  end

  def check_media_permissions(access_type: :download)
    if @attachment.present?
      access_allowed(@attachment, @current_user, access_type)
    else
      media_object_exists = @media_object.present?
      render_unauthorized_action unless media_object_exists
      media_object_exists
    end
  end

  def access_allowed(attachment, user, access_type)
    if params[:verifier]
      verifier_checker = Attachments::Verification.new(attachment)
      return true if verifier_checker.valid_verifier_for_permission?(params[:verifier], access_type, session)
    end
    submissions = attachment.attachment_associations.where(context_type: "Submission").preload(:context)
                            .filter_map(&:context)
    return true if submissions.any? { |submission| submission.grants_right?(user, session, access_type) }
    return render_unauthorized_action if (access_type == :update) && attachment.editing_restricted?(:content)

    authorized_action(attachment, user, access_type)
  end
end
