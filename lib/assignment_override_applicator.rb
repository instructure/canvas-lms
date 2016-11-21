#
# Copyright (C) 2011 Instructure, Inc.
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

module AssignmentOverrideApplicator
  # top-level method intended for consumption. given an assignment or quiz(of specific
  # version) and user, determine the list of overrides, apply them to the
  # assignment or quiz, and return the overridden stand-in.
  # pass skip_clone if you don't really care about the override attributes, and
  # it's okay to get back the passed in object - that you promise not to modify -
  # if there are no overrides
  def self.assignment_overridden_for(assignment_or_quiz, user, skip_clone: false)
    return assignment_or_quiz if assignment_or_quiz.overridden_for?(user)

    # this is a cheap hack to avoid unnecessary work (especially stupid
    # simply_versioned queries)
    if assignment_or_quiz.has_no_overrides
      return assignment_or_quiz if skip_clone
      return setup_overridden_clone(assignment_or_quiz)
    end

    overrides = self.overrides_for_assignment_and_user(assignment_or_quiz, user)

    result_assignment_or_quiz = self.assignment_with_overrides(assignment_or_quiz, overrides)
    result_assignment_or_quiz.overridden_for_user = user

    # students get the last overridden date that applies to them, but teachers
    # should see the assignment's due_date if that is more lenient
    context = result_assignment_or_quiz.context
    if context &&
      (context.user_has_been_admin?(user) || context.user_has_no_enrollments?(user)) && # don't make a permissions call if we don't need to
      context.grants_right?(user, :manage_assignments) # faster than calling :delete rights on each assignment/quiz

      overridden_section_ids = result_assignment_or_quiz
        .applied_overrides.select { |o| o.set_type == "CourseSection" }
        .map(&:set_id)
      course_section_ids = context.active_course_sections.map(&:id)

      result_assignment_or_quiz.due_at =
        # if only some sections are overridden, return the most due date for
        # teachers, if all sections are overridden, return the most lenient
        # section overriddden due date
        if overridden_section_ids.sort == course_section_ids.sort
          result_assignment_or_quiz.due_at
        else
          potential_due_dates = [
            result_assignment_or_quiz.without_overrides.due_at,
            result_assignment_or_quiz.due_at
          ]
          potential_due_dates.include?(nil) ?
            nil :
            potential_due_dates.max
        end
    end

    result_assignment_or_quiz
  end

  def self.quiz_overridden_for(quiz, user)
    assignment_overridden_for(quiz, user)
  end

  # determine list of overrides (of appropriate version) that apply to the
  # assignment or quiz(of specific version) for a particular user. the overrides are
  # returned in priority order; the first override to contain an overridden
  # value for a particular field is used for that field
  def self.overrides_for_assignment_and_user(assignment_or_quiz, user)
    cache_key = [user, assignment_or_quiz, 'overrides'].cache_key
    Rails.cache.delete(cache_key) if assignment_or_quiz.reload_overrides_cache?
    Rails.cache.fetch(cache_key) do
      next [] if self.has_invalid_args?(assignment_or_quiz, user)
      context = assignment_or_quiz.context

      if context.grants_right?(user, :read_as_admin)
        overrides = assignment_or_quiz.assignment_overrides
        if assignment_or_quiz.current_version?
          visible_user_ids = context.enrollments_visible_to(user).select(:user_id)

          overrides = if overrides.loaded?
                        ovs, adhoc_ovs = overrides.select{|ov| ov.workflow_state == 'active'}.
                          partition {|ov| ov.set_type != 'ADHOC' }

                        preload_student_ids_for_adhoc_overrides(adhoc_ovs, visible_user_ids)
                        ovs + adhoc_ovs.select{|ov| ov.preloaded_student_ids.any?}
                      else
                        ovs = overrides.active.where.not(set_type: 'ADHOC').to_a
                        adhoc_ovs = overrides.active.visible_students_only(visible_user_ids).to_a
                        preload_student_ids_for_adhoc_overrides(adhoc_ovs, visible_user_ids)

                        ovs + adhoc_ovs
                      end
        else
          overrides = current_override_version(assignment_or_quiz, overrides)
        end

        unless ConditionalRelease::Service.enabled_in_context?(assignment_or_quiz.context)
          overrides = overrides.select { |override| override.try(:set_type) != 'Noop' }
        end

        return overrides
      end

      overrides = []

      # priority: adhoc, group, section (do not exclude deleted)
      adhoc = adhoc_override(assignment_or_quiz, user)
      overrides << adhoc.assignment_override if adhoc

      if ObserverEnrollment.observed_students(context, user).empty?
        group = group_override(assignment_or_quiz, user)
        overrides << group if group
        sections = section_overrides(assignment_or_quiz, user)
        overrides += sections if sections
      else
        observed = observer_overrides(assignment_or_quiz, user)
        overrides += observed if observed
      end

      unless assignment_or_quiz.current_version?
        overrides = current_override_version(assignment_or_quiz, overrides)
      end

      overrides.compact.select(&:active?)
    end
  end

  def self.preload_student_ids_for_adhoc_overrides(adhoc_overrides, visible_user_ids)
    if adhoc_overrides.any?
      override_ids_to_student_ids = {}
      scope = AssignmentOverrideStudent.where(assignment_override_id: adhoc_overrides)
      scope = if ActiveRecord::Relation === visible_user_ids
          return adhoc_overrides if visible_user_ids.is_a?(ActiveRecord::NullRelation)
          scope.
            joins("INNER JOIN #{Enrollment.quoted_table_name} ON assignment_override_students.user_id=enrollments.user_id").
            merge(visible_user_ids.except(:select))
        else
          scope.where(user_id: visible_user_ids)
        end

      scope.pluck(:assignment_override_id, :user_id).each do |ov_id, user_id|
        override_ids_to_student_ids[ov_id] ||= []
        override_ids_to_student_ids[ov_id] << user_id
      end

      # we can preload the student ids right now
      adhoc_overrides.each{ |ov| ov.preloaded_student_ids = override_ids_to_student_ids[ov.id] || [] }
    end
    adhoc_overrides
  end

  def self.has_invalid_args?(assignment_or_quiz, user)
    user.nil? || !assignment_or_quiz.has_overrides?
  end

  def self.adhoc_override(assignment_or_quiz, user)
    return nil unless user

    if assignment_or_quiz.preloaded_override_students && (overrides = assignment_or_quiz.preloaded_override_students[user.id])
      overrides.first
    else
      key = assignment_or_quiz.is_a?(Quizzes::Quiz) ? :quiz_id : :assignment_id
      AssignmentOverrideStudent.where(key => assignment_or_quiz, :user_id => user).first
    end
  end

  def self.group_override(assignment_or_quiz, user)
    return nil unless assignment_or_quiz.is_a?(Assignment)
    group_category_id = assignment_or_quiz.group_category_id || assignment_or_quiz.discussion_topic.try(:group_category_id)
    return nil unless group_category_id

    if assignment_or_quiz.context.user_has_been_student?(user)
      group = user.current_groups.where(:group_category_id => group_category_id).first
    else
      group = assignment_or_quiz.context.groups.where(:group_category_id => group_category_id).first
    end

    if group
      if assignment_or_quiz.assignment_overrides.loaded?
        assignment_or_quiz.assignment_overrides.detect{|o| o.set_type == 'Group' && o.set_id == group.id}
      else
        assignment_or_quiz.assignment_overrides.where(:set_type => 'Group', :set_id => group.id).first
      end
    else
      nil
    end
  end

  def self.observer_overrides(assignment_or_quiz, user)
    context = assignment_or_quiz.context
    observed_students = ObserverEnrollment.observed_students(context, user)
    observed_student_overrides = observed_students.map do |student, enrollments|
      overrides_for_assignment_and_user(assignment_or_quiz, student)
    end
    observed_student_overrides.flatten.uniq
  end

  def self.section_overrides(assignment_or_quiz, user)
    context = assignment_or_quiz.context
    section_ids = RequestCache.cache(:visible_section_ids, context, user) do
      context.sections_visible_to(
        user,
        context.active_course_sections,
        excluded_workflows: ['deleted', 'completed']
      ).map(&:id) +

      context.section_visibilities_for(
        user,
        excluded_workflows: ['deleted', 'completed']
      ).select { |v|
        ['StudentEnrollment', 'ObserverEnrollment', 'StudentViewEnrollment'].include? v[:type]
      }.map { |v| v[:course_section_id] }.uniq
    end

    if assignment_or_quiz.assignment_overrides.loaded?
      assignment_or_quiz.assignment_overrides.select{|o| o.set_type == 'CourseSection' && section_ids.include?(o.set_id)}
    else
      assignment_or_quiz.assignment_overrides.where(:set_type => 'CourseSection', :set_id => section_ids)
    end
  end

  def self.current_override_version(assignment_or_quiz, all_overrides)
    all_overrides.map do |override|
      if !override.versions.exists?
        override
      else
        override_version = override.versions.detect do |version|
          model_version = assignment_or_quiz.is_a?(Quizzes::Quiz) ? version.model.quiz_version : version.model.assignment_version
          next if model_version.nil?
          model_version <= assignment_or_quiz.version_number
        end
        override_version ? override_version.model : nil
      end
    end
  end

  # really takes an assignment or quiz but who wants to type out
  # assignment_or_quiz all the time?
  def self.setup_overridden_clone(assignment, overrides = [])
    assignment.instance_variable_set(:@readonly_clone, true)
    clone = assignment.clone
    assignment.instance_variable_set(:@readonly_clone, false)

    # ActiveRecord::Base#clone wipes out some important crap; put it back
    [:id, :updated_at, :created_at].each { |attr|
      clone[attr] = assignment.send(attr)
    }
    self.copy_preloaded_associations_to_clone(assignment, clone)
    yield(clone) if block_given?

    clone.applied_overrides = overrides
    clone.without_overrides = assignment
    clone.overridden = true
    clone.readonly!

    new_record = assignment.instance_variable_get(:@new_record)
    clone.instance_variable_set(:@new_record, new_record)

    clone
  end

  # apply the overrides calculated by collapsed_overrides to a clone of the
  # assignment or quiz which can then be used in place of the original object.
  # the clone is marked readonly to prevent saving
  def self.assignment_with_overrides(assignment_or_quiz, overrides)
    unoverridden_assignment_or_quiz = assignment_or_quiz.without_overrides

    self.setup_overridden_clone(unoverridden_assignment_or_quiz,
                                overrides) do |cloned_assignment_or_quiz|
      if overrides && overrides.any?
        self.collapsed_overrides(unoverridden_assignment_or_quiz, overrides).each do |field,value|
          # for any times in the value set, bring them back from raw UTC into the
          # current Time.zone before placing them in the assignment
          value = value.in_time_zone if value && value.respond_to?(:in_time_zone) && !value.is_a?(Date)
          cloned_assignment_or_quiz.write_attribute(field, value)
        end
      end
    end
  end

  def self.copy_preloaded_associations_to_clone(orig, clone)
    orig.class.reflections.keys.each do |association|
      association = association.to_sym
      clone.send(:association_instance_set, association, orig.send(:association_instance_get, association))
    end
  end

  def self.quiz_with_overrides(quiz, overrides)
    assignment_with_overrides(quiz, overrides)
  end

  # given an assignment or quiz (of specific version) and an ordered list of overrides
  # (see overrides_for_assignment_and_user), return a hash of values for each
  # overrideable field. for caching, the same set of overrides should produce
  # the same collapsed assignment or quiz, regardless of the user that ended up at that
  # set of overrides.
  def self.collapsed_overrides(assignment_or_quiz, overrides)
    cache_key = [assignment_or_quiz, self.overrides_hash(overrides)].cache_key
    Rails.cache.delete(cache_key) if assignment_or_quiz.reload_overrides_cache?
    RequestCache.cache('collapsed_overrides', cache_key) do
      Rails.cache.fetch(cache_key) do
        overridden_data = {}
        # clone the assignment_or_quiz, apply overrides, and freeze
        [:due_at, :all_day, :all_day_date, :unlock_at, :lock_at].each do |field|
          if assignment_or_quiz.respond_to?(field)
            value = self.send("overridden_#{field}", assignment_or_quiz, overrides)
            # force times to un-zoned UTC -- this will be a cached value and should
            # not care about the TZ of the user that cached it. the user's TZ will
            # be applied before it's returned.
            value = value.utc if value && value.respond_to?(:utc) && !value.is_a?(Date)
            overridden_data[field] = value
          end
        end
        overridden_data
      end
    end
  end

  # turn the list of overrides into a unique but consistent cache key component
  def self.overrides_hash(overrides)
    canonical = overrides.map{ |override| override.cache_key }.inspect
    Digest::MD5.hexdigest(canonical)
  end

  # perform overrides of specific fields
  def self.override_for_due_at(assignment_or_quiz, overrides)
    applicable_overrides = overrides.select(&:due_at_overridden)
    if applicable_overrides.empty?
      assignment_or_quiz
    elsif override = applicable_overrides.detect{ |o| o.due_at.nil? }
      override
    else
      applicable_overrides.sort_by(&:due_at).last
    end
  end

  def self.overridden_due_at(assignment_or_quiz, overrides)
    override_for_due_at(assignment_or_quiz, overrides).due_at
  end

  def self.overridden_all_day(assignment, overrides)
    override_for_due_at(assignment, overrides).all_day
  end

  def self.overridden_all_day_date(assignment, overrides)
    override_for_due_at(assignment, overrides).all_day_date
  end

  def self.overridden_unlock_at(assignment_or_quiz, overrides)
    applicable_overrides = overrides.select(&:unlock_at_overridden)

    # CNVS-24849 if the override has been locked it's unlock_at no longer applies
    applicable_overrides.reject!(&:availability_expired?)

    if applicable_overrides.empty?
      assignment_or_quiz.unlock_at
    elsif applicable_overrides.any? { |o| o.unlock_at.nil? }
      nil
    else
      applicable_overrides.sort_by(&:unlock_at).first.unlock_at
    end
  end

  def self.overridden_lock_at(assignment_or_quiz, overrides)
    applicable_overrides = overrides.select(&:lock_at_overridden)
    if applicable_overrides.empty?
      assignment_or_quiz.lock_at
    elsif applicable_overrides.detect{ |o| o.lock_at.nil? }
      nil
    else
      applicable_overrides.sort_by(&:lock_at).last.lock_at
    end
  end

  def self.should_preload_override_students?(assignments, user, endpoint_key)
    assignment_key = Digest::MD5.hexdigest(assignments.map(&:id).sort.map(&:to_s).join(','))
    key = ['should_preload_assignment_override_students', user, endpoint_key, assignment_key].cache_key
    # if the user has been touch we should preload all of the overrides because it's almost certain we'll need them all
    if Rails.cache.read(key)
      false
    else
      Rails.cache.write(key, true)
      true
    end
  end

  def self.preload_assignment_override_students(items, user)
    return unless user
    ActiveRecord::Associations::Preloader.new.preload(items, :context)
    # preloads the override students for a particular user for many objects at once, instead of doing separate queries for each
    quizzes, assignments = items.partition{|i| i.is_a?(Quizzes::Quiz)}

    ActiveRecord::Associations::Preloader.new.preload(assignments, [:quiz, :assignment_overrides])

    if assignments.any?
      override_students = AssignmentOverrideStudent.where(:assignment_id => assignments, :user_id => user).index_by(&:assignment_id)
      assignments.each do |a|
        a.preloaded_override_students ||= {}
        a.preloaded_override_students[user.id] = Array(override_students[a.id])

        quizzes << a.quiz if a.quiz
      end
    end
    quizzes.uniq!

    ActiveRecord::Associations::Preloader.new.preload(quizzes, :assignment_overrides)

    if quizzes.any?
      override_students = AssignmentOverrideStudent.where(:quiz_id => quizzes, :user_id => user).index_by(&:quiz_id)
      quizzes.each do |q|
        q.preloaded_override_students ||= {}
        q.preloaded_override_students[user.id] = Array(override_students[q.id])
      end
    end
  end
end
