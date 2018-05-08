#
# Copyright (C) 2018 - present Instructure, Inc.
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

module DataFixup::ReclaimInstfsAttachments
  # run this to import files that were uploaded into inst-fs back into the
  # attachment_fu backed canvas file store. to be used when accounts that had
  # inst-fs enabled and had files uploaded to inst-fs need to stop using
  # inst-fs for whatever reasons (note this is beyond just stopping new uploads
  # to inst-fs).
  def self.run(root_accounts)
    Shard.partition_by_shard(root_accounts) do |shard_root_accounts|
      instfs_attachments_for_root_accounts(shard_root_accounts).find_each do |attachment|
        reclaim_attachment(attachment)
      end
    end
  end

  def self.reclaim_attachment(attachment)
    # note: this downloads the whole attachment at once into a temp file.
    # unfortunately, this is unavoidable with how attachment_fu works
    attachment.uploaded_data = attachment.open
    attachment.instfs_uuid = nil
    unless attachment.save
      # continue with other attachments, but log this one for investigation
      Rails.logger.warn("failed to reclaim attachment #{attachment.global_id}: #{attachment.errors.inspect}")
    end
  end

  def self.instfs_attachments_for_root_accounts(root_accounts)
    # between all the subqueries below, we have all the enumerated context
    # types for an attachment from attachment.rb lines 51-59 except:
    #   * other attachments (recursive)
    #   * eportfolios
    #   * purgatory
    #   * users
    #   * specific instances of other context types (e.g. folders) that are
    #     connected to a user instead of to an account or course
    #
    # we have to punt on those because either:
    #   * unfolding the recursion would be prohibitive. there aren't many of
    #     these anyways
    #   * for the others, there's no way to connect the attachment to a
    #     specific account
    #
    # for the remainder, the attachment contexts we do want, we expect the
    # attachment and every intermediary relationship to exist on the same shard
    # as the account, so we don't need to worry about spreading the queries
    # across shards
    #
    # associations associated with the accounts through courses
    course_queries = [
      Attachment.joins(:course),
      Attachment.joins(assessment_question: {assessment_question_bank: :course}),
      Attachment.joins(assignment: :course),
      Attachment.joins(content_export: :course),
      Attachment.joins(content_migration: :course),
      Attachment.joins(epub_export: :course),
      Attachment.joins(gradebook_upload: :course),
      Attachment.joins(submission: {assignment: :course}),
      Attachment.joins(context_folder: :course),
      Attachment.joins(context_outcome_import: :course),
      Attachment.joins(quiz: :course),
      Attachment.joins(quiz_statistics: {quiz: :course}),
      Attachment.joins(quiz_submission: {quiz: :course}),
    ].map{ |scope| scope.where(courses: {root_account_id: root_accounts}) }

    group_queries = [
      Attachment.joins(:group),
      Attachment.joins(content_export: :group),
      Attachment.joins(content_migration: :group),
      Attachment.joins(context_folder: :group),
    ].map{ |scope| scope.where(groups: {root_account_id: root_accounts}) }

    # attachments associated with the accounts outside of courses
    root_account_ids = root_accounts.map(&:id)
    account_queries = [
      Attachment.joins(:account),
      Attachment.joins(assessment_question: {assessment_question_bank: :account}),
      Attachment.joins(content_migration: :account),
      Attachment.joins(context_folder: :account),
      Attachment.joins(context_sis_batch: :account),
      Attachment.joins(context_outcome_import: :account),
    ].map{ |scope| scope.where("COALESCE(root_account_id, accounts.id) IN (?)", root_account_ids) }

    (course_queries + group_queries + account_queries).
      map{ |q| q.where("instfs_uuid IS NOT NULL") }.
      reduce{ |q1, q2| q1.union(q2) }
  end
end
