# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module DifferentiableAssignment
  def differentiated_assignments_applies?
    !differentiable.visible_to_everyone
  end

  def visible_to_user?(user)
    return true unless differentiated_assignments_applies?

    is_visible = false
    Shard.with_each_shard(user.associated_shards) do
      visible_instances = DifferentiableAssignment.filter([differentiable], user, context) do |_, user_ids|
        conditions = { user_id: user_ids }
        conditions[column_name] = differentiable.id
        if Account.site_admin.feature_enabled?(:selective_release_backend)
          visible(conditions)
        else
          visibility_view.where(conditions)
        end
      end
      is_visible = true if visible_instances.any?
    end
    is_visible
  end

  def differentiable
    if (is_a?(WikiPage) || is_a?(DiscussionTopic)) && assignment.present?
      assignment
    else
      self
    end
  end

  def visibility_view
    case differentiable.class_name
    when "Assignment"
      AssignmentStudentVisibility
    when "ContextModule"
      ModuleStudentVisibility
    when "WikiPage"
      WikiPageStudentVisibility
    when "DiscussionTopic"
      UngradedDiscussionStudentVisibility
    else
      Quizzes::QuizStudentVisibility
    end
  end

  def visible(conditions)
    case differentiable.class_name
    when "Assignment"
      AssignmentVisibility::AssignmentVisibilityService.assignment_visible_to_students(user_ids: conditions[:user_id], assignment_id: conditions[:assignment_id])
    when "ContextModule"
      ModuleVisibility::ModuleVisibilityService.module_visible_to_students(user_ids: conditions[:user_id], context_module_id: conditions[:context_module_id])
    when "WikiPage"
      WikiPageVisibility::WikiPageVisibilityService.wiki_page_visible_to_students(user_ids: conditions[:user_id], wiki_page_id: conditions[:wiki_page_id])
    when "DiscussionTopic"
      UngradedDiscussionVisibility::UngradedDiscussionVisibilityService.discussion_topic_visible_to_students(user_ids: conditions[:user_id], discussion_topic_id: conditions[:discussion_topic_id])
    else
      QuizVisibility::QuizVisibilityService.quiz_visible_to_students(quiz_id: conditions[:quiz_id], user_ids: conditions[:user_id])
    end
  end

  def column_name
    case differentiable.class_name
    when "Assignment"
      :assignment_id
    when "ContextModule"
      :context_module_id
    when "WikiPage"
      :wiki_page_id
    when "DiscussionTopic"
      :discussion_topic_id
    else
      :quiz_id
    end
  end

  # will not filter the collection for teachers, will for non-observer students
  # will filter for observers with observed students but not for observers without observed students
  def self.filter(collection, user, context, opts = {})
    return collection if teacher_or_public_user?(user, context, opts)

    return yield(collection, [user.id]) if user_not_observer?(user, context, opts)

    # observer following no students -> dont filter
    # observer following students -> filter based on own enrollments and observee enrollments
    observed_student_ids = opts[:observed_student_ids] || ObserverEnrollment.observed_student_ids(context, user)
    user_ids = [user.id].concat(observed_student_ids)

    observed_student_ids.any? ? yield(collection, user_ids) : collection
  end

  # can filter scope of Assignments, DiscussionTopics, Quizzes, or ContentTags
  def self.scope_filter(scope, user, context, opts = {})
    context.shard.activate do
      filter(scope, user, context, opts) do |filtered_scope, user_ids|
        filtered_scope.visible_to_students_in_course_with_da(user_ids, [context.id])
      end
    end
  end

  # private
  def self.teacher_or_public_user?(user, context, opts)
    return true if opts[:is_teacher] == true

    RequestCache.cache("teacher_or_public_user", user, context) do
      Rails.cache.fetch([context, user, "teacher_or_public_user"].cache_key) do
        if context.includes_user?(user)
          permissions_implying_visibility = [:read_as_admin, :manage_grades, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS]
          permissions_implying_visibility << [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS] if context.is_a?(Course)
          context.grants_any_right?(user, *permissions_implying_visibility)
        else
          true
        end
      end
    end
  end

  # private
  def self.user_not_observer?(user, context, opts)
    return true if opts[:ignore_observer_logic] || context.is_a?(Group)

    !context.user_has_been_observer?(user)
  end
end
