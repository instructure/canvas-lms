class AddPseudonymToStudentViewStudents < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::AddPseudonymToStudentViewStudents.send_later_if_production(:run)
  end

  def self.down
  end
end
