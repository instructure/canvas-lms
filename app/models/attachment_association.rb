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
  self.ignored_columns += %w[field_name]

  belongs_to :attachment
  belongs_to :context, polymorphic: [
    :account,
    :account_notification,
    :assignment,
    :calendar_event,
    :course,
    :conversation_message,
    :discussion_entry,
    :discussion_topic,
    :group,
    :learning_outcome,
    :learning_outcome_group,
    :submission,
    :wiki_page,
    {
      quiz: "Quizzes::Quiz",
    }
  ]
  belongs_to :user
  belongs_to :root_account, class_name: "Account", optional: true, inverse_of: :attachment_associations

  validates :context_concern, inclusion: { in: [
    nil, # default for all
    "syllabus_body", # for Course
    "terms_of_use", # for Account
  ] }

  before_create :set_root_account_id

  after_save :set_word_count

  # NB: context_concern is a virtual subdivision of context.
  # It is on purpose not a field name as it more denotes a sub-concern of
  # the context model, not necessarily an exact field.
  # Example: "terms_of_use" with an Account context denotes the custom
  # "terms of use" HTML, which should be treated as a publicly viewable
  # property of accounts, even for anonymous users, therefore any and all
  # attachments to it should also be viewable without restrictions.
  def self.update_associations(context, attachment_ids, user, session, context_concern = nil, blank_user: false)
    global_ids = attachment_ids.map { |id| Shard.global_id_for(id) }
    currently_has = AttachmentAssociation.where(context:, context_concern:).pluck(:attachment_id).map { |id| Shard.global_id_for(id) }

    to_delete = currently_has - global_ids
    to_create = global_ids - currently_has

    if to_delete.any?
      context.attachment_associations.where(context_concern:, attachment_id: to_delete).in_batches(of: 1000).destroy_all
    end

    if to_create.any?
      to_create.each_slice(1000) do |att_ids|
        all_attachment_associations = []

        Attachment.where(id: att_ids).find_each do |attachment|
          next if !(user.nil? && blank_user) && !attachment.grants_right?(user, session, :update)

          context.shard.activate do
            att_shard = Shard.shard_for(attachment.id)
            user_shard = user && Shard.shard_for(user.id)
            all_attachment_associations << {
              context_type: context.class.name,
              context_id: context.id,
              attachment_id: Shard.relative_id_for(attachment.id, att_shard, Shard.current),
              user_id: user && Shard.relative_id_for(user.id, user_shard, Shard.current),
              context_concern:,
              root_account_id: context.root_account_id,
            }
          end
        end
        context.shard.activate do
          insert_all(all_attachment_associations)
        end
      end
    end
  end

  def self.verify_access(location_param, attachment, user, session = nil)
    splat = location_param.split("_")
    return false unless splat.length >= 2

    context_id = splat.pop
    context_type = splat.join("_").camelize
    context_concern = nil
    right_to_check = :read

    if context_type == "CourseSyllabus"
      context_concern = "syllabus_body"
      context_type = "Course"
      right_to_check = :read_syllabus
    end

    association = Shard.shard_for(context_id).activate do
      AttachmentAssociation.find_by(attachment:, context_id:, context_type:, context_concern:)
    end

    return false unless association

    feature_is_on = if association.context.is_a?(Course) && context_concern == "syllabus_body"
                      association.context.root_account.feature_enabled?(:disable_file_verifiers_in_public_syllabus)
                    elsif association.context.respond_to?(:root_account)
                      association.context.root_account.feature_enabled?(:file_association_access)
                    elsif association.context.is_a?(ConversationMessage)
                      association.context.root_account_feature_enabled?(:file_association_access)
                    end

    feature_is_on && association.context&.grants_right?(user, session, right_to_check)
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
