class GradingPeriodGroup < ActiveRecord::Base
  belongs_to :course
  belongs_to :account
  has_many :grading_periods, dependent: :destroy

  set_policy do
    given { |user| multiple_grading_periods_enabled? && (course || account).grants_right?(user, :read) }
    can :read

    given { |user| account && multiple_grading_periods_enabled? && account.associated_user?(user) }
    can :read

    given { |user| multiple_grading_periods_enabled? && (course || account).grants_right?(user, :manage) }
    can :manage
  end

  def multiple_grading_periods_enabled?
    (course || account).root_account.feature_enabled?(:multiple_grading_periods)
  end
end
