class DropIgnoreTermDateRestrictions < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :enrollment_terms, :ignore_term_date_restrictions
  end

  def down
    add_column :enrollment_terms, :ignore_term_date_restrictions, :boolean
  end
end