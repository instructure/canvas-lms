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
    return assignment_or_quiz if user.nil? or assignment_or_quiz.overridden_for?(user)

    overrides = self.overrides_for_assignment_and_user(assignment_or_quiz, user)
 
    result_assignment_or_quiz = self.assignment_with_overrides(assignment_or_quiz, overrides) unless overrides.empty?
    result_assignment_or_quiz ||= assignment_or_quiz
    result_assignment_or_quiz.overridden_for_user = user
    result_assignment_or_quiz
  end

  def self.quiz_overridden_for(quiz, user)
    assignment_overridden_for(quiz, user)
  end


  def self.assignment_overriden_for_section(assignment_or_quiz, section)
    section_overrides = assignment_or_quiz.assignment_overrides.scoped(:conditions => {:set_type => 'CourseSection', :set_id => section.id})
    override_for_due_at(assignment_or_quiz, section_overrides)
  end

  # determine list of overrides (of appropriate version) that apply to the
  # assignment or quiz(of specific version) for a particular user. the overrides are
  # returned in priority order; the first override to contain an overridden
  # value for a particular field is used for that field
  def self.overrides_for_assignment_and_user(assignment_or_quiz, user)
    Rails.cache.fetch([user, assignment_or_quiz, assignment_or_quiz.version_number, 'overrides'].cache_key) do

      # return an empty array to the block if there is nothing to do here
      next [] unless assignment_or_quiz.has_overrides?

      overrides = []

      # get list of overrides that might apply. adhoc override is highest
      # priority, then group override, then section overrides by position. DO
      # NOT exclude deleted overrides, yet
      key = assignment_or_quiz.is_a?(Quiz) ? :quiz_id : :assignment_id
      adhoc_membership = AssignmentOverrideStudent.scoped(:conditions => {key => assignment_or_quiz.id, :user_id => user.id}).first
      
      overrides << adhoc_membership.assignment_override if adhoc_membership

      if assignment_or_quiz.is_a?(Assignment) && assignment_or_quiz.group_category && group = user.current_groups.scoped(:conditions => {:group_category_id => assignment_or_quiz.group_category_id}).first
        group_override = assignment_or_quiz.assignment_overrides.
          scoped(:conditions => {:set_type => 'Group', :set_id => group.id}).
          first
        overrides << group_override if group_override
      end

      observed_students = ObserverEnrollment.observed_students(assignment_or_quiz.context, user)
      observed_student_overrides = observed_students.map do |student, enrollments|
        overrides_for_assignment_and_user(assignment_or_quiz, student)
      end

      overrides += observed_student_overrides.flatten.uniq

      section_ids = user.enrollments.active.scoped(:conditions =>
        { :type => ['StudentEnrollment', 'ObserverEnrollment', 'StudentViewEnrollment'],
          :course_id => assignment_or_quiz.context_id}).map(&:course_section_id)

      section_overrides = assignment_or_quiz.assignment_overrides.
        scoped(:conditions => {:set_type => 'CourseSection', :set_id => section_ids})

      # TODO add position column to assignment_override, nil for non-section
      # overrides, (assignment_or_quiz, position) unique for section overrides
      overrides += section_overrides#.scoped(:order => :position)

      # for each potential override discovered, make sure we look at the
      # appropriate version
      overrides = overrides.map do |override|
        if override.versions.empty?
          override
        else
          override_version = override.versions.detect do |version|
            model_version = assignment_or_quiz.is_a?(Quiz) ? version.model.quiz_version : version.model.assignment_version
            model_version <= assignment_or_quiz.version_number
          end
          override_version ? override_version.model : nil
        end
      end

      # discard overrides where there was no appropriate version or the
      # appropriate version is in the deleted state
      overrides.compact.select(&:active?)
    end
  end

  # apply the overrides calculated by collapsed_overrides to a clone of the
  # assignment or quiz which can then be used in place of the original object.
  # the clone is marked readonly to prevent saving
  def self.assignment_with_overrides(assignment_or_quiz, overrides)
    # ActiveRecord::Base#clone nils out the primary key; put it back
    cloned_assignment_or_quiz = assignment_or_quiz.clone
    cloned_assignment_or_quiz.id = assignment_or_quiz.id

    # update attributes with overrides
    self.collapsed_overrides(assignment_or_quiz, overrides).each do |field,value|
      # for any times in the value set, bring them back from raw UTC into the
      # current Time.zone before placing them in the assignment
      value = value.in_time_zone if value && value.respond_to?(:in_time_zone) && !value.is_a?(Date)
      cloned_assignment_or_quiz.write_attribute(field, value)
    end
    cloned_assignment_or_quiz.applied_overrides = overrides
    cloned_assignment_or_quiz.readonly!

    # make new_record? match the original (typically always true on AR clones,
    # at least until saved, which we don't want to do)
    klass = class << cloned_assignment_or_quiz; self; end
    klass.send(:define_method, :new_record?) { assignment_or_quiz.new_record? }

    cloned_assignment_or_quiz
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
    Rails.cache.fetch([assignment_or_quiz, assignment_or_quiz.version_number, self.overrides_hash(overrides)].cache_key) do
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
    unlock_ats = overrides.select(&:unlock_at_overridden).map(&:unlock_at)
    unlock_ats.any?(&:nil?) ? nil : [assignment_or_quiz.unlock_at, *unlock_ats].compact.min
  end

  def self.overridden_lock_at(assignment_or_quiz, overrides)
    lock_ats = overrides.select(&:lock_at_overridden).map(&:lock_at)
    lock_ats.any?(&:nil?) ? nil : [assignment_or_quiz.lock_at, *lock_ats].compact.max
  end
end
