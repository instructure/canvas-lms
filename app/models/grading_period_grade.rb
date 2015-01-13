class GradingPeriodGrade < ActiveRecord::Base
  #TODO: when we create a controller for this, remove attr_accessible and use strong params instead
  attr_accessible :enrollment_id, :grading_period_id, :current_grade, :final_grade
  belongs_to :enrollment
  belongs_to :grading_period

  validates :enrollment_id, :grading_period_id, presence: true

  set_policy do
    [:read, :update, :create, :delete].each do |permission|
      given { |user| grading_period.grants_right?(user, permission) }
      can permission
    end
  end
end