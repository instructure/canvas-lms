# frozen_string_literal: true

#
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

class ScheduledPost < ActiveRecord::Base
  belongs_to :assignment, inverse_of: :scheduled_post, class_name: "AbstractAssignment"
  belongs_to :post_policy, inverse_of: :scheduled_post

  validates :assignment, presence: true, uniqueness: true
  validates :post_policy, presence: true, uniqueness: true
  validates :root_account_id, presence: true
  validates :post_comments_at, presence: true
  validates :post_grades_at, presence: true
  validate :post_grades_at_not_before_post_comments_at

  before_save :reset_ran_at_timestamps
  after_save :enqueue_immediate_processing

  scope :pending_comments_posting, ->(time) { where(post_comments_ran_at: nil, post_comments_at: ..time) }
  scope :pending_grades_posting, ->(time) { where(post_grades_ran_at: nil, post_grades_at: ..time) }

  def reset_ran_at_timestamps
    return if new_record?

    self.post_comments_ran_at = nil if will_save_change_to_post_comments_at?
    self.post_grades_ran_at = nil if will_save_change_to_post_grades_at?
  end

  def enqueue_immediate_processing
    thirty_minutes_from_now = 30.minutes.from_now

    # For new records, check if timestamps are immediate
    # For updates, check if timestamps were changed and are immediate
    if saved_change_to_id?
      comments_immediate = post_comments_at <= thirty_minutes_from_now
      grades_immediate = post_grades_at <= thirty_minutes_from_now
    else
      comments_immediate = saved_change_to_post_comments_at? && post_comments_at <= thirty_minutes_from_now
      grades_immediate = saved_change_to_post_grades_at? && post_grades_at <= thirty_minutes_from_now
    end

    return unless comments_immediate || grades_immediate

    self.class.delay.process_scheduled_posts(ids: [id])
  end

  def post_grades_at_not_before_post_comments_at
    return if post_grades_at.nil? || post_comments_at.nil?

    if post_grades_at < post_comments_at
      errors.add(:post_grades_at, "must be the same as or after post_comments_at")
    end
  end

  def should_post_comments_and_grades?
    post_comments_at.to_i == post_grades_at.to_i
  end

  def should_post_grades?(max_run_time)
    post_grades_at <= max_run_time && post_grades_ran_at.nil?
  end

  def should_post_comments?(max_run_time)
    post_comments_at <= max_run_time && post_comments_ran_at.nil?
  end

  def self.process_scheduled_posts(ids: nil)
    forty_minutes_from_now = 40.minutes.from_now
    run_time = Time.current

    scheduled_posts_to_process = pending_comments_posting(forty_minutes_from_now).or(pending_grades_posting(forty_minutes_from_now))
    scheduled_posts_to_process = scheduled_posts_to_process.where(id: ids) if ids.present?

    scheduled_posts_to_process
      .preload(
        :post_policy,
        assignment: :context
      ).find_each do |scheduled_post|
      post_policy = scheduled_post.post_policy
      assignment = scheduled_post.assignment
      course = assignment.context

      # If post_manually is false, skip processing this scheduled post
      unless post_policy&.post_manually
        scheduled_post.update(post_grades_ran_at: run_time, post_comments_ran_at: run_time)
        raise "PostPolicy is missing or does not respond to post_manually" if post_policy.nil? || !post_policy.respond_to?(:post_manually)
      end

      if scheduled_post.should_post_comments_and_grades?
        # If both are set to the same time, then call process_assignment_posting only
        progress = course.progresses.new(tag: "scheduled_post_assignment_grades_and_comments:#{assignment.id}")
        process_assignment_posting(assignment:, progress:, run_at: scheduled_post.post_grades_at)
        scheduled_post.update(post_grades_ran_at: run_time, post_comments_ran_at: run_time)
        next
      end

      if scheduled_post.should_post_grades?(forty_minutes_from_now)
        progress = course.progresses.new(tag: "scheduled_post_assignment_grades:#{assignment.id}")
        process_assignment_posting(assignment:, progress:, run_at: scheduled_post.post_grades_at)
        scheduled_post.update(post_grades_ran_at: run_time)
      end

      next unless scheduled_post.should_post_comments?(forty_minutes_from_now)

      progress = course.progresses.new(tag: "scheduled_post_assignment_comments:#{assignment.id}")
      process_comments_posting(assignment:, progress:, run_at: scheduled_post.post_comments_at)
      scheduled_post.update(post_comments_ran_at: run_time)
    rescue => e
      Canvas::Errors.capture_exception(:scheduled_post, e, :info)
    end
  end

  class << self
    private

    def process_assignment_posting(assignment:, progress:, run_at:)
      progress.save!
      progress.process_job(
        assignment,
        :post_scheduled_submissions,
        {
          preserve_method_args: true,
          run_at:,
          on_conflict: :overwrite,
          priority: Delayed::HIGH_PRIORITY,
          n_strand: ["Assignment#post_scheduled_grades", assignment.context.global_id],
          singleton: "scheduled_post_assignment_grades:#{assignment.global_id}"
        },
        run_at:,
        progress:,
        skip_content_participation_refresh: false
      )
    end

    def process_comments_posting(assignment:, progress:, run_at:)
      progress.save!
      progress.process_job(
        assignment,
        :post_scheduled_comments,
        {
          preserve_method_args: true,
          run_at:,
          on_conflict: :overwrite,
          priority: Delayed::HIGH_PRIORITY,
          n_strand: ["Assignment#post_scheduled_comments", assignment.context.global_id],
          singleton: "scheduled_post_assignment_comments:#{assignment.global_id}"
        },
        run_at:,
        progress:
      )
    end
  end
end
