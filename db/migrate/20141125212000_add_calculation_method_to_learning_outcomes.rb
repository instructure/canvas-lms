class AddCalculationMethodToLearningOutcomes < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :learning_outcomes, :calculation_method, :string
    add_column :learning_outcomes, :calculation_int, :integer, :limit => 2
  end

end
