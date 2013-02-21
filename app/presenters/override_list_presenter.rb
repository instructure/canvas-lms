class OverrideListPresenter
  attr_reader :assignment, :user

  include TextHelper

  def initialize(assignment, user)
    @user = user
    if assignment.present?
      @assignment = AssignmentOverrideApplicator.assignment_overridden_for(assignment, user)
    end
  end

  # Public: Return a date string for the discussion assignment's lock at date.
  #
  # due_date - A due date as a hash.
  #
  # Returns a date or date/time string.
  def lock_at(due_date = {})
    formatted_date_string(:lock_at, due_date)
  end

  def unlock_at(due_date = {})
    formatted_date_string(:unlock_at, due_date)
  end

  def due_at(due_date = {})
    formatted_date_string(:due_at, due_date)
  end

  def due_for(due_date = {})
    return due_date[:title] if due_date[:title]
    multiple_due_dates? ? 
      I18n.t('overrides.everyone_else','Everyone else') : 
      I18n.t('overrides.everyone','Everyone')
  end

  def formatted_date_string(date_field, date_hash = {})
    date   = date_hash[:override].try(date_field)
    date ||= date_hash[date_field]
    date ||= assignment.try(date_field)
 
    formatted_date = date.present? ? datetime_string(date) : '-'
    formatted_date.match(/11:59/) ? date_string(date) : formatted_date
  end

  # Public: Determine if multiple due dates are visible to user.
  #
  # Returns a boolean
  def multiple_due_dates?
    assignment.multiple_due_dates_apply_to?(user)
  end
  
  # Public: Return all due dates visible to user, filtering out assignment info
  #   if it isn't needed (e.g. if all sections have overrides).
  #
  # Returns an array of due date hashes.
  def visible_due_dates
    return [] unless assignment

    due_dates  = assignment.due_dates_visible_to(user)
    section_overrides = due_dates.select { |d| d[:override].try(:set_type) == 'CourseSection' }

    if section_overrides.count > 0 && section_overrides.count == assignment.context.course_sections.count
      due_dates.delete_if { |d| d[:override].nil? }
    end

    due_dates.sort_by do |date| 
      due_at = date[:due_at]
      [ due_at ?  0: 1, due_at || 0 ]
    end
  end
end
