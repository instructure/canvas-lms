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
  belongs_to :submission
  belongs_to :attachment
  belongs_to :originality_report_attachment, class_name: "Attachment"
  validates :attachment, :submission, presence: true
  validates :workflow_state, inclusion: { in: ['scored', 'error', 'pending'] }
  validates :originality_score, inclusion: { in: 0..100, message: 'score must be between 0 and 100' }, allow_nil: true

  alias_attribute :file_id, :attachment_id
  alias_attribute :originality_report_file_id, :originality_report_attachment_id
  before_validation :infer_workflow_state

  def state
    Turnitin.state_from_similarity_score(originality_score)
  end

  def as_json(options = nil)
    super(options).tap do |h|
      h[:file_id] = h.delete :attachment_id
      h[:originality_report_file_id] = h.delete :originality_report_attachment_id
    end
  end

  private

  def infer_workflow_state
    return if self.workflow_state == 'error'
    self.workflow_state = self.originality_score.present? ? 'scored' : 'pending'
  end
end
