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

  belongs_to :submission
  belongs_to :attachment
  belongs_to :originality_report_attachment, class_name: "Attachment"

  has_one :lti_link, class_name: 'Lti::Link', as: :linkable, inverse_of: :linkable, dependent: :destroy
  accepts_nested_attributes_for :lti_link, allow_destroy: true

  validates :submission, presence: true
  validates :workflow_state, inclusion: { in: ['scored', 'error', 'pending'] }
  validates :originality_score, inclusion: { in: 0..100, message: 'score must be between 0 and 100' }, allow_nil: true

  alias_attribute :file_id, :attachment_id
  alias_attribute :originality_report_file_id, :originality_report_attachment_id
  before_validation :infer_workflow_state

  def state
    if workflow_state != 'scored'
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
                             resource_type_code:lti_link.resource_type_code }
      end
    end
  end

  def report_launch_path
    if lti_link.present?
      course_assignment_resource_link_id_path(course_id: assignment.context_id,
                                             assignment_id: assignment.id,
                                             resource_link_id: lti_link.resource_link_id,
                                             host: HostUrl.context_host(assignment.context),
                                             display: 'borderless')
    else
      originality_report_url
    end
  end

  def asset_key
    return Attachment.asset_string(attachment_id) if attachment_id.present?
    Submission.asset_string(submission_id)
  end

  def copy_to_group_submissions!
    return if submission.group_id.blank?
    group_submissions = assignment.submissions.where.not(id: submission.id).where(group: submission.group)
    group_submissions.find_each do |s|
      copy_of_report = self.dup

      # We don't want a single submission to have
      # multiple originality reports with the same
      # attachment/submission combo hanging around.
      s.originality_reports.where(
        attachment_id: attachment_id
      ).destroy_all

      copy_of_report.update!(submission: s)
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

  def infer_workflow_state
    return if self.workflow_state == 'error'
    self.workflow_state = self.originality_score.present? ? 'scored' : 'pending'
  end
end
