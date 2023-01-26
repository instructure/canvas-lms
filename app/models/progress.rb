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

class Progress < ActiveRecord::Base
  belongs_to :context, polymorphic:
      [:content_migration, :course, :account, :group_category, :content_export,
       :assignment, :attachment, :epub_export, :sis_batch, :course_pace,
       { context_user: "User", quiz_statistics: "Quizzes::QuizStatistics" }]
  belongs_to :user
  belongs_to :delayed_job, class_name: "::Delayed::Job", optional: true

  validates :context_id, presence: true
  validates :context_type, presence: true
  validates :tag, presence: true

  serialize :results
  attr_reader :total

  include Workflow
  workflow do
    state :queued do
      event :start, transitions_to: :running
      event :fail, transitions_to: :failed
    end
    state :running do
      event(:complete, transitions_to: :completed) { self.completion = 100 }
      event :fail, transitions_to: :failed
    end
    state :completed
    state :failed
  end

  set_policy do
    given { |user| self.user.present? && self.user == user }
    can :cancel
  end

  def reset!
    self.results = nil
    self.workflow_state = "queued"
    self.completion = 0
    GuardRail.activate(:primary) { save! }
  end

  def set_results(results)
    self.results = results
    save
  end

  def update_completion!(value)
    update_attribute(:completion, value)
  end

  def calculate_completion!(current_value, total)
    @total = total
    @current_value = current_value
    update_completion!(100.0 * @current_value / @total)
  end

  def increment_completion!(increment = 1)
    raise "`increment_completion!` can only be invoked after a total has been set with `calculate_completion!`" if @total.nil?

    @current_value += increment
    new_value = 100.0 * @current_value / @total
    # only update the db if we're at a different integral percentage point or it's been > 15s
    if new_value.to_i != completion.to_i || (Time.now.utc - updated_at) > 15
      update_completion!(new_value)
    else
      self.completion = new_value
    end
  end

  def pending?
    queued? || running?
  end

  # Tie this Progress model to a delayed job. Rather than `obj.delay.long_method`, use:
  # `progress.process_job(obj, :long_method)`. This will transition from queued
  # => running when the job starts, from running => completed when the job
  # finishes, and from running => failed if the job fails.
  #
  # This progress object will get passed as the first argument to the method,
  # so that you can update the completion percentage on it as the job runs.
  def process_job(target, method, enqueue_args, *method_args, **kwargs)
    enqueue_args = enqueue_args.reverse_merge(max_attempts: 1, priority: Delayed::LOW_PRIORITY)
    method_args.unshift(self) unless enqueue_args.delete(:preserve_method_args)
    work = Progress::Work.new(self, target, method, args: method_args, kwargs: kwargs)
    GuardRail.activate(:primary) do
      ActiveRecord::Base.connection.after_transaction_commit do
        job = Delayed::Job.enqueue(work, **enqueue_args)
        update(delayed_job_id: job.id)
        job
      end
    end
  end

  # (private)
  class Work < Delayed::PerformableMethod
    def initialize(progress, *args, **kwargs)
      @progress = progress
      super(*args, **kwargs)
    end

    def perform
      args[0] = @progress if args[0] == @progress # maintain the same object reference
      @progress.start
      super
      @progress.reload
      @progress.complete if @progress.running?
    end

    def on_permanent_failure(error)
      er_id = @progress.shard.activate do
        Canvas::Errors.capture_exception("Progress::Work", error)[:error_report]
      end
      @progress.message = "Unexpected error, ID: #{er_id || "unknown"}"
      @progress.save
      @progress.fail
      @context.fail_with_error!(error) if @context.respond_to?(:fail_with_error!)
    end
  end
end
