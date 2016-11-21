class OriginalityReport < ActiveRecord::Base
  strong_params
  belongs_to :attachment
  belongs_to :originality_report_attachment, class_name: "Attachment"
  validates :originality_score, :attachment, presence: true
end