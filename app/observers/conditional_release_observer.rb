class ConditionalReleaseObserver < ActiveRecord::Observer
  observe :submission

  def after_update(submission)
    clear_caches_for submission
  end

  def after_create(submission)
    clear_caches_for submission
  end

  def after_save(submission)
  end

  def after_destroy(submission)
    clear_caches_for submission
  end

  private
  def clear_caches_for(submission)
    ConditionalRelease::Service.clear_submissions_cache_for(submission.student)
    ConditionalRelease::Service.clear_rules_cache_for(submission.context, submission.student)
  end
end
