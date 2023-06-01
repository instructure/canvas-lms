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

module Mutable
  def mute!
    return if muted?

    update_attribute(:muted, true)
    clear_sent_messages
    hide_submissions if respond_to?(:hide_submissions)
    ensure_post_policy(post_manually: true) if respond_to?(:ensure_post_policy)
    true
  end

  def unmute!
    return unless muted?

    update_attribute(:muted, false)
    post_submissions if respond_to?(:post_submissions)
    ensure_post_policy(post_manually: false) if respond_to?(:ensure_post_policy)
    true
  end

  protected

  def clear_sent_messages
    clear_broadcast_messages if respond_to? :clear_broadcast_messages
  end

  def hide_stream_items(submissions:)
    if submissions.present?
      submission_ids = submissions.pluck(:id)
      stream_items = StreamItem.select(%i[id context_type context_id])
                               .where(asset_type: "Submission", asset_id: submission_ids)
                               .preload(:context).to_a
      stream_item_contexts = stream_items.map { |si| [si.context_type, si.context_id] }
      user_ids = submissions.map(&:user_id).uniq # hide stream items for submission owners, not instructors
      # note: unfortunately this will hide items for an instructor if instructor (somehow) has a submission too

      Shard.partition_by_shard(user_ids) do |user_ids_subset|
        StreamItemInstance.where(stream_item_id: stream_items, user_id: user_ids_subset)
                          .update_all_with_invalidation(stream_item_contexts, hidden: true)
      end

      # Teachers want to hide their submission comments if they mute
      # the assignment after leaving them.
      instructor_ids = context.instructors.pluck(:id)
      visible_comment_sub_ids =
        SubmissionComment.where(hidden: false, submission_id: submission_ids, author_id: instructor_ids)
                         .pluck(:submission_id)
      update_submission_comments_and_count(visible_comment_sub_ids, hidden: true, instructor_ids:) if visible_comment_sub_ids.any?
    end
  end

  def show_stream_items(submissions:)
    if submissions.present?
      submission_ids = submissions.pluck(:id)
      stream_items = StreamItem.select(%i[id context_type context_id])
                               .where(asset_type: "Submission", asset_id: submission_ids)
                               .preload(:context).to_a
      stream_item_contexts = stream_items.map { |si| [si.context_type, si.context_id] }
      associated_shards = stream_items.inject([]) { |result, si| result | si.associated_shards }
      Shard.with_each_shard(associated_shards) do
        StreamItemInstance.where(hidden: true, stream_item_id: stream_items)
                          .update_all_with_invalidation(stream_item_contexts, hidden: false)
      end

      hidden_comment_sub_ids = SubmissionComment.where(hidden: true, submission_id: submission_ids).pluck(:submission_id)
      update_submission_comments_and_count(hidden_comment_sub_ids, hidden: false) if hidden_comment_sub_ids.any?
    end
  end

  def update_submission_comments_and_count(submission_ids, hidden: false, instructor_ids: nil)
    update_time = Time.zone.now
    submission_ids.each_slice(100) do |submission_id_slice|
      submission_comment_scope = SubmissionComment.where(hidden: !hidden, submission_id: submission_id_slice)
      submission_comment_scope = submission_comment_scope.where(author_id: instructor_ids) if instructor_ids.present?
      submission_comment_scope.update_all(hidden:, updated_at: update_time)

      Submission.where(id: submission_id_slice)
                .update_all(["submission_comments_count = (SELECT COUNT(*) FROM #{SubmissionComment.quoted_table_name} WHERE
            submissions.id = submission_comments.submission_id AND submission_comments.hidden = ? AND
            submission_comments.draft IS NOT TRUE AND submission_comments.provisional_grade_id IS NULL)",
                             false])
    end
  end

  private

  def update_muted_status!
    # With post policies active, an assignment is considered "muted" if it has any
    # unposted submissions.
    has_unposted_submissions = submissions.active.unposted.exists?

    if muted? != has_unposted_submissions
      # Set grade_posting_in_progress so we don't attempt to save changes to
      # this assignment's associated quiz/discussion topic/whatever in the
      # process of muting
      self.grade_posting_in_progress = true
      update!(muted: has_unposted_submissions)
      self.grade_posting_in_progress = false
    end
  end
end
