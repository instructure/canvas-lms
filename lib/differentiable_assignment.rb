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
    if self.is_a?(Assignment) || Quizzes::Quiz.class_names.include?(self.class_name)
      self.only_visible_to_overrides
    elsif self.assignment
      self.assignment.only_visible_to_overrides
    else
      false
    end
  end

  def visible_to_user?(user, opts={})
    # slightly redundant conditional, but avoiding unnecessary lookups
    return true if opts[:differentiated_assignments] == false ||
                  (opts[:differentiated_assignments] == true && !self.only_visible_to_overrides) ||
                  !self.differentiated_assignments_applies? #checks if DA enabled on course and then only_visible_to_overrides

    # will add users if observer and only filter based on DA when necessary (not for teachers/some observers)
    visible_instances = DifferentiableAssignment.filter([self], user, self.context) do |_, user_ids|
      conditions = {user_id: user_ids}
      conditions[column_name] = self.id
      visibility_view.where(conditions)
    end
    visible_instances.any?
  end

  def visibility_view
    self.is_a?(Assignment) ? AssignmentStudentVisibility : Quizzes::QuizStudentVisibility
  end

  def column_name
    self.is_a?(Assignment) ? :assignment_id : :quiz_id
  end

  # will not filter the collection for teachers, will for non-observer students
  # will filter for observers with observed students but not for observers without observed students
  def self.filter(collection, user, context, opts={}, &filter_block)
    return collection if teacher_or_public_user?(user, context, opts)

    return filter_block.call(collection, [user.id]) if user_not_observer?(user, context, opts)

    # observer following no students -> dont filter
    # observer following students -> filter based on own enrollments and observee enrollments
    observed_student_ids = opts[:observed_student_ids] || ObserverEnrollment.observed_student_ids(context, user)
    user_ids = [user.id].concat(observed_student_ids)

    observed_student_ids.any? ? filter_block.call(collection, user_ids) : collection
  end

  # can filter scope of Assignments, DiscussionTopics, Quizzes, or ContentTags
  def self.scope_filter(scope, user, context, opts={})
    context.shard.activate do
      self.filter(scope, user, context, opts) do |scope, user_ids|
        scope.visible_to_students_in_course_with_da(user_ids, context.id)
      end
    end
  end

  # private
  def self.teacher_or_public_user?(user, context, opts)
    return true if opts[:is_teacher] == true
    RequestCache.cache('teacher_or_public_user', user, context) do
      Rails.cache.fetch([context, user, 'teacher_or_public_user'].cache_key) do
        if !context.includes_user?(user)
          true
        else
          permissions_implying_visibility = [:read_as_admin, :manage_grades, :manage_assignments]
          permissions_implying_visibility << :manage_content if context.is_a?(Course)
          context.grants_any_right?(user, *permissions_implying_visibility)
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
