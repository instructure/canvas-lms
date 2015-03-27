class GradingPeriod < ActiveRecord::Base
  include Workflow

  attr_accessible :weight, :start_date, :end_date, :title

  belongs_to :grading_period_group, :inverse_of => :grading_periods
  has_many :grading_period_grades

  validates_presence_of :start_date, :end_date
  validate :validate_dates

  set_policy do
    given { |user| self.grading_period_group.grants_right?(user, :read) }
    can :read

    given { |user| self.grading_period_group.grants_right?(user, :manage) }
    can :manage
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

  # Takes a context and returns an Array (not an ActiveRecord::Relation)
  def self.for(context)
    "GradingPeriod::#{context.class}GradingPeriodFinder".constantize.new(context).grading_periods
  end

  # the keyword arguemnts version of this method is as follow:
  # def self.context_find(context: context, id: id)
  def self.context_find(options = {}) # in preperation for keyword arguments
    fail ArgumentCountError unless options.count == 2
    fail ArgumentError unless context = options.fetch(:context)
    fail ArgumentError unless id = options.fetch(:id)

    self.for(context).detect { |grading_period| grading_period.id == id }
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
    grading_period_group.grading_periods.sort_by(&:end_date).last == self
  end

  def validate_dates
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, t('errors.invalid_grading_period_end_date',
                              'Grading period end date precedes start date'))
    end
  end
end
