class OverrideListPresenter

  attr_reader :assignment, :user

  include TextHelper

  def initialize(assignment, user)
    @user = user
    if assignment.present?
      @assignment = AssignmentOverrideApplicator.assignment_overridden_for(assignment, user)
    end
  end

  def lock_at(due_date)
    formatted_date_string(:lock_at, due_date)
  end

  def unlock_at(due_date)
    formatted_date_string(:unlock_at, due_date)
  end

  def due_at(due_date)
    formatted_date_string(:due_at, due_date)
  end

  def due_for(due_date)
    return due_date[:title] if due_date[:title]
    multiple_due_dates? ? 
      I18n.t('overrides.everyone_else','Everyone else') : 
      I18n.t('overrides.everyone','Everyone')
  end

  def formatted_date_string(date_field, date_hash = {})
    date = date_hash[date_field]
    if date.present? && CanvasTime.is_fancy_midnight?(date_hash[date_field]) &&
      date_field == :due_at
      date_string(date, :no_words)
    else
      date.present? ? datetime_string(date) : '-'
    end
  end

  # Public: Determine if multiple due dates are visible to user.
  #
  # Returns a boolean
  def multiple_due_dates?
    !!assignment.try(:has_active_overrides?)
  end

  # Public: Return all due dates visible to user, filtering out assignment info
  #   if it isn't needed (e.g. if all sections have overrides).
  #
  # Returns an array of due date hashes.
  def visible_due_dates
    return [] unless assignment

    due_dates  = assignment.all_dates_visible_to(user)
    section_overrides = due_dates.select { |d| d[:set_type] == 'CourseSection' }

    if section_overrides.count > 0 && section_overrides.count == assignment.context.active_course_sections.count
      due_dates.delete_if { |d| d[:base] }
    end

    due_dates = due_dates.sort_by do |date|
      due_at = date[:due_at]
      [ due_at.present? ?  0: 1, due_at.presence || 0 ]
    end

    due_dates.each do |due_date|
      due_date[:lock_at] = lock_at due_date
      due_date[:unlock_at] = unlock_at due_date
      due_date[:due_at] = due_at due_date
      due_date[:due_for] = due_for due_date
    end
  end
end
