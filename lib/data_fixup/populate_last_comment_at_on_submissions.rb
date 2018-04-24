module DataFixup::PopulateLastCommentAtOnSubmissions
  def self.run(start_at, end_at)
    Submission.find_ids_in_ranges(:start_at => start_at, :end_at => end_at) do |min_id, max_id|
      Submission.where(:id => min_id..max_id).
        update_all("last_comment_at =
         (SELECT MAX(submission_comments.created_at) FROM #{SubmissionComment.quoted_table_name}
          WHERE submission_comments.submission_id=submissions.id AND
          submission_comments.author_id <> submissions.user_id AND
          submission_comments.draft <> 't' AND
          submission_comments.provisional_grade_id IS NULL)")
    end
  end
end
