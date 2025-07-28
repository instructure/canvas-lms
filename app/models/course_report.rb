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
#

class CourseReport < ActiveRecord::Base
  include Workflow
  include CaptureJobIds

  belongs_to :course, inverse_of: :course_reports
  belongs_to :user, inverse_of: :course_reports
  belongs_to :attachment, inverse_of: :course_report
  belongs_to :root_account, class_name: "Account"
  has_one :progress, inverse_of: :context

  validates :course_id, :user_id, :workflow_state, presence: true

  serialize :parameters, type: Hash

  workflow do
    state :created
    state :running
    state :compiling
    state :complete
    state :error
    state :aborted
    state :deleted
  end

  scope :complete, -> { where(workflow_state: "complete") }
  scope :running, -> { where(workflow_state: "running") }
  scope :by_recency, -> { order(created_at: :desc) }
  scope :active, -> { where.not(workflow_state: "deleted") }

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end

  def context
    course
  end

  def in_progress?
    created? || running?
  end

  def run_report(progress)
    shard.activate do
      generate_report(progress)
    rescue => e
      mark_as_errored(progress, e)
    end
  end

  def mark_as_errored(progress, error = nil)
    Rails.logger.error("CourseReport failed with error: #{error}") if error

    self.workflow_state = :error
    save!
    progress.fail!
  end

  def generate_report(progress)
    progress.start
    capture_job_id
    update(workflow_state: "running", start_at: Time.zone.now)

    begin
      case report_type
      when "course_pace_docx"
        CoursePaceDocxGenerator.new(self, parameters[:section_ids], parameters[:enrollment_ids]).generate(progress)
      end
      update(workflow_state: "complete", end_at: Time.zone.now)
      progress.update_completion!(100)
    rescue => e
      update(workflow_state: "error", end_at: Time.zone.now, message: "Generating the report, #{report_type}, failed\n#{e.message}\n#{e.backtrace}")
      progress.fail
    end
  end

  set_policy do
    given do |user, _, _|
      self.user == user
    end
    can :read
  end
end
