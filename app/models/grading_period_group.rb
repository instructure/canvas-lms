class GradingPeriodGroup < ActiveRecord::Base
  belongs_to :course
  belongs_to :account
  has_many :grading_periods, dependent: :destroy

  # Naive permissions, need to be fleshed out
  set_policy do
    given { |user, http_session| (course || account).grants_right?(user, http_session, :read) }
    can :read

    given do |user, http_session|
      return false unless (course || account).root_account.feature_enabled?(:multiple_grading_periods)
      if course
        course.grants_right?(user, http_session, :update)
      elsif account
        account.grants_right?(user, http_session, :manage_courses)
      end
    end
    can :read and can :update and can :create and can :delete
  end
end
