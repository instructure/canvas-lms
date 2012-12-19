module DatesOverridable
  attr_accessor :applied_overrides
  attr_accessor :overridden_for_user_id

  def self.included(base)
    base.has_many :assignment_overrides, :dependent => :destroy
    base.has_many :active_assignment_overrides, :class_name => 'AssignmentOverride', :conditions => {:workflow_state => 'active'}
    base.has_many :assignment_override_students, :dependent => :destroy
    
    base.validates_associated :assignment_overrides
  end

  def overridden_for(user)
    AssignmentOverrideApplicator.assignment_overridden_for(self, user)
  end

  def overrides_visible_to(user, overrides=active_assignment_overrides)
    # the visible_to scope is potentially expensive. skip its conditions if the
    # initial scope is already empty
    if overrides.first.present?
      overrides.visible_to(user, context)
    else
      overrides
    end
  end

  def has_overrides?
    assignment_overrides.count > 0
  end

  # returns two values indicating which due dates for this assignment apply
  # and/or are visible to the user.
  #
  # the first is the due date as it applies to the user as a student, if any
  # (nil if the user has no student enrollment(s) in the assignment's course)
  #
  # the second is a list of due dates a they apply to users, sections, or
  # groups visible to the user as an admin (nil if the user has no
  # admin/observer enrollment(s) in the assignment's course)
  #
  # in both cases, "due dates" is a hash with due_at (full timestamp), all_day
  # flag, and all_day_date. for the "as an admin" list, each due date from
  # an override will also have a 'title' key to identify which subset of the
  # course is affected by that due date, and an 'override' key referencing the
  # override itself. for the original due date, it will instead have a 'base'
  # flag (value true).
  def due_dates_for(user)
    as_student, as_admin = nil, nil
    return nil, nil if context.nil?

    if context.user_has_been_student?(user)
      as_student = self.overridden_for(user).due_date_hash
    end

    if context.user_has_been_admin?(user)
      as_admin = due_dates_visible_to(user)

    elsif context.user_has_been_observer?(user)
      as_admin = observed_student_due_dates(user).uniq

      if as_admin.empty?
        as_admin = [self.overridden_for(user).due_date_hash]
      end

    elsif context.user_has_no_enrollments?(user)
      as_admin = all_due_dates
    end

    return as_student, as_admin
  end

  def all_due_dates
    all_dates = assignment_overrides.overriding_due_at.map(&:as_hash)
    all_dates << due_date_hash.merge(:base => true)
  end

  def due_dates_visible_to(user)
    # Overrides
    overrides = overrides_visible_to(user).overriding_due_at
    list = overrides.map(&:as_hash)

    # Base
    list << self.due_date_hash.merge(:base => true)
  end

  def observed_student_due_dates(user)
    ObserverEnrollment.observed_students(context, user).map do |student, enrollments|
      self.overridden_for(student).due_date_hash
    end
  end

  def due_date_hash
    hash = { :due_at => due_at }

    if self.is_a?(Assignment)
      hash.merge!({ :all_day => all_day, :all_day_date => all_day_date })
    end

    if @applied_overrides && override = @applied_overrides.find { |o| o.due_at == due_at }
      hash[:override] = override
      hash[:title] = override.title
    end

    hash
  end

  def multiple_due_dates_apply_to(user)
    as_instructor = self.due_dates_for(user).second
    as_instructor && as_instructor.map{ |hash|
      self.class.due_date_compare_value(hash[:due_at]) }.uniq.size > 1
  end

  # like due_dates_for, but for unlock_at values instead. for consistency, each
  # unlock_at is still represented by a hash, even though the "as a student"
  # value will only have one key.
  def unlock_ats_for(user)
    as_student, as_instructor = nil, nil

    if context.user_has_been_student?(user)
      overridden = self.overridden_for(user)
      as_student = { :unlock_at => overridden.unlock_at }
    end

    if context.user_has_been_instructor?(user)
      overrides = self.overrides_visible_to(user).overriding_unlock_at

      as_instructor = overrides.map do |override|
        {
          :title => override.title,
          :unlock_at => override.unlock_at,
          :override => override
        }
      end

      as_instructor << {
        :base => true,
        :unlock_at => self.unlock_at
      }
    end

    return as_student, as_instructor
  end

  # like unlock_ats_for, but for lock_at values instead.
  def lock_ats_for(user)
    as_student, as_instructor = nil, nil

    if context.user_has_been_student?(user)
      overridden = self.overridden_for(user)
      as_student = { :lock_at => overridden.lock_at }
    end

    if context.user_has_been_instructor?(user)
      overrides = self.overrides_visible_to(user).overriding_lock_at

      as_instructor = overrides.map do |override|
        {
          :title => override.title,
          :lock_at => override.lock_at,
          :override => override
        }
      end

      as_instructor << {
        :base => true,
        :lock_at => self.lock_at
      }
    end

    return as_student, as_instructor
  end
end
