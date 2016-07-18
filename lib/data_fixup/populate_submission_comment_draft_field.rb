module DataFixup::PopulateSubmissionCommentDraftField
  def self.run
    relevant_comments = SubmissionComment.where(draft: nil)

    SubmissionComment.find_ids_in_ranges do |min_id, max_id|
      relevant_comments.where(:id => min_id..max_id).update_all(draft: false)
    end
  end
end