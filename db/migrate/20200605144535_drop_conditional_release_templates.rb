# frozen_string_literal: true

class DropConditionalReleaseTemplates < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    if table_exists?(:conditional_release_scoring_range_templates)
      drop_table :conditional_release_scoring_range_templates
    end
    if table_exists?(:conditional_release_rule_templates)
      drop_table :conditional_release_rule_templates
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
