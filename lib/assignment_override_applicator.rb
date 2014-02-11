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
  def self.assignment_overridden_for(assignment_or_quiz, user)
    return assignment_or_quiz if assignment_or_quiz.overridden_for?(user)

    # this is a cheap hack to avoid unnecessary work (especially stupid
    # simply_versioned queries)
    if assignment_or_quiz.has_no_overrides
      return setup_overridden_clone(assignment_or_quiz)
    end

    overrides = self.overrides_for_assignment_and_user(assignment_or_quiz, user)

    result_assignment_or_quiz = self.assignment_with_overrides(assignment_or_quiz, overrides)
    result_assignment_or_quiz.overridden_for_user = user

    # students get the last overridden date that applies to them, but teachers
    # should see the assignment's due_date if that is more lenient
    context = result_assignment_or_quiz.context
    if context && result_assignment_or_quiz.grants_right?(user, nil, :delete)

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

  def self.assignment_overriden_for_section(assignment_or_quiz, section)
    section_overrides = assignment_or_quiz.assignment_overrides.where(:set_type => 'CourseSection', :set_id => section)
    override_for_due_at(assignment_or_quiz, section_overrides)
  end

  # determine list of overrides (of appropriate version) that apply to the
  # assignment or quiz(of specific version) for a particular user. the overrides are
  # returned in priority order; the first override to contain an overridden
  # value for a particular field is used for that field
  def self.overrides_for_assignment_and_user(assignment_or_quiz, user)
    Rails.cache.fetch([user, assignment_or_quiz, 'overrides'].cache_key) do
      next [] if self.has_invalid_args?(assignment_or_quiz, user)
      context = assignment_or_quiz.context
      overrides = []

      if context.account_membership_allows(user, nil, :manage_courses)
        overrides = assignment_or_quiz.assignment_overrides.active.to_a
        unless assignment_or_quiz.current_version?
          overrides = current_override_version(assignment_or_quiz, overrides)
        end
        return overrides
      end

      # priority: adhoc, group, section (do not exclude deleted)
      if context.user_has_been_admin?(user)
        adhoc = adhoc_admin_overrides(assignment_or_quiz, user, context)
        overrides += adhoc if adhoc
      else
        adhoc = adhoc_override(assignment_or_quiz, user)
        overrides << adhoc.assignment_override if adhoc
      end

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

  def self.has_invalid_args?(assignment_or_quiz, user)
    user.nil? || !assignment_or_quiz.has_overrides?
  end

  def self.adhoc_override(assignment_or_quiz, user)
    key = assignment_or_quiz.is_a?(Quizzes::Quiz) ? :quiz_id : :assignment_id
    AssignmentOverrideStudent.where(key => assignment_or_quiz, :user_id => user).first
  end

  def self.adhoc_admin_overrides(assignment_or_quiz, user, course)
    key = assignment_or_quiz.is_a?(Quizzes::Quiz) ? :quiz_id : :assignment_id
    students = course.enrollments_visible_to(user).pluck(:user_id)
    adhoc = AssignmentOverrideStudent.where(:user_id => students, key => assignment_or_quiz)
    adhoc.map(&:assignment_override)
  end

  def self.group_override(assignment_or_quiz, user)
    return nil unless assignment_or_quiz.is_a?(Assignment) && assignment_or_quiz.group_category

    if assignment_or_quiz.context.user_has_been_student?(user)
      group = user.current_groups.where(:group_category_id => assignment_or_quiz.group_category_id).first
    else
      group = assignment_or_quiz.context.groups.where(:group_category_id => assignment_or_quiz.group_category_id).first
    end

    if group
      assignment_or_quiz.assignment_overrides.where(:set_type => 'Group', :set_id => group.id).first
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
    section_ids = context.sections_visible_to(user).map(&:id)
    section_ids += context.section_visibilities_for(user).select { |v|
        ['StudentEnrollment', 'ObserverEnrollment', 'StudentViewEnrollment'].include? v[:type]
      }.map { |v| v[:course_section_id] }
    section_overrides = assignment_or_quiz.assignment_overrides.where(:set_type => 'CourseSection', :set_id => section_ids.uniq)
    section_overrides
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
    clone = assignment.clone

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
      if overrides
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
    Rails.cache.fetch([assignment_or_quiz, self.overrides_hash(overrides)].cache_key) do
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

  # turn the list of overrides into a unique but consistent cache key component
  def self.overrides_hash(overrides)
    canonical = overrides.map{ |override| { :id => override.id, :version => override.version_number } }.inspect
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
    if applicable_overrides.empty?
      assignment_or_quiz.unlock_at
    elsif override = applicable_overrides.detect{ |o| o.unlock_at.nil? }
      nil
    else
      applicable_overrides.sort_by(&:unlock_at).first.unlock_at
    end
  end

  def self.overridden_lock_at(assignment_or_quiz, overrides)
    applicable_overrides = overrides.select(&:lock_at_overridden)
    if applicable_overrides.empty?
      assignment_or_quiz.lock_at
    elsif override = applicable_overrides.detect{ |o| o.lock_at.nil? }
      nil
    else
      applicable_overrides.sort_by(&:lock_at).last.lock_at
    end
  end
end
