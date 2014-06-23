class OverrideListPresenter

  attr_reader :assignment, :user

  include TextHelper

  def initialize(assignment=nil, user=nil)
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

    assignment.dates_hash_visible_to(user).each do |due_date|
      due_date[:raw] = due_date.dup
      due_date[:lock_at] = lock_at due_date
      due_date[:unlock_at] = unlock_at due_date
      due_date[:due_at] = due_at due_date
      due_date[:due_for] = due_for due_date
    end
  end
end
