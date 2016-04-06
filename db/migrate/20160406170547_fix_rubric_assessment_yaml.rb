class FixRubricAssessmentYaml < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::FixRubricAssessmentYAML.send_later_if_production(:run)
  end

  def down
  end
end
