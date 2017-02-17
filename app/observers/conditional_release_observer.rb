class ConditionalReleaseObserver < ActiveRecord::Observer
  observe :submission,
          :assignment

  def after_update(record)
    clear_caches_for record
  end

  def after_create(record)
    clear_caches_for record
  end

  def after_save(record)
  end

  def after_destroy(record)
    clear_caches_for record
  end

  private
  def clear_caches_for(record)
    case record
    when Submission
      ConditionalRelease::Service.clear_submissions_cache_for(record.student)
      ConditionalRelease::Service.clear_rules_cache_for(record.context, record.student)
    when Assignment
      ConditionalRelease::Service.clear_active_rules_cache(record.context)
      ConditionalRelease::Service.clear_applied_rules_cache(record.context)
    end
  end
end
