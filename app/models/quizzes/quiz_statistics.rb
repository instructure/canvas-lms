#
# Copyright (C) 2013 - present Instructure, Inc.
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

class Quizzes::QuizStatistics < ActiveRecord::Base
  DefaultMaxQuestions = 100
  DefaultMaxSubmissions = 1000

  self.table_name = :quiz_statistics

  belongs_to :quiz, class_name: 'Quizzes::Quiz'
  has_one :csv_attachment, :class_name => 'Attachment', :as => 'context',
    :dependent => :destroy
  has_one :progress, :as => 'context', :dependent => :destroy

  scope :report_type, lambda { |type| where(:report_type => type) }

  REPORTS = %w[student_analysis item_analysis].freeze

  validates_inclusion_of :report_type, :in => REPORTS

  after_initialize do
    self.includes_all_versions ||= false
    self.includes_sis_ids ||= false
  end

  # Test a given quiz if it's within the sanity limits for generating stats.
  # You should not generate stats for this quiz if this returns true.
  #
  # Defaults for the limits are set in the constants in this module, but you
  # can configure them via the Setting interface using the console, or by
  # directly modifying the setting records in the database (note that you will
  # still have to restart your Canvas instance for the settings to take effect.)
  def self.large_quiz?(quiz)
    (quiz.active_quiz_questions.size >
      Setting.get('quiz_statistics_max_questions', DefaultMaxQuestions).to_i) ||
    (quiz.quiz_submissions.size >
      Setting.get('quiz_statistics_max_submissions', DefaultMaxSubmissions).to_i)
  end

  def report
    report_klass = report_type.to_s.camelize
    @report ||= Quizzes::QuizStatistics.const_get(report_klass).new(self)
  end

  # Generates or returns the previously generated CSV version of this report.
  def generate_csv
    self.csv_attachment ||= begin
      attachment = build_csv_attachment(
        content_type: 'text/csv',
        filename: "quiz_#{report_type}_report.csv",
        display_name: t("%{quiz_title} %{quiz_type} %{report_type} Report", {
            quiz_title: quiz.title,
            quiz_type: quiz.readable_type,
            report_type: readable_type
          }) + ".csv")
      Attachments::Storage.store_for_attachment(attachment, StringIO.new(report.to_csv))
      attachment.save!
      attachment
    end
  end

  # Queues a job for generating the CSV version of this report unless a job has
  # already been queued, or the attachment had been generated previously.
  def generate_csv_in_background
    return if csv_attachment.present? || progress.present?

    build_progress

    progress.tag = self.class.name
    progress.completion = 0
    progress.workflow_state = 'queued'
    progress.save!

    progress.process_job(self, :__process_csv_job, {
      strand: csv_job_strand_id
    })
  end

  def __process_csv_job(progress)
    generate_csv
  end

  # Whether the CSV attachment is currently being generated, or is about to be.
  def generating_csv?
    progress.present? && progress.pending?
  end

  def csv_generation_abortable?
    progress.present? && (progress.queued? || csv_generation_failed?)
  end

  def csv_generation_failed?
    progress.present? && progress.failed?
  end

  def abort_csv_generation
    self.progress.destroy
    self.reload

    Delayed::Job.where({ strand: self.csv_job_strand_id }).destroy_all
  end

  def self.csv_job_tag
    'Quizzes::QuizStatistics#__process_csv_job'
  end

  def csv_job_strand_id
    Shard.birth.activate { "quiz_statistics_#{quiz_id}_#{self.id}" }
  end

  def update_progress(i, n)
    # the report generators will always attempt to update the progress as they
    # do their work, but we don't always track progress (e.g, non-async) so in
    # that case we just ignore the updates:
    return if progress.nil?

    # TODO: smarter updates?  maybe 10 updates isn't enough for quizzes with
    # hundreds of submissions
    increment = 10
    percent = (i.to_f / n * 100).round

    if (percent / increment) > (progress.completion / increment)
      progress.update_completion! percent
    end
  end

  def readable_type
    report.readable_type
  end

  set_policy do
    given do |user, session|
      quiz.grants_right?(user, session, :read_statistics) &&
        (!includes_sis_ids || quiz.context.grants_any_right?(user, session, :read_sis, :manage_sis))
    end
    can :read
  end
end
