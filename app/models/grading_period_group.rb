class GradingPeriodGroup < ActiveRecord::Base
  include Workflow

  attr_accessible

  belongs_to :course
  belongs_to :account
  has_many :grading_periods, dependent: :destroy

  validate :belongs_to_course_or_account_exclusive

  set_policy do
    given { |user| multiple_grading_periods_enabled? && (course || account).grants_right?(user, :read) }
    can :read

    given { |user| account && multiple_grading_periods_enabled? && account.associated_user?(user) }
    can :read

    given { |user| multiple_grading_periods_enabled? && (course || account).grants_right?(user, :manage) }
    can :manage
  end

  workflow do
    state :active
    state :deleted
  end

  scope :active, -> { where workflow_state: "active" }

  def multiple_grading_periods_enabled?
    (course || account).root_account.feature_enabled?(:multiple_grading_periods)
  end

 alias_method :destroy!, :destroy
 def destroy
   self.workflow_state = 'deleted'
   save!
   run_callbacks :destroy
 end

  private
  def belongs_to_course_or_account_exclusive
    if course.blank? && account.blank?
      errors.add(:course_id, t("cannot be nil when account_id is nil"))
      errors.add(:account_id, t("cannot be nil when course_id is nil"))
    end

    if course.present? && account.present?
      errors.add(:course_id, t("cannot be present when account_id is present"))
      errors.add(:account_id, t("cannot be present when course_id is present"))
    end
  end
end
