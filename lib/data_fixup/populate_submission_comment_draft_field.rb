module DataFixup::PopulateSubmissionCommentDraftField
  def self.run
    relevant_comments = SubmissionComment.where(draft: nil)

    while relevant_comments.limit(1000).update_all(draft: false) > 0; end
  end
end