class GradingPeriod < ActiveRecord::Base
  attr_accessible :course, :account, :weight, :start_date, :end_date

  belongs_to :course
  belongs_to :account

  validates_presence_of :weight, :start_date, :end_date
  validate :validate_dates

  # Naive permissions, need to be fleshed out
  set_policy do
    given { |user, http_session| (course || account).grants_right?(user, http_session, :read)}
    can :read

    given do |user, http_session|
      if course
        course.grants_right?(user, http_session, :update)
      elsif account
        account.grants_right?(user, http_session, :manage_courses)
      end
    end
    can :read and can :update and can :create and can :delete

  end


  def validate_dates
    if self.start_date && self.end_date
      errors.add(:end_date, t('errors.invalid_grading_period_end_date', "Grading period end date precedes start date")) if self.end_date < self.start_date
    end
  end
end
