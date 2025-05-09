# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AttachmentAssociation < ActiveRecord::Base
  # removing this definition until we figure out how to unbreak rake db:set_ignored_columns
  # enum :field_name, %i[syllabus_body]

  belongs_to :attachment
  belongs_to :context, polymorphic: %i[conversation_message submission course group]
  belongs_to :user
  belongs_to :root_account, class_name: "Account", optional: true, inverse_of: :attachment_associations

  before_create :set_root_account_id

  after_save :set_word_count

  def self.update_associations(context, attachment_ids, user, session, field_name = nil, blank_user: false)
    global_ids = attachment_ids.map { |id| Shard.global_id_for(id) }
    currently_has = AttachmentAssociation.where(context:, field_name:).pluck(:attachment_id).map { |id| Shard.global_id_for(id) }

    to_delete = currently_has - global_ids
    to_create = global_ids - currently_has

    AttachmentAssociation.where(context:, field_name:, attachment_id: to_delete).destroy_all if to_delete.any?

    if to_create.any?
      to_create.each_slice(1000) do |att_ids|
        all_attachment_associations = []

        Attachment.where(id: att_ids).find_each do |attachment|
          next if !(user.nil? && blank_user) && !attachment.grants_right?(user, session, :update)

          all_attachment_associations << {
            context_type: context.class.name,
            context_id: context.id,
            attachment_id: attachment.id,
            user_id: user&.id,
            field_name:
          }
        end
        insert_all(all_attachment_associations, context.root_account_id)
      end
    end
  end

  def self.insert_all(records, root_account_id)
    records_with_root_account_id = records.map do |record|
      unless record[:root_account_id]
        record[:root_account_id] = root_account_id
      end
      record
    end
    super(records_with_root_account_id)
  end

  def self.verify_access(location_param, attachment_id, user, session = nil)
    splat = location_param.split("_")
    return false unless splat.length >= 2

    context_id = splat.pop
    context_type = splat.join("_").camelize
    field_name = nil
    right_to_check = :read

    if context_type == "CourseSyllabus"
      field_name = "syllabus_body"
      context_type = "Course"
      right_to_check = :read_syllabus
    end

    association = AttachmentAssociation.find_by(
      attachment: attachment_id,
      context_id:,
      context_type:,
      field_name:
    )

    return false unless association

    root_account = Account.find_by(id: association.root_account_id)
    root_account.feature_enabled?(:disable_file_verifiers_in_public_syllabus) &&
      association.context&.grants_right?(user, session, right_to_check)
  end

  def set_root_account_id
    self.root_account_id ||=
      if context_type == "ConversationMessage" || context.nil?
        # conversation messages can have multiple root account IDs, so we
        # don't bother dealing with them here
        attachment&.root_account_id
      else
        context.root_account_id
      end
  end

  def set_word_count
    if context_type == "Submission" && saved_change_to_attachment_id?
      attachment&.set_word_count
    end
  end
end
