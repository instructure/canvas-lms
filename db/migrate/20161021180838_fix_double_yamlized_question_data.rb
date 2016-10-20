class FixDoubleYamlizedQuestionData < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::FixDoubleYamlizedQuestionData.send_later_if_production(:run)
  end

  def down
  end
end
