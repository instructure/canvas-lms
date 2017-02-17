class AddPseudonymToStudentViewStudents < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::AddPseudonymToStudentViewStudents.send_later_if_production(:run)
  end

  def self.down
  end
end
