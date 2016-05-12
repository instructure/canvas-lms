class GradingPeriodGroup < ActiveRecord::Base
  include Canvas::SoftDeletable

  attr_accessible :title
  belongs_to :account
  belongs_to :course
  has_many :grading_periods, dependent: :destroy
  has_many :enrollment_terms, inverse_of: :grading_period_group

  validate :associated_with_course_or_account_or_enrollment_term?

  set_policy do
    given do |user|
      multiple_grading_periods_enabled? &&
        (course || account).grants_right?(user, :read)
    end
    can :read

    given do |user|
      account &&
        multiple_grading_periods_enabled? &&
        account.associated_user?(user)
    end
    can :read

    given do |user|
      multiple_grading_periods_enabled? &&
        (course || account).grants_right?(user, :manage)
    end
    can :update and can :delete

    given do |user|
      account &&
      multiple_grading_periods_enabled? &&
      account.grants_right?(user, :manage)
    end
    can :create
  end

  def multiple_grading_periods_enabled?
    (course || account).feature_enabled?(:multiple_grading_periods) || account_grading_period_allowed?
  end

  private

  def associated_with_course_or_account_or_enrollment_term?
    has_enrollment_terms = enrollment_terms.loaded? ? enrollment_terms.any?(&:active?) : enrollment_terms.active.exists?
    if has_enrollment_terms
      validate_with_enrollment_terms
    else
      validate_without_enrollment_terms if active?
    end
  end

  def validate_without_enrollment_terms
    if course_id.blank? && account_id.blank?
      errors.add(:enrollment_terms, t("cannot be empty when course_id is nil and account_id is nil"))
    elsif course_id.present? && account_id.present?
      errors.add(:course_id, t("cannot be present when account_id is present"))
      errors.add(:account_id, t("cannot be present when course_id is present"))
    end
  end

  def validate_with_enrollment_terms
    if enrollment_terms.loaded?
      account_ids = enrollment_terms.map(&:root_account_id)
    else
      account_ids = enrollment_terms.uniq.pluck(:root_account_id)
    end
    account_ids << self.account_id if self.account_id.present?
    if account_ids.uniq.count > 1
      errors.add(:enrollment_terms, t("cannot be associated with different accounts"))
    end
  end

  def account_grading_period_allowed?
    !!(account && account.feature_allowed?(:multiple_grading_periods))
  end
end
