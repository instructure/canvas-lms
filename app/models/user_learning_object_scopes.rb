#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

module UserLearningObjectScopes
  ULOS_DEFAULT_LIMIT = 15

  # This is a helper method for converting a method call's regular parameters
  # and named parameters into a hash. `opts` is considered to be a keyword that
  # contains the rest of the named parameters passed to the method. The `opts`
  # parameter is merged into the return value.
  #
  # This is useful for using the parameters as a cache key and for forwarding
  # named parameters to another method.
  def _params_hash(parent_binding)
    caller_method = method(caller_locations(1, 1).first.base_label)
    caller_param_names = caller_method.parameters.map(&:last)
    param_values = caller_param_names.each_with_object({}) { |v, h| h[v] = parent_binding.local_variable_get(v) }
    opts = param_values[:opts]
    param_values = param_values.except(:opts).merge(opts) if opts
    param_values
  end

  def ignore_item!(asset, purpose, permanent = false)
    begin
      # more likely this doesn't exist, so try the create first
      asset.ignores.create!(:user => self, :purpose => purpose, :permanent => permanent)
    rescue ActiveRecord::RecordNotUnique
      asset.shard.activate do
        ignore = asset.ignores.where(user_id: self, purpose: purpose).first
        ignore.permanent = permanent
        ignore.save!
      end
    end
    self.touch
  end

  def assignments_visible_in_course(course)
    return course.active_assignments if course.grants_any_right?(self, :read_as_admin,
                                                                       :manage_grades,
                                                                       :manage_assignments)
    published_visible_assignments = course.active_assignments.published
    published_visible_assignments = DifferentiableAssignment.scope_filter(published_visible_assignments,
                                                                          self, course, is_teacher: false)
    published_visible_assignments
  end

  def course_ids_for_todo_lists(participation_type, course_ids: nil, contexts: nil, include_concluded: false)
    shard.activate do
      course_ids_result = Shackles.activate(:slave) do
        if include_concluded
          all_course_ids
        else
          case participation_type
          when :student
            participating_student_course_ids
          when :instructor
            participating_instructor_course_ids
          end
        end
      end

      course_ids_result &= course_ids if course_ids
      course_ids_result &= Array.wrap(contexts).select{|c| c.is_a? Course}.map(&:id) if contexts
      course_ids_result
    end
  end

  def group_ids_for_todo_lists(group_ids: nil, contexts: nil)
    shard.activate do
      group_ids_result = cached_current_group_memberships.map(&:group_id)
      group_ids_result &= group_ids if group_ids
      group_ids_result &= contexts.select{|g| g.is_a? Group}.map(&:id) if contexts
      group_ids_result
    end
  end

  def objects_needing(
    object_type, purpose, participation_type, params_cache_key, expires_in,
    limit: ULOS_DEFAULT_LIMIT, scope_only: false,
    course_ids: nil, group_ids: nil, contexts: nil, include_concluded: false,
    include_ignored: false, include_ungraded: false
  )
    original_shard = Shard.current
    shard.activate do
      course_ids = course_ids_for_todo_lists(participation_type,
         course_ids: course_ids, contexts: contexts, include_concluded: include_concluded)
      group_ids = group_ids_for_todo_lists(group_ids: group_ids, contexts: contexts)
      ids_by_shard = Hash.new({course_ids: [], group_ids: []})
      Shard.partition_by_shard(course_ids) do |shard_course_ids|
        ids_by_shard[Shard.current] = { course_ids: shard_course_ids, group_ids: [] }
      end
      Shard.partition_by_shard(group_ids) do |shard_group_ids|
        shard_hash = ids_by_shard[Shard.current]
        shard_hash[:group_ids] = shard_group_ids
        ids_by_shard[Shard.current] = shard_hash
      end

      if scope_only
        original_shard.activate do
          # only provide scope on current shard
          shard_course_ids = ids_by_shard.dig(original_shard, :course_ids)
          shard_group_ids = ids_by_shard.dig(original_shard, :group_ids)
          if shard_course_ids.present? || shard_group_ids.present?
            return yield(*arguments_for_objects_needing(
              object_type, purpose, shard_course_ids, shard_group_ids, participation_type,
              include_ignored: include_ignored,
              include_ungraded: include_ungraded,
            ))
          end
          return object_type.constantize.none # fallback
        end
      else
        course_ids_cache_key = Digest::MD5.hexdigest(course_ids.sort.join('/'))
        cache_key = [self, "#{object_type}_needing_#{purpose}", course_ids_cache_key, params_cache_key].cache_key
        Rails.cache.fetch(cache_key, expires_in: expires_in) do
          result = Shackles.activate(:slave) do
            ids_by_shard.flat_map do |shard, shard_hash|
              shard.activate do
                yield(*arguments_for_objects_needing(
                  object_type, purpose, shard_hash[:course_ids], shard_hash[:group_ids], participation_type,
                  include_ignored: include_ignored,
                  include_ungraded: include_ungraded
                ))
              end
            end
          end
          result = result[0...limit] if limit # limit is sometimes passed in as nil explicitly
          result
        end
      end
    end
  end

  def arguments_for_objects_needing(
    object_type, purpose, shard_course_ids, shard_group_ids, participation_type,
    include_ignored: false,
    include_ungraded: false
  )
    scope = object_type.constantize
    scope = scope.not_ignored_by(self, purpose) unless include_ignored
    scope = scope.for_course(shard_course_ids) if ['Assignment', 'Quizzes::Quiz'].include?(object_type)
    if object_type == 'Assignment'
      scope = participation_type == :student ? scope.published : scope.active
      scope = scope.expecting_submission unless include_ungraded
    end
    [scope, shard_course_ids, shard_group_ids]
  end

  def assignments_for_student(
    purpose,
    limit: ULOS_DEFAULT_LIMIT,
    due_after: 2.weeks.ago,
    due_before: 2.weeks.from_now,
    cache_timeout: 120.minutes,
    include_locked: false,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    objects_needing('Assignment', purpose, :student, params, cache_timeout,
      limit: limit, **opts) do |assignment_scope|
      assignments = assignment_scope.due_between_for_user(due_after, due_before, self)
      assignments = assignments.need_submitting_info(id, limit) if purpose == 'submitting'
      assignments = assignments.submittable.or(assignments.where('assignments.due_at > ?', Time.zone.now)) if purpose == 'submitting'
      assignments = assignments.having_submissions_for_user(id) if purpose == 'submitted'
      assignments = assignments.not_locked unless include_locked
      assignments
    end
  end

  def assignments_needing_submitting(
    due_after: 4.weeks.ago,
    due_before: 1.week.from_now,
    scope_only: false,
    include_concluded: false,
    **opts # forward args to assignments_for_student
  )
    opts[:cache_timeout] = 15.minutes
    params = _params_hash(binding)
    assignments = assignments_for_student('submitting', **params)
    return assignments if scope_only
    select_available_assignments(assignments, include_concluded: include_concluded)
  end

  def submitted_assignments(
    scope_only: false,
    include_concluded: false,
    **opts # forward args to assignments_for_student
  )
    params = _params_hash(binding)
    assignments = assignments_for_student('submitted', **params)
    return assignments if scope_only
    select_available_assignments(assignments, include_concluded: include_concluded)
  end

  def ungraded_quizzes(
    limit: ULOS_DEFAULT_LIMIT,
    due_after: Time.zone.now,
    due_before: 1.week.from_now,
    needing_submitting: false,
    scope_only: false,
    include_locked: false,
    include_concluded: false,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    opts.merge!(params.slice(:limit, :scope_only, :include_concluded))
    objects_needing('Quizzes::Quiz', 'viewing', :student, params, 15.minutes, **opts) do |quiz_scope|
      quizzes = quiz_scope.available
      quizzes = quizzes.not_locked unless include_locked
      quizzes = quizzes.
        ungraded_due_between_for_user(due_after, due_before, self).
        preload(:context)
      quizzes = quizzes.need_submitting_info(id, limit) if needing_submitting
      return quizzes if scope_only
      select_available_assignments(quizzes, include_concluded: include_concluded)
    end
  end

  def submissions_needing_peer_review(
    limit: ULOS_DEFAULT_LIMIT,
    due_after: 2.weeks.ago,
    due_before: 2.weeks.from_now,
    scope_only: false,
    include_ignored: false,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    opts.merge!(params.slice(:limit, :scope_only, :include_ignored))
    objects_needing('AssessmentRequest', 'reviewing', :student, params, 15.minutes, **opts) do |ar_scope, shard_course_ids|
      ar_scope = ar_scope.joins(submission: :assignment).
        joins("INNER JOIN #{Submission.quoted_table_name} AS assessor_asset ON assessment_requests.assessor_asset_id = assessor_asset.id
               AND assessor_asset.assignment_id = assignments.id").
        where(assessor_id: id)
      ar_scope = ar_scope.incomplete unless scope_only
      ar_scope = ar_scope.for_context_codes(shard_course_ids.map { |course_id| "course_#{course_id}"})

      # The below merging of scopes mimics a portion of the behavior for checking the access policy
      # for the submissions, ensuring that the user has access and can read & comment on them.
      # The check for making sure that the user is a participant in the course is already made
      # by using `course_ids_for_todo_lists` through `objects_needing`
      ar_scope = ar_scope.merge(Submission.active).
        merge(Assignment.published.where(peer_reviews: true))

      if due_before
        ar_scope = ar_scope.where("COALESCE(assignments.peer_reviews_due_at, assessor_asset.cached_due_date) <= ?", due_before)
      end

      if due_after
        ar_scope = ar_scope.where("COALESCE(assignments.peer_reviews_due_at, assessor_asset.cached_due_date) > ?", due_after)
      end

      if scope_only
        ar_scope
      else
        result = limit ? ar_scope.take(limit) : ar_scope.to_a
        result
      end
    end
  end

  # opts forwaded to course_ids_for_todo_lists
  def assignments_needing_grading_count(**opts)
    course_ids = course_ids_for_todo_lists(:instructor, **opts)
    Submission.active.
      needs_grading.
      joins(assignment: :course).
      where(courses: { id: course_ids }).
      merge(Assignment.expecting_submission).
      merge(Assignment.published).
      where("NOT EXISTS (?)",
        Ignore.where(asset_type: 'Assignment',
                     user_id: self,
                     purpose: 'grading').where('asset_id=submissions.assignment_id')).count
  end

  def assignments_needing_grading(
    limit: ULOS_DEFAULT_LIMIT,
    scope_only: false,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    # not really any harm in extending the expires_in since we touch the user anyway when grades change
    objects_needing('Assignment', 'grading', :instructor, params, 120.minutes, **params) do |assignment_scope|
      as = assignment_scope.active.
        expecting_submission.
        need_grading_info
      ActiveRecord::Associations::Preloader.new.preload(as, :context)
      if scope_only
        as # This needs the below `select` somehow to work
      else
        as.lazy.reject{|a| Assignments::NeedsGradingCountQuery.new(a, self).count == 0 }.take(limit).to_a
      end
    end
  end

  def assignments_needing_moderation(
    limit: ULOS_DEFAULT_LIMIT,
    scope_only: false,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    objects_needing('Assignment', 'moderation', :instructor, params, 120.minutes, **params) do |assignment_scope|
      scope = assignment_scope.active.
        expecting_submission.
        where(final_grader: self, moderated_grading: true).
        where("assignments.grades_published_at IS NULL").
        where(id: ModeratedGrading::ProvisionalGrade.joins(:submission).
          where("submissions.assignment_id=assignments.id").
          where(Submission.needs_grading_conditions).distinct.select(:assignment_id)).
        preload(:context)
      if scope_only
        scope # Also need to check the rights like below
      else
        scope.lazy.select{|a| a.permits_moderation?(self)}.take(limit).to_a
      end
    end
  end

  def discussion_topics_needing_viewing(
    due_after:,
    due_before:,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    objects_needing('DiscussionTopic', 'viewing', :student, params, 120.minutes, **opts) do |topics_context, shard_course_ids, shard_group_ids|
      topics_context.
        active.
        published.
        for_courses_and_groups(shard_course_ids, shard_group_ids).
        todo_date_between(due_after, due_before).
        visible_to_student_sections(self)
    end
  end

  def wiki_pages_needing_viewing(
    due_after:,
    due_before:,
    **opts # arguments that are just forwarded to objects_needing
  )
    params = _params_hash(binding)
    objects_needing('WikiPage', 'viewing', :student, params, 120.minutes, **opts) do |wiki_pages_context, shard_course_ids, shard_group_ids|
      wiki_pages_context.
        available_to_planner.
        visible_to_user(self).
        for_courses_and_groups(shard_course_ids, shard_group_ids).
        todo_date_between(due_after, due_before)
    end
  end
end
