class DiscussionTopic::ScopedToUser < ScopeFilter
  def scope
    concat_scope do
      if context.feature_enabled?(:differentiated_assignments)
        scope_for_differentiated_assignments(@relation)
      end
    end
  end

  private
  def scope_for_differentiated_assignments(scope)
    return scope if context.is_a?(Account)
    return DifferentiableAssignment.scope_filter(scope, user, context) if context.is_a?(Course)
    return scope if context.context.is_a?(Account)

    # group context owned by a course
    course = context.context
    course_scope = course.discussion_topics.active
    course_level_topic_ids = DifferentiableAssignment.scope_filter(course_scope, user, course).pluck(:id)
    if course_level_topic_ids.any?
      scope.where("discussion_topics.root_topic_id IN (?) OR discussion_topics.root_topic_id IS NULL OR discussion_topics.id IN (?)", course_level_topic_ids, course_level_topic_ids)
    else
      scope.where(root_topic_id: nil)
    end
  end
end

