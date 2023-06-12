# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class OriginalityReport < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  # Allowed workflow states, for ActiveRecord callbacks. In addition, this list is sorted from least
  # to most preferred state. This allows us to sort and determine what report we want to use if
  # multiple exist for a given submission and attachment combo.
  ORDERED_VALID_WORKFLOW_STATES = %w[pending error scored].freeze

  belongs_to :submission
  belongs_to :attachment
  belongs_to :originality_report_attachment, class_name: "Attachment"
  belongs_to :root_account, class_name: "Account"

  has_one :lti_link, class_name: "Lti::Link", as: :linkable, inverse_of: :linkable, dependent: :destroy
  accepts_nested_attributes_for :lti_link, allow_destroy: true

  validates :submission, presence: true
  validates :workflow_state, inclusion: { in: ORDERED_VALID_WORKFLOW_STATES }
  validates :originality_score, inclusion: { in: 0..100, message: -> { t("score must be between 0 and 100") } }, allow_nil: true

  alias_attribute :file_id, :attachment_id
  alias_attribute :originality_report_file_id, :originality_report_attachment_id
  before_validation :infer_workflow_state
  after_validation :set_submission_time
  before_save :set_root_account

  def self.submission_asset_key(submission)
    "#{submission.asset_string}_#{submission.submitted_at.utc.iso8601}"
  end

  def state
    if workflow_state != "scored"
      return workflow_state
    end

    Turnitin.state_from_similarity_score(originality_score)
  end

  def as_json(options = nil)
    super(options).tap do |h|
      h[:file_id] = h.delete :attachment_id
      h[:originality_report_file_id] = h.delete :originality_report_attachment_id
      if lti_link.present?
        h[:tool_setting] = { resource_url: lti_link.resource_url,
                             resource_type_code: lti_link.resource_type_code }
      end
    end
  end

  def report_launch_path
    if lti_link.present?
      course_assignment_resource_link_id_path(course_id: assignment.context_id,
                                              assignment_id: assignment.id,
                                              resource_link_id: lti_link.resource_link_id,
                                              host: HostUrl.context_host(assignment.context),
                                              display: "borderless")
    else
      originality_report_url
    end
  end

  def asset_key
    return Attachment.asset_string(attachment_id) if attachment_id.present?

    if submission_time.present?
      "#{Submission.asset_string(submission_id)}_#{submission_time&.utc&.iso8601}"
    else
      Submission.asset_string(submission_id)
    end
  end

  def self.copy_to_group_submissions!(report_id:, user_id:, updated_at: nil, submission_id: nil, attachment_id: nil)
    report = find(report_id)
    report.copy_to_group_submissions!
  rescue ActiveRecord::RecordNotFound => e
    user = User.where(id: user_id).first
    if user.nil? || user.fake_student?
      # Test students get reset frequently, which wipes out their originality
      # reports, so if we can't find a report but the user is also
      # gone or is known to be a fake_student, we can ignore this and not
      # continue with the job
      Canvas::Errors.capture(e, { report_id:, user_id: }, :info)
    elsif updated_at && where("updated_at > ?", updated_at)
          .where(submission_id:, attachment_id:).exists?
      # It is possible for the report to have been deleted by another job (of
      # the same group but different submission/student). In this case it would
      # have created another report, so if we find that, it's an expected
      # error.
      info = {
        report_id:,
        submission_id:,
        attachment_id:,
        updated_at:
      }
      Canvas::Errors.capture(e, info, :info)
    else
      raise e
    end
  end

  def copy_to_group_submissions_later!
    # Some providers may actually send a report for each student, but
    # historically at least some did not, so we need to copy.
    return if submission.group_id.blank?

    strand = "originality_report_copy_to_group_submissions:" \
             "#{submission.global_assignment_id}:#{submission.group_id}:#{attachment_id}"

    self.class.delay_if_production(strand:).copy_to_group_submissions!(
      report_id: id,
      user_id: submission.user_id,
      submission_id:,
      attachment_id:,
      updated_at:
    )
  end

  def copy_to_group_submissions!
    # This normally wouldn't have changed but check again anyway because
    # updating all submissions with no group id would be bad...
    return if submission.group_id.blank?

    group_submissions = assignment.submissions.where.not(id: submission.id).where(group: submission.group)

    group_submissions.find_each do |s|
      same_or_later_report_exists =
        s.originality_reports.where(attachment_id:)
         .where("updated_at >= ?", updated_at).exists?
      next if same_or_later_report_exists

      copy_of_report = dup
      copy_of_report.submission_time = nil

      # We don't want a single submission to have
      # multiple originality reports with the same
      # attachment/submission combo hanging around.
      s.originality_reports
       .where(attachment_id:)
       .where("updated_at < ?", updated_at)
       .destroy_all

      copy_of_report.update!(submission: s, updated_at:)
      lti_link&.dup&.update!(
        linkable: copy_of_report,
        resource_link_id: nil
      )
    end
  end

  private

  def assignment
    submission.assignment
  end

  def set_submission_time
    self.submission_time ||= submission.reload.submitted_at
  end

  def infer_workflow_state
    self.workflow_state = "error" if error_message.present?
    return if workflow_state == "error"

    self.workflow_state = originality_score.present? ? "scored" : "pending"
  end

  def set_root_account
    self.root_account_id ||= submission&.root_account_id
  end
end
