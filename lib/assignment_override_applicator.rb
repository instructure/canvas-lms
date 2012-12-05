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
  # top-level method intended for consumption. given an assignment (of specific
  # version) and user, determine the list of overrides, apply them to the
  # assignment, and return the overridden stand-in.
  def self.assignment_overridden_for(assignment, user)
    overrides = self.overrides_for_assignment_and_user(assignment, user)
    
    if overrides.empty?
      assignment
    else
      self.assignment_with_overrides(assignment, overrides)
    end
  end

  # determine list of overrides (of appropriate version) that apply to the
  # assignment (of specific version) for a particular user. the overrides are
  # returned in priority order; the first override to contain an overridden
  # value for a particular field is used for that field
  def self.overrides_for_assignment_and_user(assignment, user)
    Rails.cache.fetch([user, assignment, assignment.version_number, 'overrides'].cache_key) do

      # return an empty array to the block if there is nothing to do here
      next [] unless assignment.has_overrides?

      overrides = []

      # get list of overrides that might apply. adhoc override is highest
      # priority, then group override, then section overrides by position. DO
      # NOT exclude deleted overrides, yet
      adhoc_membership = AssignmentOverrideStudent.scoped(:conditions => {:assignment_id => assignment.id, :user_id => user.id}).first
      overrides << adhoc_membership.assignment_override if adhoc_membership

      if assignment.group_category && group = user.current_groups.scoped(:conditions => {:group_category_id => assignment.group_category_id}).first
        group_override = assignment.assignment_overrides.
          scoped(:conditions => {:set_type => 'Group', :set_id => group.id}).
          first
        overrides << group_override if group_override
      end

      section_ids = user.enrollments.active.scoped(:conditions =>
        { :type => ['StudentEnrollment', 'ObserverEnrollment'],
          :course_id => assignment.context_id}).map(&:course_section_id)
      
      section_overrides = assignment.assignment_overrides.
        scoped(:conditions => {:set_type => 'CourseSection', :set_id => section_ids})

      # TODO add position column to assignment_override, nil for non-section
      # overrides, (assignment, position) unique for section overrides
      overrides += section_overrides#.scoped(:order => :position)

      # for each potential override discovered, make sure we look at the
      # appropriate version
      overrides = overrides.map do |override|
        override_version = override.versions.detect do |version|
          version.model.assignment_version <= assignment.version_number
        end
        override_version ? override_version.model : nil
      end

      # discard overrides where there was no appropriate version or the
      # appropriate version is in the deleted state
      overrides.select{ |override| override && override.active? }
    end
  end

  # apply the overrides calculated by collapsed_overrides to a clone of the
  # assignment which can then be used in place of the assignment. the clone is
  # marked readonly to prevent saving
  def self.assignment_with_overrides(assignment, overrides)
    # ActiveRecord::Base#clone nils out the primary key; put it back
    cloned_assignment = assignment.clone
    cloned_assignment.id = assignment.id

    # update attributes with overrides
    self.collapsed_overrides(assignment, overrides).each do |field,value|
      # for any times in the value set, bring them back from raw UTC into the
      # current Time.zone before placing them in the assignment
      value = value.in_time_zone if value && value.respond_to?(:in_time_zone) && !value.is_a?(Date)
      cloned_assignment.write_attribute(field, value)
    end
    cloned_assignment.applied_overrides = overrides
    cloned_assignment.readonly!

    # make new_record? match the original (typically always true on AR clones,
    # at least until saved, which we don't want to do)
    klass = class << cloned_assignment; self; end
    klass.send(:define_method, :new_record?) { assignment.new_record? }

    cloned_assignment
  end

  # given an assignment (of specific version) and an ordered list of overrides
  # (see overrides_for_assignment_and_user), return a hash of values for each
  # overrideable field. for caching, the same set of overrides should produce
  # the same collapsed assignment, regardless of the user that ended up at that
  # set of overrides.
  def self.collapsed_overrides(assignment, overrides)
    Rails.cache.fetch([assignment, assignment.version_number, self.overrides_hash(overrides)].cache_key) do
      overridden_data = {}
      # clone the assignment, apply overrides, and freeze
      [:due_at, :all_day, :all_day_date, :unlock_at, :lock_at].each do |field|
        value = self.send("overridden_#{field}", assignment, overrides)
        # force times to un-zoned UTC -- this will be a cached value and should
        # not care about the TZ of the user that cached it. the user's TZ will
        # be applied before it's returned.
        value = value.utc if value && value.respond_to?(:utc) && !value.is_a?(Date)
        overridden_data[field] = value
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
  def self.override_for_due_at(assignment, overrides)
    applicable_overrides = overrides.select(&:due_at_overridden)
    if applicable_overrides.empty?
      assignment
    elsif override = applicable_overrides.detect{ |o| o.due_at.nil? }
      override
    else
      override = applicable_overrides.sort_by(&:due_at).last
      if assignment.due_at && assignment.due_at > override.due_at
        assignment
      else
        override
      end
    end
  end

  def self.overridden_due_at(assignment, overrides)
    override_for_due_at(assignment, overrides).due_at
  end

  def self.overridden_all_day(assignment, overrides)
    override_for_due_at(assignment, overrides).all_day
  end

  def self.overridden_all_day_date(assignment, overrides)
    override_for_due_at(assignment, overrides).all_day_date
  end

  def self.overridden_unlock_at(assignment, overrides)
    unlock_ats = overrides.select(&:unlock_at_overridden).map(&:unlock_at)
    unlock_ats.any?(&:nil?) ? nil : [assignment.unlock_at, *unlock_ats].compact.min
  end

  def self.overridden_lock_at(assignment, overrides)
    lock_ats = overrides.select(&:lock_at_overridden).map(&:lock_at)
    lock_ats.any?(&:nil?) ? nil : [assignment.lock_at, *lock_ats].compact.max
  end
end
