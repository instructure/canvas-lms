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
  belongs_to :attachment
  belongs_to :context, polymorphic: [
    :account,
    :account_notification,
    :assessment_question,
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
      quiz_question: "Quizzes::QuizQuestion",
      quiz_submission: "Quizzes::QuizSubmission"
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

  def self.verify_access(location_param, attachment, user, session = nil)
    return false if attachment.locked_for?(user)

    context_type, _, context_id = location_param.rpartition("_")
    return false unless context_type && context_id

    context_type = context_type.camelize
    context_id = Shard.integral_id_for(context_id)
    context_concern = nil
    permission_context = nil

    if context_type == "CourseSyllabus"
      context_concern = "syllabus_body"
      context_type = "Course"
    elsif context_type == "Quiz"
      context_type = "Quizzes::Quiz"
    elsif context_type == "QuizQuestion"
      context_type = "Quizzes::QuizQuestion"
    elsif context_type == "QuizSubmission"
      context_type = "Quizzes::QuizSubmission"
      submission = Quizzes::QuizSubmission.find_by(id: context_id)
      return false unless submission&.quiz_data.present?

      if (attachment.context_type == "Quizzes::QuizSubmission" && context_id == attachment.context_id) ||
         (attachment.context_type == "AssessmentQuestion" && submission.quiz_data.pluck("assessment_question_id").include?(attachment.context_id))
        permission_context = submission
      end
    elsif context_type == "AssessmentQuestion"
      return false unless attachment.context_type == "AssessmentQuestion" && context_id == attachment.context_id

      permission_context = AssessmentQuestion.find_by(id: context_id)
    end

    unless permission_context
      association = Shard.shard_for(context_id).activate do
        AttachmentAssociation.find_by(attachment:, context_id:, context_type:, context_concern:)
      end

      permission_context = if association&.context.is_a?(Quizzes::QuizQuestion)
                             association.context.quiz
                           else
                             association&.context
                           end
    end
    return false unless permission_context

    permission_context.attachment_associations_enabled? && permission_context.access_for_attachment_association?(user, session, association)
  end

  def self.copy_associations(source, targets, source_context_concern = nil, target_context_concern = nil)
    return if source.nil? || targets.nil?

    targets = Array(targets)
    raise "Targets must be of same class" unless targets.all?(targets.first.class)

    return if targets.empty?

    AttachmentAssociation.where(context_type: targets.first.class.name, context_id: targets.pluck(:id), context_concern: target_context_concern).delete_all

    to_create = []
    AttachmentAssociation.where(context: source, context_concern: source_context_concern).find_each do |assoc|
      targets.each do |target|
        to_create << {
          context_type: target.class.name,
          context_id: target.id,
          attachment_id: assoc.attachment_id,
          user_id: assoc.user_id,
          context_concern: target_context_concern,
          root_account_id: target.root_account_id
        }
      end
    end

    AttachmentAssociation.insert_all(to_create, returning: false) if to_create.any?
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
