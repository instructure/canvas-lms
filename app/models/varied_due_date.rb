require 'date'

class VariedDueDate

  attr_accessor :assignment, :user, :student_due_date, :admin_due_dates

  def initialize(assignment=nil, user=nil)
    self.assignment = assignment
    self.user = user

    if assignment && user
      self.student_due_date, self.admin_due_dates = assignment.due_dates_for(user)
    end
  end

  def latest_due_at
    unique_due_at.compact.sort.last
  end

  def self.due_at_for?(assignment,user)
    self.new(assignment,user).due_at
  end

  def multiple?
    unique_due_at.length > 1
  end

  def earliest_due_at
    unique_due_at.compact.sort.first
  end

  def due_at
    latest_due_at
  end

  def unique_due_at
    all_due_at.uniq
  end

  def all_due_at
    all_due_dates.map { |due| due[:due_at] }
  end

  def all_due_dates
    due_dates = []
    due_dates << student_due_date if student_due_date
    due_dates += admin_due_dates if admin_due_dates
    due_dates
  end

end
