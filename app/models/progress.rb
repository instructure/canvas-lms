#
# Copyright (C) 2013 Instructure, Inc.
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
  include PolymorphicTypeOverride
  override_polymorphic_types context_type: {'QuizStatistics' => 'Quizzes::QuizStatistics'}

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['ContentMigration', 'Course', 'User',
    'Quizzes::QuizStatistics', 'Account', 'GroupCategory', 'ContentExport', 'Assignment', 'Attachment']
  belongs_to :user
  attr_accessible :context, :tag, :completion, :message

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :tag

  serialize :results

  include Workflow
  workflow do
    state :queued do
      event :start, :transitions_to => :running
      event :fail, :transitions_to => :failed
    end
    state :running do
      event(:complete, :transitions_to => :completed) { self.completion = 100 }
      event :fail, :transitions_to => :failed
    end
    state :completed
    state :failed
  end

  def reset!
    self.results = nil
    self.workflow_state = 'queued'
    self.completion = 0
    self.save!
  end

  def set_results(results)
    self.results = results
    self.save
  end

  def update_completion!(value)
    update_attribute(:completion, value)
  end

  def calculate_completion!(current_value, total)
    update_completion!(100.0 * current_value / total)
  end

  def pending?
    queued? || running?
  end

  # Tie this Progress model to a delayed job. Rather than `obj.send_later(:long_method)`, use:
  # `progress.process_job(obj, :long_method)`. This will transition from queued
  # => running when the job starts, from running => completed when the job
  # finishes, and from running => failed if the job fails.
  #
  # This progress object will get passed as the first argument to the method,
  # so that you can update the completion percentage on it as the job runs.
  def process_job(target, method, enqueue_args = {}, *method_args)
    enqueue_args = enqueue_args.reverse_merge(max_attempts: 1, priority: Delayed::LOW_PRIORITY)
    method_args = method_args.unshift(self) unless enqueue_args.delete(:preserve_method_args)
    work = Progress::Work.new(self, target, method, method_args)
    Delayed::Job.enqueue(work, enqueue_args)
  end

  # (private)
  class Work < Delayed::PerformableMethod
    def initialize(progress, *args)
      @progress = progress
      super(*args)
    end

    def perform
      @progress.start
      super.tap { @progress.complete }
    end

    def on_permanent_failure(error)
      error_report = ErrorReport.log_exception("Progress::Work", error)
      @progress.message = "Unexpected error, ID: #{error_report.id rescue "unknown"}"
      @progress.save
      @progress.fail
    end
  end
end
