module Messages::PeerReviewsHelper

  def reviewee_name(asset, reviewer)
    asset.can_read_assessment_user_name?(reviewer, nil) ? asset.asset.user.name : I18n.t(:anonymous_user, 'Anonymous User')
  end

  def submission_comment_author(submission_comment, user)
     submission_comment.can_read_author?(user, nil) ? (submission_comment.author_name || I18n.t(:someone, "Someone")) : I18n.t(:anonymous_user, 'Anonymous User')
  end

  def submission_comment_submittor(submission_comment, user)
    submission_comment.submission.can_read_submission_user_name?(user, nil) ? submission_comment.submission.user.short_name : I18n.t(:anonymous_user, 'Anonymous User')
  end

end