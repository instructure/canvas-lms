module SubmissionCommentsHelper
  def comment_author_name_for(comment)
    can_do(comment, @current_user, :read_author) ?
      comment.author_name : t("Anonymous User")
  end
end
