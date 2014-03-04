module DatesOverridable
  attr_accessor :applied_overrides, :overridden_for_user, :overridden,
    :has_no_overrides
  attr_writer :without_overrides

  def self.included(base)
    base.has_many :assignment_overrides, :dependent => :destroy
    base.has_many :active_assignment_overrides, :class_name => 'AssignmentOverride', :conditions => {:workflow_state => 'active'}
    base.has_many :assignment_override_students, :dependent => :destroy
    
    base.validates_associated :assignment_overrides

    base.extend(ClassMethods)
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

  def has_active_overrides?
    assignment_overrides.active.count > 0
  end

  def without_overrides
    @without_overrides || self
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
  #
  # TODO: only used externally by app/controllers/calendar_events_api_controller.rb,
  # app/serializers/quiz_serializer.rb, and internally by
  # multiple_due_dates_apply_to?.  This would be a good candidate to refactor away.
  def due_dates_for(user)
    as_student, as_admin = nil, nil
    return nil, nil if context.nil?

    if user.nil?
      return self.without_overrides.due_date_hash, nil
    end

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
    all_dates << without_overrides.due_date_hash.merge(:base => true)
  end

  def all_dates_visible_to(user)
    if context.user_has_been_observer?(user)
      observed_student_due_dates(user).uniq
    else
      all_dates = overrides_visible_to(user).active
      all_dates = all_dates.map(&:as_hash)
      all_dates << without_overrides.due_date_hash.merge(:base => true)
    end
  end

  def due_dates_visible_to(user)
    # Overrides
    overrides = overrides_visible_to(user).overriding_due_at
    list = overrides.map(&:as_hash)

    # Base
    list << without_overrides.due_date_hash.merge(:base => true)
  end

  def dates_hash_visible_to(user)
    all_dates = all_dates_visible_to(user)

    # remove base if all sections are set
    overrides = all_dates.select { |d| d[:set_type] == 'CourseSection' }
    if overrides.count > 0 && overrides.count == context.active_course_sections.count
      all_dates.delete_if {|d| d[:base] }
    end

    formatted_dates_hash(all_dates)
  end

  def formatted_dates_hash(dates)
    dates = dates.sort_by do |date|
      due_at = date[:due_at]
      [ due_at.present? ? SortFirst : SortLast, due_at.presence || SortFirst ]
    end

    dates.map { |h| h.slice(:id, :due_at, :unlock_at, :lock_at, :title, :base) }
  end

  def observed_student_due_dates(user)
    ObserverEnrollment.observed_students(context, user).map do |student, enrollments|
      self.overridden_for(student).due_date_hash
    end
  end

  def due_date_hash
    hash = { :due_at => due_at, :unlock_at => unlock_at, :lock_at => lock_at }
    if self.is_a?(Assignment)
      hash.merge!({ :all_day => all_day, :all_day_date => all_day_date })
    elsif self.assignment
      hash.merge!({ :all_day => assignment.all_day, :all_day_date => assignment.all_day_date})
    end

    if @applied_overrides && override = @applied_overrides.find { |o| o.due_at == due_at }
      hash[:override] = override
      hash[:title] = override.title
    end

    hash
  end

  def multiple_due_dates_apply_to?(user)
    if !context.multiple_sections?
      return false
    else
      as_instructor = self.due_dates_for(user).second
      as_instructor && as_instructor.map{ |hash|
        self.class.due_date_compare_value(hash[:due_at]) }.uniq.size > 1
    end
  end

  def multiple_due_dates?
    if overridden
      !!multiple_due_dates_apply_to?(overridden_for_user)
    else
      raise "#{self.class.name} has not been overridden"
    end
  end

  def overridden_for?(user)
    overridden && (overridden_for_user == user)
  end

  module ClassMethods
    def due_date_compare_value(date)
      # due dates are considered equal if they're the same up to the minute
      date.to_i / 60
    end

    def due_dates_equal?(date1, date2)
      due_date_compare_value(date1) == due_date_compare_value(date2)
    end
  end
end
