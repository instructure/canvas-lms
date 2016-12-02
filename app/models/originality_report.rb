class OriginalityReport < ActiveRecord::Base
  strong_params
  belongs_to :submission
  belongs_to :attachment
  belongs_to :originality_report_attachment, class_name: "Attachment"
  validates :originality_score, :attachment, :submission, presence: true
  validates :originality_score, inclusion: { in: 0..100, message: 'score must be between 0 and 100' }
  validates :workflow_state, inclusion: { in: ['scored', 'error', 'pending'] }

  alias_attribute :file_id, :attachment_id
  alias_attribute :originality_report_file_id, :originality_report_attachment_id
  before_validation { self.workflow_state ||= 'pending' }

  def state
    Turnitin.state_from_similarity_score(originality_score)
  end

  def as_json(options = nil)
    super(options).tap do |h|
      h[:file_id] = h.delete :attachment_id
      h[:originality_report_file_id] = h.delete :originality_report_attachment_id
    end
  end
end
