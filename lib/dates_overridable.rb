module DatesOverridable
  attr_accessor :applied_overrides, :overridden_for_user, :overridden,
    :has_no_overrides, :preloaded_override_students
  attr_writer :without_overrides
  include DifferentiableAssignment

  def self.included(base)
    base.has_many :assignment_overrides, :dependent => :destroy
    base.has_many :active_assignment_overrides, -> { where(workflow_state: 'active') }, class_name: 'AssignmentOverride'
    base.has_many :assignment_override_students, :dependent => :destroy

    base.validates_associated :active_assignment_overrides

    base.extend(ClassMethods)
  end

  def reload_overrides_cache?
    self.updated_at && self.updated_at > 2.seconds.ago
  end

  def without_overrides
    @without_overrides || self
  end

  def overridden_for(user)
    AssignmentOverrideApplicator.assignment_overridden_for(self, user)
  end

  # All overrides, not just dates
  def overrides_for(user)
    AssignmentOverrideApplicator.overrides_for_assignment_and_user(self, user)
  end

  def overridden_for?(user)
    overridden && (overridden_for_user == user)
  end

  def has_overrides?
    assignment_overrides.loaded? ? assignment_overrides.any? : assignment_overrides.exists?
  end

  def has_active_overrides?
    assignment_overrides.active.exists?
  end

  def multiple_due_dates?
    if overridden
      !!multiple_due_dates_apply_to?(overridden_for_user)
    else
      raise "#{self.class.name} has not been overridden"
    end
  end

  def multiple_due_dates_apply_to?(user)
    return false if !context.multiple_sections?
    return false if context.user_has_been_student?(user)

    if context.user_has_been_observer?(user)
      observed_student_due_dates(user).length > 1
    elsif context.user_has_been_admin?(user)
      dates = all_dates_visible_to(user)
      dates && dates.map{ |hash| self.class.due_date_compare_value(hash[:due_at]) }.uniq.size > 1
    elsif context.user_has_no_enrollments?(user)
      all_due_dates.length > 1
    end
  end

  def all_due_dates
    due_at_overrides = assignment_overrides.loaded? ? assignment_overrides.select{|ao| ao.active? && ao.due_at_overridden} : assignment_overrides.active.overriding_due_at
    dates = due_at_overrides.map(&:as_hash)
    dates << base_due_date_hash unless differentiated_assignments_applies?
    dates
  end

  def all_dates_visible_to(user)
    if user.nil?
      all_due_dates
    elsif ObserverEnrollment.observed_students(context, user).any?
      observed_student_due_dates(user)
    elsif context.user_has_been_student?(user) || context.user_has_been_admin?(user) || context.user_has_been_observer?(user)
      overrides = overrides_for(user)
      overrides = overrides.map(&:as_hash)
      unless differentiated_assignments_applies?
        overrides << base_due_date_hash if overrides.empty? || context.user_has_been_admin?(user)
      end
      overrides
    elsif context.user_has_no_enrollments?(user)
      all_due_dates
    end
  end

  def observed_student_due_dates(user)
    dates = ObserverEnrollment.observed_students(context, user).map do |student, enrollments|
      self.all_dates_visible_to(student)
    end
    dates.flatten.uniq
  end

  def dates_hash_visible_to(user)
    all_dates = all_dates_visible_to(user)

    if all_dates
      # remove base if all sections are set
      overrides = all_dates.select{ |d| d[:set_type] == 'CourseSection' }
      if overrides.count > 0 && overrides.count == context.active_section_count
        all_dates.delete_if {|d| d[:base] }
      end

      formatted_dates_hash(all_dates)
    else
      [due_date_hash]
    end
  end

  def teacher_due_date_for_display(user)
    ao = overridden_for user
    due_at || ao.due_at || all_due_dates.first[:due_at]
  end

  def formatted_dates_hash(dates)
    return [] unless dates.present?

    dates = dates.sort_by do |date|
      due_at = date[:due_at]
      [ due_at.present? ? CanvasSort::First : CanvasSort::Last, due_at.presence || CanvasSort::First ]
    end

    dates.map { |h| h.slice(:id, :due_at, :unlock_at, :lock_at, :title, :base) }
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

  def base_due_date_hash
    without_overrides.due_date_hash.merge(:base => true)
  end

  def context_module_tag_info(user, context)
    self.association(:context).target ||= context
    tag_info = Rails.cache.fetch([self, user, "context_module_tag_info"].cache_key) do
      hash = {:points_possible => self.points_possible}
      if self.multiple_due_dates_apply_to?(user)
        hash[:vdd_tooltip] = OverrideTooltipPresenter.new(self, user).as_json
      else
        if due_date = self.overridden_for(user).due_at
          hash[:due_date] = due_date
        end
      end
      hash
    end

    if tag_info[:due_date]
      if tag_info[:due_date] < Time.now
        if self.is_a?(Quizzes::Quiz) || (self.is_a?(Assignment) && expects_submission?)
          has_submission = self.is_a?(Assignment) && Rails.cache.fetch([self, user, "user_has_submission"]) do
            submission_for_student(user).has_submission?
          end
          tag_info[:past_due] = true unless has_submission
        end
      end

      tag_info[:due_date] = tag_info[:due_date].utc.iso8601
    end
    tag_info
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
