class GradingPeriod < ActiveRecord::Base
  attr_accessible :weight, :start_date, :end_date, :title
  include Workflow

  belongs_to :grading_period_group

  validates_presence_of :weight, :start_date, :end_date
  validate :validate_dates

  set_policy do
    [:read, :update, :create, :delete].each do |permission|
      given { |user, http_session| grading_period_group.grants_right?(user, http_session, permission) }
      can permission
    end
  end

  workflow do
    state :active
    state :deleted
  end

  scope :active, -> { where workflow_state: "active" }

  alias_method :destroy!, :destroy
  def destroy
    update_attribute :workflow_state, "deleted"
  end

  def validate_dates
    if self.start_date && self.end_date
      errors.add(:end_date, t('errors.invalid_grading_period_end_date', "Grading period end date precedes start date")) if self.end_date < self.start_date
    end
  end
end
