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
    return course.active_assignments if course.grants_any_right?(self, :read_as_admin, :manage_grades, :manage_assignments)
    published_visible_assignments = course.active_assignments.published
    published_visible_assignments = DifferentiableAssignment.scope_filter(published_visible_assignments,self,course, is_teacher: false)
    published_visible_assignments
  end

  def course_ids_for_todo_lists(participation_type, opts)
    shard.activate do
      course_ids = Shackles.activate(:slave) do
        if opts[:include_concluded]
          participated_course_ids
        else
          case participation_type
          when :student
            participating_student_course_ids
          when :instructor
            participating_instructor_course_ids
          end
        end
      end

      if opts[:only_favorites]
        course_ids &= favorite_context_ids("Course")
      end

      if opts[:contexts]
        course_ids = Array(opts[:contexts]).map(&:id) & course_ids
      end
      course_ids
    end
  end

  def objects_needing(object_type, purpose, participation_type, expires_in, opts={})
    original_shard = Shard.current
    shard.activate do
      course_ids = course_ids_for_todo_lists(participation_type, opts)
      opts = {limit: 15}.merge(opts.slice(:due_after, :due_before, :limit, :include_ungraded, :ungraded_quizzes, :include_ignored,
        :include_locked, :include_concluded, :scope_only, :only_favorites, :needing_submitting, :role))

      if opts[:scope_only]
        Shard.partition_by_shard(course_ids) do |shard_course_ids|
          next unless Shard.current == original_shard # only provide scope on current shard
          return yield(*arguments_for_objects_needing(object_type, purpose, shard_course_ids, participation_type, opts))
        end
        return object_type.constantize.none # fallback
      else
        course_ids_cache_key = Digest::MD5.hexdigest(course_ids.sort.join('/'))
        cache_key = [self, "#{object_type}_needing_#{purpose}", course_ids_cache_key, opts].cache_key
        Rails.cache.fetch(cache_key, expires_in: expires_in) do
          result = Shackles.activate(:slave) do
            Shard.partition_by_shard(course_ids) do |shard_course_ids|
              yield(*arguments_for_objects_needing(object_type, purpose, shard_course_ids, participation_type, opts))
            end
          end
          result = result[0...opts[:limit]] if opts[:limit]
          result
        end
      end
    end
  end

  def arguments_for_objects_needing(object_type, purpose, shard_course_ids, participation_type, opts)
    scope = object_type.constantize
    scope = scope.not_ignored_by(self, purpose) unless opts[:include_ignored]
    scope = scope.for_course(shard_course_ids) if ['Assignment', 'Quizzes::Quiz'].include?(object_type)
    if object_type == 'Assignment'
      scope = participation_type == :student ? scope.published : scope.active
      scope = scope.expecting_submission unless opts[:include_ungraded]
    end
    [scope, opts.merge(shard_course_ids: shard_course_ids)]
  end

  def assignments_for_student(purpose, opts={})
    opts[:due_after] ||= 2.weeks.ago
    opts[:due_before] ||= 2.weeks.from_now
    cache_timeout = opts[:cache_timeout] || 120.minutes
    objects_needing('Assignment', purpose, :student, cache_timeout, opts) do |assignment_scope, options|
      assignments = assignment_scope.due_between_for_user(options[:due_after], options[:due_before], self)
      assignments = assignments.need_submitting_info(id, options[:limit]) if purpose == 'submitting'
      assignments = assignments.having_submissions_for_user(id) if purpose == 'submitted'
      assignments = assignments.not_locked unless options[:include_locked]
      assignments
    end
  end

  def assignments_needing_submitting(opts={})
    opts[:due_after] ||= 4.weeks.ago
    opts[:due_before] ||= 1.week.from_now
    opts[:cache_timeout] = 15.minutes
    assignments = assignments_for_student('submitting', opts)
    return assignments if opts[:scope_only]
    select_available_assignments(assignments, opts).reject do |a|
      a.due_at && a.due_at < Time.zone.now && !a.expects_submission?
    end
  end

  def submitted_assignments(opts={})
    assignments = assignments_for_student('submitted', opts)
    return assignments if opts[:scope_only]
    select_available_assignments(assignments, opts)
  end

  def ungraded_quizzes(opts={})
    objects_needing('Quizzes::Quiz', 'viewing', :student, 15.minutes, opts) do |quiz_scope, options|
      due_after = options[:due_after] || Time.zone.now
      due_before = options[:due_before] || 1.week.from_now

      quizzes = quiz_scope.available
      quizzes = quizzes.not_locked unless opts[:include_locked]
      quizzes = quizzes.
        ungraded_due_between_for_user(due_after, due_before, self).
        preload(:context)
      quizzes = quizzes.need_submitting_info(id, options[:limit]) if options[:needing_submitting]
      if options[:scope_only]
        quizzes
      else
        select_available_assignments(quizzes, options)
      end
    end
  end

  def submissions_needing_peer_review(opts={})
    course_ids = Shackles.activate(:slave) do
      if opts[:contexts]
        (Array(opts[:contexts]).map(&:id) &
        participating_student_course_ids)
      else
        participating_student_course_ids
      end
    end
    opts = {limit: 15}.merge(opts.slice(:limit))

    shard.activate do
      Rails.cache.fetch([self, 'submissions_needing_peer_review', course_ids, opts].cache_key, expires_in: 15.minutes) do
        Shackles.activate(:slave) do
          limit = opts[:limit]

          result = Shard.partition_by_shard(course_ids) do |shard_course_ids|
            shard_course_context_codes = shard_course_ids.map { |course_id| "course_#{course_id}"}
            AssessmentRequest.where(assessor_id: id).incomplete.
              not_ignored_by(self, 'reviewing').
              for_context_codes(shard_course_context_codes).
              preload({submission: :assignment}) # avoid n+1 query on grants_right? check below
          end

          # only include assessment requests user has permission to perform.
          # This has 2 parts
          # 1. the reviewer must have permission to read the submission, and
          # 2. the submission must still be part of the assignment, which will
          #    be false if the submitter is no longer assigned the assigment
          result = result.select do |request|
            request.submission.grants_right?(self, :read) &&
            request.submission.assignment.submissions.include?(request.submission)
          end
          # outer limit, since there could be limit * n_shards results
          result = result[0...limit] if limit
          result
        end
      end
    end
  end

  def assignments_needing_grading(opts={})
    # not really any harm in extending the expires_in since we touch the user anyway when grades change
    objects_needing('Assignment', 'grading', :instructor, 120.minutes, opts) do |assignment_scope, options|
      as = assignment_scope.active.
        expecting_submission.
        need_grading_info
      ActiveRecord::Associations::Preloader.new.preload(as, :context)
      if options[:scope_only]
        as # This needs the below `select` somehow to work
      else
        as.lazy.reject{|a| Assignments::NeedsGradingCountQuery.new(a, self).count == 0 }.take(options[:limit]).to_a
      end
    end
  end

  def assignments_needing_moderation(opts={})
    objects_needing('Assignment', 'moderation', :instructor, 120.minutes, opts) do |assignment_scope, options|
      scope = assignment_scope.active.
        expecting_submission.
        where(:moderated_grading => true).
        where("assignments.grades_published_at IS NULL").
        where(:id => ModeratedGrading::ProvisionalGrade.joins(:submission).where("submissions.assignment_id=assignments.id").
          where(Submission.needs_grading_conditions).distinct.select(:assignment_id)).
        preload(:context)
      if options[:scope_only]
        scope # Also need to check the rights like below
      else
        scope.lazy.select{|a| a.context.grants_right?(self, :moderate_grades)}.take(options[:limit]).to_a
      end
    end
  end

  def discussion_topics_needing_viewing(opts={})
    objects_needing('DiscussionTopic', 'viewing', :student, 120.minutes, opts) do |topics_context, options|
      topics_context.
        active.
        published.
        for_courses_and_groups(options[:shard_course_ids], cached_current_group_memberships.pluck(:group_id)).
        todo_date_between(opts[:due_after], opts[:due_before])
    end
  end

  def wiki_pages_needing_viewing(opts={})
    objects_needing('WikiPage', 'viewing', :student, 120.minutes, opts) do |wiki_pages_context, options|
      wiki_pages_context.
        available_to_planner.
        visible_to_user(self).
        for_courses_and_groups(options[:shard_course_ids], cached_current_group_memberships.pluck(:group_id)).
        todo_date_between(opts[:due_after], opts[:due_before])
    end
  end

  def submission_statuses(opts = {})
    Rails.cache.fetch(['assignment_submission_statuses', self, opts].cache_key, :expires_in => 120.minutes) do
      opts[:due_after] ||= 2.weeks.ago

      {
        submitted: Set.new(submitted_assignments(opts).pluck(:id)),
        excused: Set.new(Submission.active.with_assignment.where(excused: true, user_id: self).pluck(:assignment_id)),
        graded: Set.new(Submission.active.with_assignment.where(user_id: self).
          where("submissions.excused = true OR (submissions.score IS NOT NULL AND submissions.workflow_state = 'graded')").
          pluck(:assignment_id)),
        late: Set.new(Submission.active.with_assignment.late.where(user_id: self).pluck(:assignment_id)),
        missing: Set.new(Submission.active.with_assignment.missing.where(user_id: self).pluck(:assignment_id)),
        needs_grading: Set.new(Submission.active.with_assignment.needs_grading.where(user_id: self).pluck(:assignment_id)),
        # distinguishes between assignment being graded and having feedback comments, but cannot discern
        # new feedback and new grades if there is already feedback. that's OK for now, since the "New" was
        # removed from the "New Grades" and "New Feedback" pills in the UI to simply indicate if there is _any_ feedback or grade.
        has_feedback: Set.new((self.recent_feedback(start_at: opts[:due_after]).
          select { |feedback| feedback[:submission_comments_count].to_i > 0 }).pluck(:assignment_id)),
        new_activity: Set.new(Submission.active.with_assignment.unread_for(self).pluck(:assignment_id))
      }.with_indifferent_access
    end
  end
end
