class AddCalculationMethodToLearningOutcomes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :learning_outcomes, :calculation_method, :string
    add_column :learning_outcomes, :calculation_int, :integer, :limit => 2
  end

end
