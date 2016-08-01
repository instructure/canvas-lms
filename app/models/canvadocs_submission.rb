class CanvadocsSubmission < ActiveRecord::Base
  strong_params

  belongs_to :canvadoc
  belongs_to :crocodoc_document
  belongs_to :submission
end
