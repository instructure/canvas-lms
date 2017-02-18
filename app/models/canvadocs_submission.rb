class CanvadocsSubmission < ActiveRecord::Base
  belongs_to :canvadoc
  belongs_to :crocodoc_document
  belongs_to :submission
end
