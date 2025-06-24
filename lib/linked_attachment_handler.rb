# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module LinkedAttachmentHandler
  SPECIAL_CONCERN_FIELDS = %w[syllabus_body terms_of_use].freeze

  def self.included(klass)
    klass.send(:attr_accessor, :saving_user)

    klass.after_save :update_attachment_associations
    klass.extend(ClassMethods)
  end

  def update_attachment_associations
    return unless attachment_associations_enabled?

    self.class.html_fields.each do |field|
      next unless saved_change_to_attribute?(field)

      context_concern = field if SPECIAL_CONCERN_FIELDS.include?(field)
      associate_attachments_to_rce_object(send(field), saving_user, context_concern:)
    end
  end

  # NB: context_concern is a virtual subdivision of context.
  # It is on purpose not a field name as it more denotes a sub-concern of
  # the context model, not necessarily an exact field.
  # Example: "terms_of_use" with an Account context denotes the custom
  # "terms of use" HTML, which should be treated as a publicly viewable
  # property of accounts, even for anonymous users, therefore any and all
  # attachments to it should also be viewable without restrictions.
  def associate_attachments_to_rce_object(html, user, context_concern: nil, session: nil, skip_user_verification: false)
    attachment_ids = Api::Html::Content.collect_attachment_ids(html) if html.present?
    attachment_ids = [] if attachment_ids.blank?

    global_ids = attachment_ids.map { |id| Shard.global_id_for(id) }
    currently_has = attachment_associations.where(context_concern:).pluck(:attachment_id).map { |id| Shard.global_id_for(id) }

    to_delete = currently_has - global_ids
    to_create = global_ids - currently_has

    return if (to_create + to_delete).none?
    return unless attachment_associations_enabled?
    raise "User is required to update attachment links" if user.blank? && !skip_user_verification

    if to_delete.any?
      attachment_associations.where(context_concern:, attachment_id: to_delete).in_batches(of: 1000).destroy_all
    end

    if to_create.any?
      to_create.each_slice(1000) do |att_ids|
        all_attachment_associations = []

        Attachment.where(id: att_ids).find_each do |attachment|
          next if !(user.nil? && skip_user_verification) && !attachment.grants_right?(user, session, :update)

          shard.activate do
            all_attachment_associations << {
              context_type: class_name,
              context_id: id,
              attachment_id: attachment.id,
              user_id: user&.id,
              context_concern:,
              root_account_id:,
            }
          end
        end

        shard.activate do
          AttachmentAssociation.insert_all(all_attachment_associations)
        end
      end
    end
  end

  def attachment_associations_enabled?
    root_account.feature_enabled?(:file_association_access)
  end

  module ClassMethods
    def html_fields
      raise NotImplementedError
    end
  end
end
