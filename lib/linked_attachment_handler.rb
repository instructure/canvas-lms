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
    klass.send(:attr_writer, :updating_user)
    klass.send(:attr_accessor, :skip_attachment_association_update)

    klass.after_save :update_attachment_associations
    klass.extend(ClassMethods)
  end

  def updating_user
    @updating_user || saving_user || try(:current_user) || try(:editor) || try(:user)
  end

  def update_attachment_associations
    return if @skip_attachment_association_update
    return unless attachment_associations_creation_enabled?

    self.class.html_fields.each do |field|
      next unless saved_change_to_attribute?(field)

      context_concern = field if SPECIAL_CONCERN_FIELDS.include?(field)
      associate_attachments_to_rce_object(send(field), updating_user, context_concern:)
    end
  end

  # course/groups attachments cannot be copied over to another course/group so we would not allow
  # cross-course attachment associations
  def exclude_cross_course_attachment_association?(attachment)
    # Only consider Course and Group contexts for cross-context rules
    source_is_course_or_group = ["Course", "Group"].include?(attachment.context_type)
    return false unless source_is_course_or_group

    # where we're associating to
    target_context_type, target_context_id = nil
    if class_name == "Course" || class_name == "Group"
      target_context_type = class_name
      target_context_id = id
    elsif respond_to?(:context_type) && ["Course", "Group"].include?(context_type)
      target_context_type = context_type
      target_context_id = context_id
    else
      return false
    end

    # Get global IDs for comparison due to sharding
    source_global_id = Shard.global_id_for(attachment.context_id)
    target_global_id = Shard.global_id_for(target_context_id)

    attachment.context_type != target_context_type || source_global_id != target_global_id
  end

  def keep_associations?(attachment, session, user)
    if instance_of?(::WikiPage) || !attachment.grants_right?(user, session, :delete)
      return true
    end

    false
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
    to_process = to_create + to_delete

    return if to_process.none?
    return unless attachment_associations_creation_enabled?
    raise "User is required to update attachment links for #{self.class}:#{try(:id)}" if user.blank? && !skip_user_verification

    if to_process.any?
      to_process.each_slice(1000) do |att_ids|
        all_attachment_associations = []

        Attachment.where(id: att_ids).find_each do |attachment|
          if to_delete.any? && to_delete.include?(Shard.global_id_for(attachment.id))
            to_delete.delete(Shard.global_id_for(attachment.id)) if keep_associations?(attachment, session, user)
          else
            next if exclude_cross_course_attachment_association?(attachment)
            next unless skip_user_verification || attachment.grants_right?(user, session, :update)

            shard.activate do
              all_attachment_associations << {
                context_type: class_name,
                context_id: id,
                attachment_id: attachment.id,
                user_id: user&.id,
                context_concern:,
                root_account_id: actual_root_account_id,
              }
            end
          end
        end

        shard.activate do
          AttachmentAssociation.insert_all(all_attachment_associations)
        end
      end
    end

    if to_delete.any?
      attachment_associations.where(context_concern:, attachment_id: to_delete).in_batches(of: 1000).destroy_all
    end
  end

  def copy_attachment_associations_from(other)
    return unless attachment_associations_enabled?

    AttachmentAssociation.copy_associations(other, [self])
  end

  def attachment_associations_creation_enabled?
    root_account&.feature_enabled?(:allow_attachment_association_creation)
  end

  def attachment_associations_enabled?
    root_account&.feature_enabled?(:file_association_access)
  end

  def access_for_attachment_association?(user, session, _association)
    grants_right?(user, session, :read) if user && respond_to?(:grants_right?)
  end

  def actual_root_account_id
    root_account_id
  end

  module ClassMethods
    def html_fields
      raise NotImplementedError
    end
  end
end
