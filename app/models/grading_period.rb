class GradingPeriod < ActiveRecord::Base
  include Workflow

  attr_accessible :weight, :start_date, :end_date, :title

  belongs_to :grading_period_group, :inverse_of => :grading_periods
  has_many :grading_period_grades

  validates_presence_of :start_date, :end_date
  validate :validate_dates

  set_policy do
    [:read, :manage].each do |action|
      given { |user| grading_period_group.grants_right?(user, action) }
      can action
    end
  end

  workflow do
    state :active
    state :deleted
  end

  scope :active, -> { where workflow_state: "active" }
  scope :current, -> { where("start_date <= ? AND end_date >= ?", Time.now, Time.now) }
  scope :grading_periods_by, ->(context_with_ids) {
    joins(:grading_period_group).where(grading_period_groups: context_with_ids)
  }

  def self.for(context)
    "GradingPeriod::#{context.class}GradingPeriodFinder".constantize.new(context).grading_periods
  end

  # save the previous definition of `destroy` and alias it to `destroy!`
  # Note: `destroy!` now does NOT throw errors while the newly defined
  # `destroy` DOES throw errors due to `save!`
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  def assignments(assignment_scope)
    # TODO: avoid wasteful queries
    assignments = assignment_scope.where( "due_at BETWEEN ? AND ?", start_date, end_date)

    if last?
      assignments + assignment_scope.where(due_at: nil)
    else
      assignments
    end
  end

  private

  def last?
    grading_period_group.grading_periods.last == self
  end

  def validate_dates
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, t('errors.invalid_grading_period_end_date',
                              'Grading period end date precedes start date'))
    end
  end
end
